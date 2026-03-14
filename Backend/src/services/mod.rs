use crate::auth;
use crate::database::DbPool;
use crate::models::*;
use chrono::{Duration, Utc};
use rand::{distributions::Alphanumeric, thread_rng, Rng};
use sha2::{Digest, Sha256};
use uuid::Uuid;

// ─────────────────────────────────────────────
// Auth Service — authentication business logic
// ─────────────────────────────────────────────

pub struct AuthService;

impl AuthService {
    pub async fn register(
        pool: &DbPool,
        request: RegisterRequest,
        jwt_secret: &str,
        jwt_expires_in: i64,
    ) -> Result<AuthResponse, Box<dyn std::error::Error>> {
        // Validate: check if email already exists
        if crate::database::get_user_by_email(pool, &request.email)
            .await?
            .is_some()
        {
            return Err("A user with this email already exists".into());
        }

        // Hash the password
        let password_hash = auth::hash_password(&request.password)?;

        // Persist the user
        let user =
            crate::database::create_user(pool, &request.name, &request.email, &password_hash)
                .await?;

        // Generate tokens
        let token = auth::generate_jwt(user.id, jwt_secret, jwt_expires_in)?;
        let (refresh_token_raw, _) = Self::create_refresh_token(pool, user.id).await?;

        Ok(AuthResponse {
            token,
            refresh_token: refresh_token_raw,
            expires_in: jwt_expires_in as f64,
            user: UserResponse::from(&user),
        })
    }

    pub async fn login(
        pool: &DbPool,
        request: LoginRequest,
        jwt_secret: &str,
        jwt_expires_in: i64,
    ) -> Result<AuthResponse, Box<dyn std::error::Error>> {
        let user = crate::database::get_user_by_email(pool, &request.email)
            .await?
            .ok_or("Invalid email or password")?;

        if !auth::verify_password(&request.password, &user.password_hash)? {
            return Err("Invalid email or password".into());
        }

        let token = auth::generate_jwt(user.id, jwt_secret, jwt_expires_in)?;
        let (refresh_token_raw, _) = Self::create_refresh_token(pool, user.id).await?;

        Ok(AuthResponse {
            token,
            refresh_token: refresh_token_raw,
            expires_in: jwt_expires_in as f64,
            user: UserResponse::from(&user),
        })
    }

    pub async fn refresh(
        pool: &DbPool,
        refresh_token_raw: &str,
        jwt_secret: &str,
        jwt_expires_in: i64,
    ) -> Result<RefreshTokenResponse, Box<dyn std::error::Error>> {
        let token_hash = Self::hash_token(refresh_token_raw);

        let (user_id, expires_at) = crate::database::find_refresh_token(pool, &token_hash)
            .await?
            .ok_or("Invalid refresh token")?;

        if expires_at < Utc::now() {
            crate::database::delete_refresh_token(pool, &token_hash).await?;
            return Err("Refresh token expired".into());
        }

        // Rotate: delete old, issue new JWT
        crate::database::delete_refresh_token(pool, &token_hash).await?;
        let new_token = auth::generate_jwt(user_id, jwt_secret, jwt_expires_in)?;

        Ok(RefreshTokenResponse {
            token: new_token,
            expires_in: jwt_expires_in as f64,
        })
    }

    pub async fn logout(pool: &DbPool, user_id: Uuid) -> Result<(), Box<dyn std::error::Error>> {
        crate::database::delete_user_refresh_tokens(pool, user_id).await?;
        Ok(())
    }

    pub async fn forgot_password(
        pool: &DbPool,
        email: &str,
        smtp_config: &crate::email::SmtpConfig,
    ) -> Result<(), Box<dyn std::error::Error>> {
        // Find user — always return success to prevent email enumeration
        let user = match crate::database::get_user_by_email(pool, email).await? {
            Some(u) => u,
            None => {
                tracing::warn!("Password reset requested for non-existent email: {}", email);
                return Ok(()); // Silent success to prevent enumeration
            }
        };

        // Generate a reset token
        let raw_token = Self::generate_random_token(32);
        let token_hash = Self::hash_token(&raw_token);
        let expires_at = Utc::now() + Duration::hours(1);

        crate::database::store_password_reset_token(pool, user.id, &token_hash, expires_at).await?;

        // Send the reset email (falls back to console in dev mode)
        crate::email::send_password_reset_email(email, &raw_token, smtp_config).await?;

        Ok(())
    }

    pub async fn reset_password(
        pool: &DbPool,
        token: &str,
        new_password: &str,
    ) -> Result<(), Box<dyn std::error::Error>> {
        let token_hash = Self::hash_token(token);

        // Validate the token
        let (user_id, expires_at, used) =
            crate::database::find_password_reset_token(pool, &token_hash)
                .await?
                .ok_or("Invalid or expired reset token")?;

        if used {
            return Err("This reset token has already been used".into());
        }
        if expires_at < Utc::now() {
            return Err("This reset token has expired".into());
        }

        // Hash new password, update user, mark token used
        let new_hash = auth::hash_password(new_password)?;
        crate::database::update_user_password(pool, user_id, &new_hash).await?;
        crate::database::mark_reset_token_used(pool, &token_hash).await?;

        // Revoke all existing refresh tokens for security
        crate::database::delete_user_refresh_tokens(pool, user_id).await?;

        Ok(())
    }

