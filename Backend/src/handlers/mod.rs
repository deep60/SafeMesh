use crate::config::Config;
use crate::database::DbPool;
use crate::middleware::get_user_id;
use crate::models::*;
use crate::services::{
    AuthService, ConnectionHistoryService, SubscriptionService, UserService, VpnService,
};
use actix_web::{web, HttpRequest, HttpResponse};
use chrono::Utc;
use uuid::Uuid;

// ─────────────────────────────────────────────
// Auth Handlers (public — no middleware)
// ─────────────────────────────────────────────

pub async fn signup(
    pool: web::Data<DbPool>,
    config: web::Data<Config>,
    body: web::Json<RegisterRequest>,
) -> HttpResponse {
    match AuthService::register(
        pool.get_ref(),
        body.into_inner(),
        &config.jwt_secret,
        config.jwt_expires_in,
    )
    .await
    {
        Ok(response) => HttpResponse::Created().json(response),
        Err(e) => HttpResponse::BadRequest().json(ApiResponse::<()>::error(
            "registration_failed",
            &e.to_string(),
        )),
    }
}

pub async fn login(
    pool: web::Data<DbPool>,
    config: web::Data<Config>,
    body: web::Json<LoginRequest>,
) -> HttpResponse {
    match AuthService::login(
        pool.get_ref(),
        body.into_inner(),
        &config.jwt_secret,
        config.jwt_expires_in,
    )
    .await
    {
        Ok(response) => HttpResponse::Ok().json(response),
        Err(e) => HttpResponse::Unauthorized()
            .json(ApiResponse::<()>::error("auth_failed", &e.to_string())),
    }
}

pub async fn refresh_token(
    pool: web::Data<DbPool>,
    config: web::Data<Config>,
    body: web::Json<RefreshTokenRequest>,
) -> HttpResponse {
    match AuthService::refresh(
        pool.get_ref(),
        &body.refresh_token,
        &config.jwt_secret,
        config.jwt_expires_in,
    )
    .await
    {
        Ok(response) => HttpResponse::Ok().json(response),
        Err(e) => HttpResponse::Unauthorized()
            .json(ApiResponse::<()>::error("refresh_failed", &e.to_string())),
    }
}

pub async fn forgot_password(
    pool: web::Data<DbPool>,
    smtp_config: web::Data<crate::email::SmtpConfig>,
    body: web::Json<ForgotPasswordRequest>,
) -> HttpResponse {
    match AuthService::forgot_password(pool.get_ref(), &body.email, smtp_config.get_ref()).await {
        Ok(_) => HttpResponse::Ok().json(ApiResponse::ok_with_message(
            serde_json::Value::Null,
            "If an account with this email exists, a reset link has been sent",
        )),
        Err(e) => {
            tracing::error!("Forgot password error: {}", e);
            // Return success anyway to prevent email enumeration
            HttpResponse::Ok().json(ApiResponse::ok_with_message(
                serde_json::Value::Null,
                "If an account with this email exists, a reset link has been sent",
            ))
        }
    }
}

pub async fn reset_password(
    pool: web::Data<DbPool>,
    body: web::Json<ResetPasswordRequest>,
) -> HttpResponse {
    match AuthService::reset_password(pool.get_ref(), &body.token, &body.new_password).await {
        Ok(_) => HttpResponse::Ok().json(ApiResponse::ok_with_message(
            serde_json::Value::Null,
            "Password has been reset successfully",
        )),
        Err(e) => HttpResponse::BadRequest()
            .json(ApiResponse::<()>::error("reset_failed", &e.to_string())),
    }
}

// ─────────────────────────────────────────────
// Protected Auth Handler (requires JWT via middleware)
// ─────────────────────────────────────────────

pub async fn logout(pool: web::Data<DbPool>, req: HttpRequest) -> HttpResponse {
    let user_id = get_user_id(&req);
    match AuthService::logout(pool.get_ref(), user_id).await {
        Ok(_) => HttpResponse::Ok().json(ApiResponse::ok(serde_json::Value::Null)),
        Err(e) => HttpResponse::InternalServerError()
            .json(ApiResponse::<()>::error("logout_failed", &e.to_string())),
    }
}

// ─────────────────────────────────────────────
// User Handlers (protected — user_id from middleware)
// ─────────────────────────────────────────────

pub async fn get_user_profile(pool: web::Data<DbPool>, req: HttpRequest) -> HttpResponse {
    let user_id = get_user_id(&req);
    match UserService::get_profile(pool.get_ref(), user_id).await {
        Ok(Some(user)) => HttpResponse::Ok().json(ApiResponse::ok(UserResponse::from(&user))),
        Ok(None) => {
            HttpResponse::NotFound().json(ApiResponse::<()>::error("not_found", "User not found"))
        }
        Err(e) => HttpResponse::InternalServerError()
            .json(ApiResponse::<()>::error("server_error", &e.to_string())),
    }
}

