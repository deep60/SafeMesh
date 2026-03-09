use serde::Serialize;
use actix_web::{HttpResponse, Result};

#[derive(Serialize)]
pub struct ErrorResponse {
    pub message: String,
}

pub fn bad_request(message: &str) -> Result<HttpResponse> {
    Ok(HttpResponse::BadRequest().json(ErrorResponse {
        message: message.to_string(),
    }))
}

pub fn internal_server_error(message: &str) -> Result<HttpResponse> {
    Ok(HttpResponse::InternalServerError().json(ErrorResponse {
        message: message.to_string(),
    }))
}

pub fn unauthorized(message: &str) -> Result<HttpResponse> {
    Ok(HttpResponse::Unauthorized().json(ErrorResponse {
        message: message.to_string(),
    }))
}

// Utility function to validate email format
pub fn is_valid_email(email: &str) -> bool {
    // Simple email validation - in production, use a proper email validation crate
    email.contains('@') && email.contains('.')
}

// Utility function to validate password strength
pub fn is_valid_password(password: &str) -> bool {
    // Simple password validation - at least 8 characters
    password.len() >= 8
}

// Utility function to generate a random string
pub fn generate_random_string(len: usize) -> String {
    use rand::{distributions::Alphanumeric, thread_rng, Rng};

    thread_rng()
        .sample_iter(&Alphanumeric)
        .take(len)
        .map(char::from)
        .collect()
}