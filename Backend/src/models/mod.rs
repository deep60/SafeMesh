use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use sqlx::FromRow;
use std::collections::HashMap;
use uuid::Uuid;

// ─────────────────────────────────────────────
// Database Models
// ─────────────────────────────────────────────

#[derive(Debug, Clone, FromRow, Serialize, Deserialize)]
pub struct User {
    pub id: Uuid,
    pub username: String,
    pub name: String,
    pub email: String,
    pub password_hash: String,
    pub avatar_url: Option<String>,
    pub is_email_verified: bool,
    pub two_factor_enabled: bool,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
    pub is_active: bool,
}

#[derive(Debug, Clone, FromRow, Serialize, Deserialize)]
pub struct VpnServer {
    pub id: Uuid,
    pub name: String,
    pub city: String,
    pub country: String,
    pub country_code: String,
    pub region: String,
    pub ip_address: String,
    pub port: i32,
    pub public_key: String,
    pub endpoint: String,
    pub dns_servers: String,
    pub protocol: String,
    pub protocols: String,
    pub latency: i32,
    pub load_percentage: i32,
    pub max_connections: i32,
    pub current_connections: i32,
    pub is_active: bool,
    pub is_premium: bool,
    pub status: String,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, FromRow, Serialize, Deserialize)]
pub struct UserSession {
    pub id: Uuid,
    pub user_id: Uuid,
    pub server_id: Uuid,
    pub connect_time: DateTime<Utc>,
    pub disconnect_time: Option<DateTime<Utc>>,
    pub ip_address: String,
    pub bytes_in: i64,
    pub bytes_out: i64,
    pub status: String,
}

#[derive(Debug, Clone, FromRow, Serialize, Deserialize)]
pub struct Subscription {
    pub id: Uuid,
    pub user_id: Uuid,
    pub plan_type: String,
    pub status: String,
    pub start_date: DateTime<Utc>,
    pub end_date: Option<DateTime<Utc>>,
    pub auto_renew: bool,
    pub max_bandwidth: i64,
    pub max_connections: i32,
    pub features: String,
    pub is_active: bool,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

// ─────────────────────────────────────────────
// API Request Models
// ─────────────────────────────────────────────

#[derive(Debug, Clone, Deserialize)]
pub struct RegisterRequest {
    pub name: String,
    pub email: String,
    pub password: String,
}

#[derive(Debug, Clone, Deserialize)]
pub struct LoginRequest {
    pub email: String,
    pub password: String,
}

#[derive(Debug, Clone, Deserialize)]
pub struct ForgotPasswordRequest {
    pub email: String,
}

#[derive(Debug, Clone, Deserialize)]
pub struct ResetPasswordRequest {
    pub token: String,
    #[serde(rename = "newPassword")]
    pub new_password: String,
}

#[derive(Debug, Clone, Deserialize)]
pub struct RefreshTokenRequest {
    #[serde(rename = "refreshToken")]
    pub refresh_token: String,
}

#[derive(Debug, Clone, Deserialize)]
pub struct UpdateProfileRequest {
    pub name: Option<String>,
    #[serde(rename = "avatarURL")]
    pub avatar_url: Option<String>,
}

#[derive(Debug, Clone, Deserialize)]
pub struct VpnConfigRequest {
    #[serde(rename = "serverId")]
    pub server_id: String,
    #[serde(rename = "publicKey")]
    pub public_key: String,
}

// ─────────────────────────────────────────────
// API Response Models
// ─────────────────────────────────────────────

/// Standard API response wrapper matching frontend `APIResponse<T>`
#[derive(Debug, Clone, Serialize)]
pub struct ApiResponse<T: Serialize> {
    pub success: bool,
    pub data: Option<T>,
    pub error: Option<ApiErrorDetail>,
    pub message: Option<String>,
}

impl<T: Serialize> ApiResponse<T> {
    pub fn ok(data: T) -> Self {
        Self {
            success: true,
            data: Some(data),
            error: None,
            message: None,
        }
    }

    pub fn ok_with_message(data: T, message: &str) -> Self {
        Self {
            success: true,
            data: Some(data),
            error: None,
            message: Some(message.to_string()),
        }
    }