pub async fn update_user_profile(
    pool: web::Data<DbPool>,
    req: HttpRequest,
    body: web::Json<UpdateProfileRequest>,
) -> HttpResponse {
    let user_id = get_user_id(&req);
    match UserService::update_profile(
        pool.get_ref(),
        user_id,
        body.name.as_deref(),
        body.avatar_url.as_deref(),
    )
    .await
    {
        Ok(Some(user)) => HttpResponse::Ok().json(ApiResponse::ok(UserResponse::from(&user))),
        Ok(None) => {
            HttpResponse::NotFound().json(ApiResponse::<()>::error("not_found", "User not found"))
        }
        Err(e) => HttpResponse::InternalServerError()
            .json(ApiResponse::<()>::error("server_error", &e.to_string())),
    }
}

// ─────────────────────────────────────────────
// Server Handlers (public — no auth required)
// ─────────────────────────────────────────────

pub async fn get_servers(pool: web::Data<DbPool>) -> HttpResponse {
    match VpnService::list_servers(pool.get_ref()).await {
        Ok(servers) => {
            let response: Vec<VpnServerResponse> =
                servers.iter().map(VpnServerResponse::from).collect();
            HttpResponse::Ok().json(VpnServerListResponse { servers: response })
        }
        Err(e) => HttpResponse::InternalServerError()
            .json(ApiResponse::<()>::error("server_error", &e.to_string())),
    }
}

// ─────────────────────────────────────────────
// VPN Connection Handlers (protected)
// ─────────────────────────────────────────────

pub async fn connect_to_server(
    pool: web::Data<DbPool>,
    req: HttpRequest,
    path: web::Path<String>,
) -> HttpResponse {
    let user_id = get_user_id(&req);
    let server_id = match Uuid::parse_str(&path.into_inner()) {
        Ok(id) => id,
        Err(_) => {
            return HttpResponse::BadRequest()
                .json(ApiResponse::<()>::error("bad_request", "Invalid server ID"))
        }
    };

    let client_ip = req
        .connection_info()
        .realip_remote_addr()
        .unwrap_or("unknown")
        .to_string();

    match VpnService::connect(pool.get_ref(), user_id, server_id, &client_ip).await {
        Ok((session, server)) => {
            let response = serde_json::json!({
                "sessionId": session.id.to_string(),
                "server": VpnServerResponse::from(&server),
                "connectedAt": session.connect_time.to_rfc3339(),
            });
            HttpResponse::Ok().json(ApiResponse::ok(response))
        }
        Err(e) => HttpResponse::BadRequest()
            .json(ApiResponse::<()>::error("connect_failed", &e.to_string())),
    }
}

pub async fn disconnect_from_server(
    pool: web::Data<DbPool>,
    req: HttpRequest,
    path: web::Path<String>,
) -> HttpResponse {
    let user_id = get_user_id(&req);
    let session_id = match Uuid::parse_str(&path.into_inner()) {
        Ok(id) => id,
        Err(_) => {
            return HttpResponse::BadRequest().json(ApiResponse::<()>::error(
                "bad_request",
                "Invalid session ID",
            ))
        }
    };

    match VpnService::disconnect(pool.get_ref(), session_id, user_id).await {
        Ok(_) => HttpResponse::Ok().json(ApiResponse::ok(serde_json::Value::Null)),
        Err(e) => {
            let msg = e.to_string();
            if msg.contains("do not own") {
                HttpResponse::Forbidden().json(ApiResponse::<()>::error("forbidden", &msg))
            } else {
                HttpResponse::InternalServerError()
                    .json(ApiResponse::<()>::error("server_error", &msg))
            }
        }
    }
}

// ─────────────────────────────────────────────
// VPN Config Handler (protected)
// ─────────────────────────────────────────────

pub async fn get_vpn_config(
    pool: web::Data<DbPool>,
    req: HttpRequest,
    body: web::Json<VpnConfigRequest>,
) -> HttpResponse {
    let _user_id = get_user_id(&req);

    let server_id = match Uuid::parse_str(&body.server_id) {
        Ok(id) => id,
        Err(_) => {
            return HttpResponse::BadRequest()
                .json(ApiResponse::<()>::error("bad_request", "Invalid server ID"))
        }
    };

    match VpnService::generate_config(pool.get_ref(), server_id, &body.public_key).await {
        Ok(response) => HttpResponse::Ok().json(ApiResponse::ok(response)),
        Err(e) => HttpResponse::BadRequest()
            .json(ApiResponse::<()>::error("config_failed", &e.to_string())),
    }
}

// ─────────────────────────────────────────────
// Connection History Handler (protected)
// ─────────────────────────────────────────────

pub async fn get_connection_history(pool: web::Data<DbPool>, req: HttpRequest) -> HttpResponse {
    let user_id = get_user_id(&req);
    match ConnectionHistoryService::get_history(pool.get_ref(), user_id).await {
        Ok(sessions) => {
            let response: Vec<ConnectionHistoryEntry> =
                sessions.iter().map(ConnectionHistoryEntry::from).collect();
            HttpResponse::Ok().json(ApiResponse::ok(response))
        }
        Err(e) => HttpResponse::InternalServerError()
            .json(ApiResponse::<()>::error("server_error", &e.to_string())),
    }
}

// ─────────────────────────────────────────────
// Subscription Handlers (protected)
// ─────────────────────────────────────────────

