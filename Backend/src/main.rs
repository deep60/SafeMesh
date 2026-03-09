use actix_web::{web, App, HttpServer, middleware::Logger};
use actix_cors::Cors;
use tracing_subscriber;

mod api;
mod auth;
mod config;
mod database;
mod handlers;
mod middleware;
mod models;
mod services;
mod utils;

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    // Initialize logging
    tracing_subscriber::fmt::init();

    // Load configuration
    let config = config::Config::from_env().expect("Failed to load configuration");

    // Initialize database
    let pool = database::init_db(&config.database_url)
        .await
        .expect("Failed to initialize database");

    // Run database migrations
    database::run_migrations(&pool)
        .await
        .expect("Failed to run database migrations");

    let config_clone = config.clone();

    println!("🚀 SafeMesh Backend starting at http://{}:{}", config.host, config.port);
    println!("📡 API available at http://{}:{}/api/v1/", config.host, config.port);

    HttpServer::new(move || {
        // CORS — allows the iOS app and local development
        let cors = Cors::default()
            .allow_any_origin()
            .allow_any_method()
            .allow_any_header()
            .max_age(3600);

        App::new()
            .app_data(web::Data::new(pool.clone()))
            .app_data(web::Data::new(config_clone.clone()))
            .wrap(cors)
            .wrap(Logger::default())
            .configure(|cfg| api::config(cfg, &config_clone.jwt_secret))
    })
    .bind((config.host.clone(), config.port))?
    .run()
    .await
}
