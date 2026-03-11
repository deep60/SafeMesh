use crate::handlers;
use crate::middleware::JwtAuth;
use actix_web::web;

pub fn config(cfg: &mut web::ServiceConfig, jwt_secret: &str) {
    cfg.service(
        web::scope("/v1")
            // ── Public routes (no JWT required) ──
            .route("/health", web::get().to(handlers::health_check))
            .route("/servers", web::get().to(handlers::get_servers))
            .route("/auth/signup", web::post().to(handlers::signup))
            .route("/auth/login", web::post().to(handlers::login))
            .route("/auth/refresh", web::post().to(handlers::refresh_token))
            .route(
                "/auth/forgot-password",
                web::post().to(handlers::forgot_password),
            )
            .route(
                "/auth/reset-password",
                web::post().to(handlers::reset_password),
            )
            // ── Protected routes (JWT middleware applied) ──
            .service(
                web::scope("")
                    .wrap(JwtAuth::new(jwt_secret.to_string()))
                    .route("/auth/logout", web::post().to(handlers::logout))
                    .route("/user/me", web::get().to(handlers::get_user_profile))
                    .route("/user/me", web::put().to(handlers::update_user_profile))
                    .route(
                        "/connect/{server_id}",
                        web::post().to(handlers::connect_to_server),
                    )
                    .route(
                        "/disconnect/{session_id}",
                        web::post().to(handlers::disconnect_from_server),
                    )
                    .route("/vpn/config", web::post().to(handlers::get_vpn_config))
                    .route(
                        "/connections/history",
                        web::get().to(handlers::get_connection_history),
                    )
                    .route("/subscriptions", web::get().to(handlers::get_subscriptions))
                    .route(
                        "/subscriptions/purchase",
                        web::post().to(handlers::purchase_subscription),
                    ),
            ),
    );
}