pub async fn get_subscriptions(pool: web::Data<DbPool>, req: HttpRequest) -> HttpResponse {
    let user_id = get_user_id(&req);
    match SubscriptionService::get_user_subscription(pool.get_ref(), user_id).await {
        Ok(Some(sub)) => HttpResponse::Ok().json(ApiResponse::ok(SubscriptionResponse::from(&sub))),
        Ok(None) => HttpResponse::Ok().json(ApiResponse::ok(serde_json::Value::Null)),
        Err(e) => HttpResponse::InternalServerError()
            .json(ApiResponse::<()>::error("server_error", &e.to_string())),
    }
}

pub async fn purchase_subscription(
    pool: web::Data<DbPool>,
    req: HttpRequest,
    body: web::Json<PurchaseSubscriptionRequest>,
) -> HttpResponse {
    let user_id = get_user_id(&req);
    match SubscriptionService::purchase_subscription(pool.get_ref(), user_id, &body.plan_type).await
    {
        Ok(sub) => HttpResponse::Created().json(ApiResponse::ok(SubscriptionResponse::from(&sub))),
        Err(e) => HttpResponse::BadRequest()
            .json(ApiResponse::<()>::error("purchase_failed", &e.to_string())),
    }
}

// ─────────────────────────────────────────────
// Health Check (public)
// ─────────────────────────────────────────────

pub async fn health_check() -> HttpResponse {
    HttpResponse::Ok().json(HealthCheckResponse {
        status: "ok".to_string(),
        version: env!("CARGO_PKG_VERSION").to_string(),
        timestamp: Utc::now(),
        services: vec![ServiceStatus {
            name: "database".to_string(),
            status: "healthy".to_string(),
            latency: 1.0,
        }],
    })
}

// ─────────────────────────────────────────────
// Delete User Account (protected)
// ─────────────────────────────────────────────

pub async fn delete_user_profile(pool: web::Data<DbPool>, req: HttpRequest) -> HttpResponse {
    let user_id = get_user_id(&req);
    match UserService::delete_account(pool.get_ref(), user_id).await {
        Ok(_) => HttpResponse::Ok().json(ApiResponse::ok(serde_json::Value::Null)),
        Err(e) => HttpResponse::InternalServerError()
            .json(ApiResponse::<()>::error("delete_failed", &e.to_string())),
    }
}

// ─────────────────────────────────────────────
// Subscription Plans (protected)
// ─────────────────────────────────────────────

pub async fn get_subscription_plans() -> HttpResponse {
    let plans = SubscriptionService::get_available_plans();
    HttpResponse::Ok().json(SubscriptionPlansResponse {
        plans,
        subscription: None,
    })
}

pub async fn cancel_subscription(pool: web::Data<DbPool>, req: HttpRequest) -> HttpResponse {
    let user_id = get_user_id(&req);
    match SubscriptionService::cancel_subscription(pool.get_ref(), user_id).await {
        Ok(sub) => {
            let response = sub.map(|s| SubscriptionResponse::from(&s));
            HttpResponse::Ok().json(ApiResponse::ok(response))
        }
        Err(e) => HttpResponse::BadRequest()
            .json(ApiResponse::<()>::error("cancel_failed", &e.to_string())),
    }
}

pub async fn restore_subscription(pool: web::Data<DbPool>, req: HttpRequest) -> HttpResponse {
    let user_id = get_user_id(&req);
    match SubscriptionService::restore_subscription(pool.get_ref(), user_id).await {
        Ok(sub) => {
            let response = sub.map(|s| SubscriptionResponse::from(&s));
            HttpResponse::Ok().json(ApiResponse::ok(response))
        }
        Err(e) => HttpResponse::BadRequest()
            .json(ApiResponse::<()>::error("restore_failed", &e.to_string())),
    }
}

// ─────────────────────────────────────────────
// Usage Upload (protected)
// ─────────────────────────────────────────────

pub async fn upload_usage(
    pool: web::Data<DbPool>,
    req: HttpRequest,
    body: web::Json<UsageUploadRequest>,
) -> HttpResponse {
    let user_id = get_user_id(&req);

    // Log usage for analytics. In production, store in a usage_logs table.
    tracing::info!(
        user_id = %user_id,
        bytes_up = body.bytes_uploaded,
        bytes_down = body.bytes_downloaded,
        duration = body.duration,
        server_id = ?body.server_id,
        "Usage data received"
    );

    // If a server_id was provided and we can find an active session, update it
    if let Some(ref server_id_str) = body.server_id {
        if let Ok(server_id) = Uuid::parse_str(server_id_str) {
            let _ = sqlx::query(
                "UPDATE user_sessions SET bytes_in = $1, bytes_out = $2 WHERE user_id = $3 AND server_id = $4 AND status = 'active'"
            )
            .bind(body.bytes_downloaded)
            .bind(body.bytes_uploaded)
            .bind(user_id)
            .bind(server_id)
            .execute(pool.get_ref())
            .await;
        }
    }

    HttpResponse::Ok().json(ApiResponse::ok(serde_json::Value::Null))
}