    pub fn error(code: &str, message: &str) -> Self {
        Self {
            success: false,
            data: None,
            error: Some(ApiErrorDetail {
                code: code.to_string(),
                message: message.to_string(),
                details: None,
            }),
            message: Some(message.to_string()),
        }
    }
}

#[derive(Debug, Clone, Serialize)]
pub struct ApiErrorDetail {
    pub code: String,
    pub message: String,
    pub details: Option<Vec<String>>,
}

/// Auth response matching frontend `AuthResponse`
#[derive(Debug, Clone, Serialize)]
pub struct AuthResponse {
    pub token: String,
    #[serde(rename = "refreshToken")]
    pub refresh_token: String,
    #[serde(rename = "expiresIn")]
    pub expires_in: f64,
    pub user: UserResponse,
}

/// User response matching frontend `User` model
#[derive(Debug, Clone, Serialize)]
pub struct UserResponse {
    pub id: String,
    pub name: String,
    pub email: String,
    #[serde(rename = "avatarURL")]
    pub avatar_url: Option<String>,
    #[serde(rename = "createdAt")]
    pub created_at: DateTime<Utc>,
    #[serde(rename = "updatedAt")]
    pub updated_at: DateTime<Utc>,
    #[serde(rename = "isEmailVerified")]
    pub is_email_verified: bool,
    #[serde(rename = "twoFactorEnabled")]
    pub two_factor_enabled: bool,
}

impl From<&User> for UserResponse {
    fn from(user: &User) -> Self {
        Self {
            id: user.id.to_string(),
            name: user.name.clone(),
            email: user.email.clone(),
            avatar_url: user.avatar_url.clone(),
            created_at: user.created_at,
            updated_at: user.updated_at,
            is_email_verified: user.is_email_verified,
            two_factor_enabled: user.two_factor_enabled,
        }
    }
}

#[derive(Debug, Clone, Serialize)]
pub struct RefreshTokenResponse {
    pub token: String,
    #[serde(rename = "expiresIn")]
    pub expires_in: f64,
}

/// Server list response
#[derive(Debug, Clone, Serialize)]
pub struct VpnServerListResponse {
    pub servers: Vec<VpnServerResponse>,
}

/// Server response matching frontend `VPNServer` model
#[derive(Debug, Clone, Serialize)]
pub struct VpnServerResponse {
    pub id: String,
    pub name: String,
    pub city: String,
    pub country: String,
    #[serde(rename = "countryCode")]
    pub country_code: String,
    pub region: String,
    #[serde(rename = "ipAddress")]
    pub ip_address: String,
    pub port: i32,
    #[serde(rename = "publicKey")]
    pub public_key: String,
    pub endpoint: String,
    #[serde(rename = "dnsServers")]
    pub dns_servers: Vec<String>,
    pub latency: i32,
    #[serde(rename = "loadPercentage")]
    pub load_percentage: i32,
    #[serde(rename = "isActive")]
    pub is_active: bool,
    #[serde(rename = "isPremium")]
    pub is_premium: bool,
    pub protocols: Vec<String>,
}

impl From<&VpnServer> for VpnServerResponse {
    fn from(s: &VpnServer) -> Self {
        Self {
            id: s.id.to_string(),
            name: s.name.clone(),
            city: s.city.clone(),
            country: s.country.clone(),
            country_code: s.country_code.clone(),
            region: s.region.clone(),
            ip_address: s.ip_address.clone(),
            port: s.port,
            public_key: s.public_key.clone(),
            endpoint: s.endpoint.clone(),
            dns_servers: s
                .dns_servers
                .split(',')
                .map(|s| s.trim().to_string())
                .collect(),
            latency: s.latency,
            load_percentage: s.load_percentage,
            is_active: s.is_active,
            is_premium: s.is_premium,
            protocols: s
                .protocols
                .split(',')
                .map(|s| s.trim().to_string())
                .collect(),
        }
    }
}

/// VPN configuration response with per-client interface addresses
#[derive(Debug, Clone, Serialize)]
pub struct VpnConfigResponse {
    pub configuration: VpnConfigurationData,
    #[serde(rename = "expiresAt")]
    pub expires_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize)]
pub struct VpnConfigurationData {
    pub server: VpnServerResponse,
    #[serde(rename = "vpnProtocol")]
    pub vpn_protocol: String,
    #[serde(rename = "interfaceAddressV4")]
    pub interface_address_v4: String,
    #[serde(rename = "interfaceAddressV6")]
    pub interface_address_v6: String,
    #[serde(rename = "privateKey")]
    pub private_key: String,
    #[serde(rename = "publicKey")]
    pub public_key: String,
    #[serde(rename = "presharedKey")]
    pub preshared_key: Option<String>,
    #[serde(rename = "allowedIPs")]
    pub allowed_ips: Vec<String>,
    #[serde(rename = "dnsServers")]
    pub dns_servers: Vec<String>,
    #[serde(rename = "keepAliveInterval")]
    pub keep_alive_interval: i32,
    pub mtu: i32,
    #[serde(rename = "additionalSettings")]
    pub additional_settings: HashMap<String, String>,
}

/// Subscription response matching frontend
#[derive(Debug, Clone, Serialize)]
pub struct SubscriptionResponse {
    pub id: String,
    #[serde(rename = "planType")]
    pub plan_type: String,
    pub status: String,
    #[serde(rename = "startDate")]
    pub start_date: DateTime<Utc>,
    #[serde(rename = "endDate")]
    pub end_date: Option<DateTime<Utc>>,
    #[serde(rename = "autoRenew")]
    pub auto_renew: bool,
    #[serde(rename = "maxBandwidth")]
    pub max_bandwidth: i64,
    #[serde(rename = "maxConnections")]
    pub max_connections: i32,
    pub features: Vec<String>,
}

impl From<&Subscription> for SubscriptionResponse {
    fn from(s: &Subscription) -> Self {
        Self {
            id: s.id.to_string(),
            plan_type: s.plan_type.clone(),
            status: s.status.clone(),
            start_date: s.start_date,
            end_date: s.end_date,
            auto_renew: s.auto_renew,
            max_bandwidth: s.max_bandwidth,
            max_connections: s.max_connections,
            features: s
                .features
                .split(',')
                .map(|s| s.trim().to_string())
                .filter(|s| !s.is_empty())
                .collect(),
        }
    }
}

/// Health check response
#[derive(Debug, Clone, Serialize)]
pub struct HealthCheckResponse {
    pub status: String,
    pub version: String,
    pub timestamp: DateTime<Utc>,
    pub services: Vec<ServiceStatus>,
}

#[derive(Debug, Clone, Serialize)]
pub struct ServiceStatus {
    pub name: String,
    pub status: String,
    pub latency: f64,
}
