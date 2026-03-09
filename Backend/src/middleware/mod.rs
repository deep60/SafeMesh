use actix_web::{
    dev::{forward_ready, Service, ServiceRequest, ServiceResponse, Transform},
    Error, HttpMessage,
};
use futures_util::future::{ok, LocalBoxFuture, Ready};
use std::rc::Rc;
use uuid::Uuid;
use crate::auth::validate_jwt;

// ─────────────────────────────────────────────
// JWT Authentication Middleware
// ─────────────────────────────────────────────

/// Actix-web middleware that validates JWT tokens on protected routes.
/// Extracts the user_id from valid tokens and inserts it into request extensions.
pub struct JwtAuth {
    pub jwt_secret: String,
}

impl JwtAuth {
    pub fn new(jwt_secret: String) -> Self {
        Self { jwt_secret }
    }
}

impl<S, B> Transform<S, ServiceRequest> for JwtAuth
where
    S: Service<ServiceRequest, Response = ServiceResponse<B>, Error = Error> + 'static,
    S::Future: 'static,
    B: 'static,
{
    type Response = ServiceResponse<B>;
    type Error = Error;
    type InitError = ();
    type Transform = JwtAuthMiddleware<S>;
    type Future = Ready<Result<Self::Transform, Self::InitError>>;

    fn new_transform(&self, service: S) -> Self::Future {
        ok(JwtAuthMiddleware {
            service: Rc::new(service),
            jwt_secret: self.jwt_secret.clone(),
        })
    }
}

pub struct JwtAuthMiddleware<S> {
    service: Rc<S>,
    jwt_secret: String,
}

impl<S, B> Service<ServiceRequest> for JwtAuthMiddleware<S>
where
    S: Service<ServiceRequest, Response = ServiceResponse<B>, Error = Error> + 'static,
    S::Future: 'static,
    B: 'static,
{
    type Response = ServiceResponse<B>;
    type Error = Error;
    type Future = LocalBoxFuture<'static, Result<Self::Response, Self::Error>>;

    forward_ready!(service);

    fn call(&self, req: ServiceRequest) -> Self::Future {
        let service = Rc::clone(&self.service);
        let jwt_secret = self.jwt_secret.clone();

        Box::pin(async move {
            // Extract Authorization header
            let auth_header = req
                .headers()
                .get("Authorization")
                .and_then(|v| v.to_str().ok())
                .map(|s| s.to_string());

            let token = match auth_header {
                Some(ref header) if header.starts_with("Bearer ") => &header[7..],
                _ => {
                    return Err(actix_web::error::ErrorUnauthorized(
                        r#"{"success":false,"error":{"code":"unauthorized","message":"Missing or invalid Authorization header"}}"#,
                    ));
                }
            };

            // Validate JWT and extract user_id
            let user_id = match validate_jwt(token, &jwt_secret) {
                Ok(id) => id,
                Err(_) => {
                    return Err(actix_web::error::ErrorUnauthorized(
                        r#"{"success":false,"error":{"code":"unauthorized","message":"Invalid or expired token"}}"#,
                    ));
                }
            };

            // Insert user_id into request extensions so handlers can access it
            req.extensions_mut().insert(user_id);

            // Continue to handler
            service.call(req).await
        })
    }
}

// ─────────────────────────────────────────────
// Helper: extract user_id from request extensions
// ─────────────────────────────────────────────

/// Extract the authenticated user_id inserted by JwtAuth middleware.
/// Panics if called on an unprotected route (middleware not applied).
pub fn get_user_id(req: &actix_web::HttpRequest) -> Uuid {
    *req.extensions()
        .get::<Uuid>()
        .expect("JwtAuth middleware must be applied to this route")
}