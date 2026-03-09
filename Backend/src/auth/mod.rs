use bcrypt::{hash, verify, DEFAULT_COST};
use chrono::Utc;
use jsonwebtoken::{decode, encode, DecodingKey, EncodingKey, Header, Validation};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

// ─────────────────────────────────────────────
// JWT Claims
// ─────────────────────────────────────────────

#[derive(Debug, Serialize, Deserialize)]
pub struct Claims {
    pub sub: String, // user_id
    pub exp: i64,    // expiration (Unix timestamp)
}

// ─────────────────────────────────────────────
// Password Hashing (bcrypt)
// ─────────────────────────────────────────────

pub fn hash_password(password: &str) -> Result<String, Box<dyn std::error::Error>> {
    Ok(hash(password, DEFAULT_COST)?)
}

pub fn verify_password(password: &str, hash: &str) -> Result<bool, Box<dyn std::error::Error>> {
    Ok(verify(password, hash)?)
}

// ─────────────────────────────────────────────
// JWT Generation / Validation
// ─────────────────────────────────────────────

pub fn generate_jwt(
    user_id: Uuid,
    secret: &str,
    expires_in: i64,
) -> Result<String, Box<dyn std::error::Error>> {
    let claims = Claims {
        sub: user_id.to_string(),
        exp: Utc::now().timestamp() + expires_in,
    };
    Ok(encode(
        &Header::default(),
        &claims,
        &EncodingKey::from_secret(secret.as_bytes()),
    )?)
}

pub fn validate_jwt(token: &str, secret: &str) -> Result<Uuid, Box<dyn std::error::Error>> {
    let token_data = decode::<Claims>(
        token,
        &DecodingKey::from_secret(secret.as_bytes()),
        &Validation::default(),
    )?;
    Ok(Uuid::parse_str(&token_data.claims.sub)?)
}