    // ── Private helpers ──

    async fn create_refresh_token(
        pool: &DbPool,
        user_id: Uuid,
    ) -> Result<(String, String), Box<dyn std::error::Error>> {
        let raw = Self::generate_random_token(64);
        let hash = Self::hash_token(&raw);
        let expires = Utc::now() + Duration::days(30);
        crate::database::store_refresh_token(pool, user_id, &hash, expires).await?;
        Ok((raw, hash))
    }

    fn hash_token(token: &str) -> String {
        let mut hasher = Sha256::new();
        hasher.update(token.as_bytes());
        format!("{:x}", hasher.finalize())
    }

    fn generate_random_token(len: usize) -> String {
        thread_rng()
            .sample_iter(&Alphanumeric)
            .take(len)
            .map(char::from)
            .collect()
    }
}

// ─────────────────────────────────────────────
// User Service — user profile business logic
// ─────────────────────────────────────────────

pub struct UserService;

impl UserService {
    pub async fn get_profile(pool: &DbPool, user_id: Uuid) -> Result<Option<User>, sqlx::Error> {
        crate::database::get_user_by_id(pool, user_id).await
    }

    pub async fn update_profile(
        pool: &DbPool,
        user_id: Uuid,
        name: Option<&str>,
        avatar_url: Option<&str>,
    ) -> Result<Option<User>, sqlx::Error> {
        crate::database::update_user_profile(pool, user_id, name, avatar_url).await
    }

    pub async fn delete_account(
        pool: &DbPool,
        user_id: Uuid,
    ) -> Result<(), Box<dyn std::error::Error>> {
        // Revoke refresh tokens
        crate::database::delete_user_refresh_tokens(pool, user_id).await?;
        // Deactivate user record (soft delete)
        sqlx::query("UPDATE users SET is_active = false, updated_at = NOW() WHERE id = $1")
            .bind(user_id)
            .execute(pool)
            .await?;
        Ok(())
    }
}

// ─────────────────────────────────────────────
// VPN Service — server listing, connection, config generation
// ─────────────────────────────────────────────

pub struct VpnService;

impl VpnService {
    pub async fn list_servers(pool: &DbPool) -> Result<Vec<VpnServer>, sqlx::Error> {
        crate::database::get_all_servers(pool).await
    }

    pub async fn get_server(
        pool: &DbPool,
        server_id: Uuid,
    ) -> Result<Option<VpnServer>, sqlx::Error> {
        crate::database::get_server_by_id(pool, server_id).await
    }

    pub async fn connect(
        pool: &DbPool,
        user_id: Uuid,
        server_id: Uuid,
        client_ip: &str,
    ) -> Result<(UserSession, VpnServer), Box<dyn std::error::Error>> {
        let server = crate::database::get_server_by_id(pool, server_id)
            .await?
            .ok_or("Server not found")?;

        if !server.is_active || server.status != "online" {
            return Err("Server is not available".into());
        }

        let session = crate::database::create_session(pool, user_id, server_id, client_ip).await?;
        Ok((session, server))
    }

    pub async fn disconnect(
        pool: &DbPool,
        session_id: Uuid,
        user_id: Uuid,
    ) -> Result<(), Box<dyn std::error::Error>> {
        let session = crate::database::get_session_by_id(pool, session_id)
            .await?
            .ok_or("Session not found")?;
        if session.user_id != user_id {
            return Err("You do not own this session".into());
        }
        crate::database::disconnect_session(pool, session_id).await?;
        Ok(())
    }

    /// Generate a real WireGuard VPN configuration for the client.
    /// In production, this would manage peer state on the actual WireGuard server.
    pub async fn generate_config(
        pool: &DbPool,
        server_id: Uuid,
        client_public_key: &str,
    ) -> Result<VpnConfigResponse, Box<dyn std::error::Error>> {
        let server = crate::database::get_server_by_id(pool, server_id)
            .await?
            .ok_or("Server not found")?;

        if !server.is_active || server.status != "online" {
            return Err("Server is not available for configuration".into());
        }

        // Generate a unique interface IP for this client from the server's pool.
        // In production, this would be tracked per-peer in the database.
        let client_index = (server.current_connections + 2) as u8; // +2 because .1 is the server
        let interface_ipv4 = format!("10.0.0.{}/32", client_index);
        let interface_ipv6 = format!("fd00::{:x}/128", client_index);

        // Generate server-side WireGuard keypair for this peer relationship.
        // In production, the server's private key is managed by the WireGuard server process.
        let server_response = VpnServerResponse::from(&server);
        let dns_servers = server
            .dns_servers
            .split(',')
            .map(|s| s.trim().to_string())
            .collect();

        let config = VpnConfigurationData {
            server: server_response,
            vpn_protocol: "WireGuard".to_string(),
            interface_address_v4: interface_ipv4,
            interface_address_v6: interface_ipv6,
            private_key: String::new(), // Client keeps their own private key
            public_key: client_public_key.to_string(),
            preshared_key: None,
            allowed_ips: vec!["0.0.0.0/0".to_string(), "::/0".to_string()],
            dns_servers,
            keep_alive_interval: 25,
            mtu: 1280,
            additional_settings: std::collections::HashMap::new(),
        };

        Ok(VpnConfigResponse {
            configuration: config,
            expires_at: Utc::now() + Duration::hours(24),
        })
    }
}

