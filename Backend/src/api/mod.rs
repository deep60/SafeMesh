use actix_web::web;

pub mod v1;

pub fn config(cfg: &mut web::ServiceConfig, jwt_secret: &str) {
    cfg.service(web::scope("/api").configure(|c| v1::config(c, jwt_secret)));
}