// ─────────────────────────────────────────────
// Subscription Service
// ─────────────────────────────────────────────

pub struct SubscriptionService;

impl SubscriptionService {
    pub async fn get_user_subscription(
        pool: &DbPool,
        user_id: Uuid,
    ) -> Result<Option<Subscription>, sqlx::Error> {
        crate::database::get_user_subscription(pool, user_id).await
    }

    pub fn get_available_plans() -> Vec<SubscriptionPlanInfo> {
        vec![
            SubscriptionPlanInfo {
                id: "plan_free".to_string(),
                name: "Free".to_string(),
                plan_type: "free".to_string(),
                price: 0.0,
                currency: "USD".to_string(),
                billing_period: "forever".to_string(),
                max_bandwidth: 1_073_741_824,          // 1 GB
                max_connections: 1,
                features: vec!["basic_vpn".to_string()],
                sort_order: 0,
                is_free: true,
            },
            SubscriptionPlanInfo {
                id: "plan_monthly".to_string(),
                name: "Pro Monthly".to_string(),
                plan_type: "pro".to_string(),
                price: 9.99,
                currency: "USD".to_string(),
                billing_period: "month".to_string(),
                max_bandwidth: 107_374_182_400,        // 100 GB
                max_connections: 5,
                features: vec![
                    "basic_vpn".to_string(),
                    "premium_servers".to_string(),
                    "kill_switch".to_string(),
                ],
                sort_order: 1,
                is_free: false,
            },
            SubscriptionPlanInfo {
                id: "plan_yearly".to_string(),
                name: "Premium Yearly".to_string(),
                plan_type: "premium".to_string(),
                price: 79.99,
                currency: "USD".to_string(),
                billing_period: "year".to_string(),
                max_bandwidth: i64::MAX,
                max_connections: 10,
                features: vec![
                    "basic_vpn".to_string(),
                    "premium_servers".to_string(),
                    "kill_switch".to_string(),
                    "split_tunnel".to_string(),
                    "dedicated_ip".to_string(),
                ],
                sort_order: 2,
                is_free: false,
            },
        ]
    }

    pub async fn purchase_subscription(
        pool: &DbPool,
        user_id: Uuid,
        plan_type: &str,
    ) -> Result<Subscription, Box<dyn std::error::Error>> {
        let (max_bw, max_conn, features) = match plan_type {
            "free" => (1_073_741_824i64, 1, "basic_vpn"),
            "pro" => (
                107_374_182_400i64,
                5,
                "basic_vpn,premium_servers,kill_switch",
            ),
            "premium" => (
                i64::MAX,
                10,
                "basic_vpn,premium_servers,kill_switch,split_tunnel,dedicated_ip",
            ),
            _ => return Err("Invalid plan type. Choose: free, pro, premium".into()),
        };
        let sub = crate::database::create_subscription(
            pool, user_id, plan_type, max_bw, max_conn, features,
        )
        .await?;
        Ok(sub)
    }

    pub async fn cancel_subscription(
        pool: &DbPool,
        user_id: Uuid,
    ) -> Result<Option<Subscription>, Box<dyn std::error::Error>> {
        // Set auto_renew to false and mark status as "canceled"
        sqlx::query(
            "UPDATE subscriptions SET auto_renew = false, status = 'canceled', updated_at = NOW() WHERE user_id = $1 AND is_active = true"
        )
        .bind(user_id)
        .execute(pool)
        .await?;

        Ok(crate::database::get_user_subscription(pool, user_id).await?)
    }

    pub async fn restore_subscription(
        pool: &DbPool,
        user_id: Uuid,
    ) -> Result<Option<Subscription>, Box<dyn std::error::Error>> {
        // Re-enable auto_renew and set status back to "active"
        sqlx::query(
            "UPDATE subscriptions SET auto_renew = true, status = 'active', updated_at = NOW() WHERE user_id = $1 AND is_active = true"
        )
        .bind(user_id)
        .execute(pool)
        .await?;

        Ok(crate::database::get_user_subscription(pool, user_id).await?)
    }
}

// ─────────────────────────────────────────────
// Connection History Service
// ─────────────────────────────────────────────

pub struct ConnectionHistoryService;

impl ConnectionHistoryService {
    pub async fn get_history(
        pool: &DbPool,
        user_id: Uuid,
    ) -> Result<Vec<UserSession>, sqlx::Error> {
        crate::database::get_user_sessions(pool, user_id).await
    }
}
