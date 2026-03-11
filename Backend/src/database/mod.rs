use crate::models::{Subscription, User, UserSession, VpnServer};
use chrono::{DateTime, Utc};
use sqlx::{
    sqlite::{SqliteConnectOptions, SqlitePoolOptions},
    Pool, Row, Sqlite,
};
use std::str::FromStr;
use uuid::Uuid;

pub type DbPool = Pool<Sqlite>;

pub async fn init_db(database_url: &str) -> Result<DbPool, sqlx::Error> {
    let options: SqliteConnectOptions = database_url
        .parse::<SqliteConnectOptions>()?
        .create_if_missing(true);

    SqlitePoolOptions::new()
        .max_connections(5)
        .connect_with(options)
        .await
}

pub async fn run_migrations(pool: &DbPool) -> Result<(), sqlx::Error> {
    // Users table (expanded to match frontend User model)
    sqlx::query(
        r#"
        CREATE TABLE IF NOT EXISTS users (
            id TEXT PRIMARY KEY,
            username TEXT UNIQUE NOT NULL,
            name TEXT NOT NULL DEFAULT '',
            email TEXT UNIQUE NOT NULL,
            password_hash TEXT NOT NULL,
            avatar_url TEXT,
            is_email_verified INTEGER NOT NULL DEFAULT 0,
            two_factor_enabled INTEGER NOT NULL DEFAULT 0,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            is_active INTEGER NOT NULL DEFAULT 1
        )
        "#,
    )
    .execute(pool)
    .await?;

    // VPN servers table (expanded to match frontend VPNServer model)
    sqlx::query(
        r#"
        CREATE TABLE IF NOT EXISTS vpn_servers (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            city TEXT NOT NULL,
            country TEXT NOT NULL,
            country_code TEXT NOT NULL DEFAULT 'US',
            region TEXT NOT NULL DEFAULT 'North America',
            ip_address TEXT NOT NULL,
            port INTEGER NOT NULL DEFAULT 51820,
            public_key TEXT NOT NULL DEFAULT '',
            endpoint TEXT NOT NULL DEFAULT '',
            dns_servers TEXT NOT NULL DEFAULT '1.1.1.1,1.0.0.1',
            protocol TEXT NOT NULL DEFAULT 'WireGuard',
            protocols TEXT NOT NULL DEFAULT 'WireGuard',
            latency INTEGER NOT NULL DEFAULT 0,
            load_percentage INTEGER NOT NULL DEFAULT 0,
            max_connections INTEGER NOT NULL DEFAULT 1000,
            current_connections INTEGER NOT NULL DEFAULT 0,
            is_active INTEGER NOT NULL DEFAULT 1,
            is_premium INTEGER NOT NULL DEFAULT 0,
            status TEXT NOT NULL DEFAULT 'online',
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
        )
        "#,
    )
    .execute(pool)
    .await?;

    // User sessions table
    sqlx::query(
        r#"
        CREATE TABLE IF NOT EXISTS user_sessions (
            id TEXT PRIMARY KEY,
            user_id TEXT NOT NULL,
            server_id TEXT NOT NULL,
            connect_time TEXT NOT NULL,
            disconnect_time TEXT,
            ip_address TEXT NOT NULL,
            bytes_in INTEGER NOT NULL DEFAULT 0,
            bytes_out INTEGER NOT NULL DEFAULT 0,
            status TEXT NOT NULL DEFAULT 'active'
        )
        "#,
    )
    .execute(pool)
    .await?;

    // Subscriptions table (expanded)
    sqlx::query(
        r#"
        CREATE TABLE IF NOT EXISTS subscriptions (
            id TEXT PRIMARY KEY,
            user_id TEXT NOT NULL,
            plan_type TEXT NOT NULL,
            status TEXT NOT NULL DEFAULT 'active',
            start_date TEXT NOT NULL,
            end_date TEXT,
            auto_renew INTEGER NOT NULL DEFAULT 1,
            max_bandwidth INTEGER NOT NULL DEFAULT 10737418240,
            max_connections INTEGER NOT NULL DEFAULT 1,
            features TEXT NOT NULL DEFAULT '',
            is_active INTEGER NOT NULL DEFAULT 1,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
        )
        "#,
    )
    .execute(pool)
    .await?;

    // Refresh tokens table
    sqlx::query(
        r#"
        CREATE TABLE IF NOT EXISTS refresh_tokens (
            id TEXT PRIMARY KEY,
            user_id TEXT NOT NULL,
            token_hash TEXT NOT NULL,
            expires_at TEXT NOT NULL,
            created_at TEXT NOT NULL
        )
        "#,
    )
    .execute(pool)
    .await?;

    // Password reset tokens table
    sqlx::query(
        r#"
        CREATE TABLE IF NOT EXISTS password_reset_tokens (
            id TEXT PRIMARY KEY,
            user_id TEXT NOT NULL,
            token_hash TEXT NOT NULL,
            expires_at TEXT NOT NULL,
            used INTEGER NOT NULL DEFAULT 0,
            created_at TEXT NOT NULL
        )
        "#,
    )
    .execute(pool)
    .await?;

    Ok(())
}

// ─────────────────────────────────────────────
// Helper
// ─────────────────────────────────────────────

fn parse_datetime(datetime_str: &str) -> Result<DateTime<Utc>, chrono::ParseError> {
    // Try RFC 3339 first (e.g. "2026-03-08T09:55:16.123Z")
    if let Ok(dt) = DateTime::parse_from_rfc3339(datetime_str) {
        return Ok(dt.with_timezone(&Utc));
    }
    // Fall back to SQLite datetime format (e.g. "2026-03-08 09:55:16")
    chrono::NaiveDateTime::parse_from_str(datetime_str, "%Y-%m-%d %H:%M:%S")
        .map(|naive| naive.and_utc())
}

// ─────────────────────────────────────────────
// User operations
// ─────────────────────────────────────────────

pub async fn create_user(
    pool: &DbPool,
    name: &str,
    email: &str,
    password_hash: &str,
) -> Result<User, sqlx::Error> {
    let id = Uuid::new_v4();
    let now = Utc::now().to_rfc3339();
    // Use the part before '@' as a default username
    let username = email.split('@').next().unwrap_or("user").to_string();

    sqlx::query(
        "INSERT INTO users (id, username, name, email, password_hash, avatar_url, is_email_verified, two_factor_enabled, created_at, updated_at, is_active) VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9, ?10, ?11)"
    )
    .bind(id.to_string())
    .bind(&username)
    .bind(name)
    .bind(email)
    .bind(password_hash)
    .bind(Option::<String>::None)
    .bind(0)
    .bind(0)
    .bind(&now)
    .bind(&now)
    .bind(1)
    .execute(pool)
    .await?;

    Ok(User {
        id,
        username,
        name: name.to_string(),
        email: email.to_string(),
        password_hash: password_hash.to_string(),
        avatar_url: None,
        is_email_verified: false,
        two_factor_enabled: false,
        created_at: Utc::now(),
        updated_at: Utc::now(),
        is_active: true,
    })
}

fn row_to_user(row: &sqlx::sqlite::SqliteRow) -> Result<User, sqlx::Error> {
    let id: String = row.get("id");
    let username: String = row.get("username");
    let name: String = row.get("name");
    let email: String = row.get("email");
    let password_hash: String = row.get("password_hash");
    let avatar_url: Option<String> = row.get("avatar_url");
    let is_email_verified: i32 = row.get("is_email_verified");
    let two_factor_enabled: i32 = row.get("two_factor_enabled");
    let created_at_str: String = row.get("created_at");
    let updated_at_str: String = row.get("updated_at");
    let is_active: i32 = row.get("is_active");

    let created_at =
        parse_datetime(&created_at_str).map_err(|e| sqlx::Error::Decode(Box::new(e)))?;
    let updated_at =
        parse_datetime(&updated_at_str).map_err(|e| sqlx::Error::Decode(Box::new(e)))?;

    Ok(User {
        id: Uuid::from_str(&id).map_err(|e| sqlx::Error::Decode(Box::new(e)))?,
        username,
        name,
        email,
        password_hash,
        avatar_url,
        is_email_verified: is_email_verified == 1,
        two_factor_enabled: two_factor_enabled == 1,
        created_at,
        updated_at,
        is_active: is_active == 1,
    })
}

pub async fn get_user_by_email(pool: &DbPool, email: &str) -> Result<Option<User>, sqlx::Error> {
    let row = sqlx::query(
        "SELECT id, username, name, email, password_hash, avatar_url, is_email_verified, two_factor_enabled, created_at, updated_at, is_active FROM users WHERE email = ?1"
    )
    .bind(email)
    .fetch_optional(pool)
    .await?;

    match row {
        Some(row) => Ok(Some(row_to_user(&row)?)),
        None => Ok(None),
    }
}

pub async fn get_user_by_username(
    pool: &DbPool,
    username: &str,
) -> Result<Option<User>, sqlx::Error> {
    let row = sqlx::query(
        "SELECT id, username, name, email, password_hash, avatar_url, is_email_verified, two_factor_enabled, created_at, updated_at, is_active FROM users WHERE username = ?1"
    )
    .bind(username)
    .fetch_optional(pool)
    .await?;

    match row {
        Some(row) => Ok(Some(row_to_user(&row)?)),
        None => Ok(None),
    }
}

pub async fn get_user_by_id(pool: &DbPool, id: Uuid) -> Result<Option<User>, sqlx::Error> {
    let row = sqlx::query(
        "SELECT id, username, name, email, password_hash, avatar_url, is_email_verified, two_factor_enabled, created_at, updated_at, is_active FROM users WHERE id = ?1"
    )
    .bind(id.to_string())
    .fetch_optional(pool)
    .await?;

    match row {
        Some(row) => Ok(Some(row_to_user(&row)?)),
        None => Ok(None),
    }
}

pub async fn update_user_profile(
    pool: &DbPool,
    user_id: Uuid,
    name: Option<&str>,
    avatar_url: Option<&str>,
) -> Result<Option<User>, sqlx::Error> {
    let now = Utc::now().to_rfc3339();

    if let Some(name) = name {
        sqlx::query("UPDATE users SET name = ?1, updated_at = ?2 WHERE id = ?3")
            .bind(name)
            .bind(&now)
            .bind(user_id.to_string())
            .execute(pool)
            .await?;
    }

    if let Some(avatar_url) = avatar_url {
        sqlx::query("UPDATE users SET avatar_url = ?1, updated_at = ?2 WHERE id = ?3")
            .bind(avatar_url)
            .bind(&now)
            .bind(user_id.to_string())
            .execute(pool)
            .await?;
    }

    get_user_by_id(pool, user_id).await
}

// ─────────────────────────────────────────────
// Server operations
// ─────────────────────────────────────────────

fn row_to_server(row: &sqlx::sqlite::SqliteRow) -> Result<VpnServer, sqlx::Error> {
    let id: String = row.get("id");
    let name: String = row.get("name");
    let city: String = row.get("city");
    let country: String = row.get("country");
    let country_code: String = row.get("country_code");
    let region: String = row.get("region");
    let ip_address: String = row.get("ip_address");
    let port: i32 = row.get("port");
    let public_key: String = row.get("public_key");
    let endpoint: String = row.get("endpoint");
    let dns_servers: String = row.get("dns_servers");
    let protocol: String = row.get("protocol");
    let protocols: String = row.get("protocols");
    let latency: i32 = row.get("latency");
    let load_percentage: i32 = row.get("load_percentage");
    let max_connections: i32 = row.get("max_connections");
    let current_connections: i32 = row.get("current_connections");
    let is_active: i32 = row.get("is_active");
    let is_premium: i32 = row.get("is_premium");
    let status: String = row.get("status");
    let created_at_str: String = row.get("created_at");
    let updated_at_str: String = row.get("updated_at");

    let created_at =
        parse_datetime(&created_at_str).map_err(|e| sqlx::Error::Decode(Box::new(e)))?;
    let updated_at =
        parse_datetime(&updated_at_str).map_err(|e| sqlx::Error::Decode(Box::new(e)))?;

    Ok(VpnServer {
        id: Uuid::from_str(&id).map_err(|e| sqlx::Error::Decode(Box::new(e)))?,
        name,
        city,
        country,
        country_code,
        region,
        ip_address,
        port,
        public_key,
        endpoint,
        dns_servers,
        protocol,
        protocols,
        latency,
        load_percentage,
        max_connections,
        current_connections,
        is_active: is_active == 1,
        is_premium: is_premium == 1,
        status,
        created_at,
        updated_at,
    })
}

pub async fn get_all_servers(pool: &DbPool) -> Result<Vec<VpnServer>, sqlx::Error> {
    let rows = sqlx::query("SELECT * FROM vpn_servers ORDER BY latency ASC")
        .fetch_all(pool)
        .await?;

    let mut servers = Vec::new();
    for row in rows {
        servers.push(row_to_server(&row)?);
    }
    Ok(servers)
}

pub async fn get_server_by_id(pool: &DbPool, id: Uuid) -> Result<Option<VpnServer>, sqlx::Error> {
    let row = sqlx::query("SELECT * FROM vpn_servers WHERE id = ?1")
        .bind(id.to_string())
        .fetch_optional(pool)
        .await?;

    match row {
        Some(row) => Ok(Some(row_to_server(&row)?)),
        None => Ok(None),
    }
}

// ─────────────────────────────────────────────
// Session operations
// ─────────────────────────────────────────────

pub async fn create_session(
    pool: &DbPool,
    user_id: Uuid,
    server_id: Uuid,
    ip_address: &str,
) -> Result<UserSession, sqlx::Error> {
    let id = Uuid::new_v4();
    let now = Utc::now().to_rfc3339();

    sqlx::query(
        "INSERT INTO user_sessions (id, user_id, server_id, connect_time, ip_address, bytes_in, bytes_out, status) VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8)"
    )
    .bind(id.to_string())
    .bind(user_id.to_string())
    .bind(server_id.to_string())
    .bind(&now)
    .bind(ip_address)
    .bind(0i64)
    .bind(0i64)
    .bind("active")
    .execute(pool)
    .await?;

    Ok(UserSession {
        id,
        user_id,
        server_id,
        connect_time: Utc::now(),
        disconnect_time: None,
        ip_address: ip_address.to_string(),
        bytes_in: 0,
        bytes_out: 0,
        status: "active".to_string(),
    })
}

pub async fn disconnect_session(pool: &DbPool, session_id: Uuid) -> Result<(), sqlx::Error> {
    let now = Utc::now().to_rfc3339();

    sqlx::query("UPDATE user_sessions SET disconnect_time = ?1, status = ?2 WHERE id = ?3")
        .bind(&now)
        .bind("disconnected")
        .bind(session_id.to_string())
        .execute(pool)
        .await?;

    Ok(())
}

// ─────────────────────────────────────────────
// Refresh token operations
// ─────────────────────────────────────────────

pub async fn store_refresh_token(
    pool: &DbPool,
    user_id: Uuid,
    token_hash: &str,
    expires_at: DateTime<Utc>,
) -> Result<(), sqlx::Error> {
    let id = Uuid::new_v4();
    let now = Utc::now().to_rfc3339();

    sqlx::query(
        "INSERT INTO refresh_tokens (id, user_id, token_hash, expires_at, created_at) VALUES (?1, ?2, ?3, ?4, ?5)"
    )
    .bind(id.to_string())
    .bind(user_id.to_string())
    .bind(token_hash)
    .bind(expires_at.to_rfc3339())
    .bind(&now)
    .execute(pool)
    .await?;

    Ok(())
}

pub async fn find_refresh_token(
    pool: &DbPool,
    token_hash: &str,
) -> Result<Option<(Uuid, DateTime<Utc>)>, sqlx::Error> {
    let row = sqlx::query("SELECT user_id, expires_at FROM refresh_tokens WHERE token_hash = ?1")
        .bind(token_hash)
        .fetch_optional(pool)
        .await?;

    match row {
        Some(row) => {
            let user_id_str: String = row.get("user_id");
            let expires_at_str: String = row.get("expires_at");
            let user_id =
                Uuid::from_str(&user_id_str).map_err(|e| sqlx::Error::Decode(Box::new(e)))?;
            let expires_at =
                parse_datetime(&expires_at_str).map_err(|e| sqlx::Error::Decode(Box::new(e)))?;
            Ok(Some((user_id, expires_at)))
        }
        None => Ok(None),
    }
}

pub async fn delete_refresh_token(pool: &DbPool, token_hash: &str) -> Result<(), sqlx::Error> {
    sqlx::query("DELETE FROM refresh_tokens WHERE token_hash = ?1")
        .bind(token_hash)
        .execute(pool)
        .await?;
    Ok(())
}

pub async fn delete_user_refresh_tokens(pool: &DbPool, user_id: Uuid) -> Result<(), sqlx::Error> {
    sqlx::query("DELETE FROM refresh_tokens WHERE user_id = ?1")
        .bind(user_id.to_string())
        .execute(pool)
        .await?;
    Ok(())
}

// ─────────────────────────────────────────────
// Subscription operations
// ─────────────────────────────────────────────

pub async fn get_user_subscription(
    pool: &DbPool,
    user_id: Uuid,
) -> Result<Option<Subscription>, sqlx::Error> {
    let row = sqlx::query(
        "SELECT * FROM subscriptions WHERE user_id = ?1 AND is_active = 1 ORDER BY created_at DESC LIMIT 1"
    )
    .bind(user_id.to_string())
    .fetch_optional(pool)
    .await?;

    match row {
        Some(row) => {
            let id: String = row.get("id");
            let user_id: String = row.get("user_id");
            let plan_type: String = row.get("plan_type");
            let status: String = row.get("status");
            let start_date_str: String = row.get("start_date");
            let end_date_str: Option<String> = row.get("end_date");
            let auto_renew: i32 = row.get("auto_renew");
            let max_bandwidth: i64 = row.get("max_bandwidth");
            let max_connections: i32 = row.get("max_connections");
            let features: String = row.get("features");
            let is_active: i32 = row.get("is_active");
            let created_at_str: String = row.get("created_at");
            let updated_at_str: String = row.get("updated_at");

            Ok(Some(Subscription {
                id: Uuid::from_str(&id).map_err(|e| sqlx::Error::Decode(Box::new(e)))?,
                user_id: Uuid::from_str(&user_id).map_err(|e| sqlx::Error::Decode(Box::new(e)))?,
                plan_type,
                status,
                start_date: parse_datetime(&start_date_str)
                    .map_err(|e| sqlx::Error::Decode(Box::new(e)))?,
                end_date: end_date_str
                    .map(|s| parse_datetime(&s))
                    .transpose()
                    .map_err(|e| sqlx::Error::Decode(Box::new(e)))?,
                auto_renew: auto_renew == 1,
                max_bandwidth,
                max_connections,
                features,
                is_active: is_active == 1,
                created_at: parse_datetime(&created_at_str)
                    .map_err(|e| sqlx::Error::Decode(Box::new(e)))?,
                updated_at: parse_datetime(&updated_at_str)
                    .map_err(|e| sqlx::Error::Decode(Box::new(e)))?,
            }))
        }
        None => Ok(None),
    }
}

// ─────────────────────────────────────────────
// Password reset token operations
// ─────────────────────────────────────────────

pub async fn store_password_reset_token(
    pool: &DbPool,
    user_id: Uuid,
    token_hash: &str,
    expires_at: DateTime<Utc>,
) -> Result<(), sqlx::Error> {
    let id = Uuid::new_v4();
    let now = Utc::now().to_rfc3339();

    sqlx::query(
        "INSERT INTO password_reset_tokens (id, user_id, token_hash, expires_at, used, created_at) VALUES (?1, ?2, ?3, ?4, ?5, ?6)"
    )
    .bind(id.to_string())
    .bind(user_id.to_string())
    .bind(token_hash)
    .bind(expires_at.to_rfc3339())
    .bind(0)
    .bind(&now)
    .execute(pool)
    .await?;

    Ok(())
}

pub async fn find_password_reset_token(
    pool: &DbPool,
    token_hash: &str,
) -> Result<Option<(Uuid, DateTime<Utc>, bool)>, sqlx::Error> {
    let row = sqlx::query(
        "SELECT user_id, expires_at, used FROM password_reset_tokens WHERE token_hash = ?1",
    )
    .bind(token_hash)
    .fetch_optional(pool)
    .await?;

    match row {
        Some(row) => {
            let user_id_str: String = row.get("user_id");
            let expires_at_str: String = row.get("expires_at");
            let used: i32 = row.get("used");
            let user_id =
                Uuid::from_str(&user_id_str).map_err(|e| sqlx::Error::Decode(Box::new(e)))?;
            let expires_at =
                parse_datetime(&expires_at_str).map_err(|e| sqlx::Error::Decode(Box::new(e)))?;
            Ok(Some((user_id, expires_at, used == 1)))
        }
        None => Ok(None),
    }
}

pub async fn mark_reset_token_used(pool: &DbPool, token_hash: &str) -> Result<(), sqlx::Error> {
    sqlx::query("UPDATE password_reset_tokens SET used = 1 WHERE token_hash = ?1")
        .bind(token_hash)
        .execute(pool)
        .await?;
    Ok(())
}

pub async fn update_user_password(
    pool: &DbPool,
    user_id: Uuid,
    new_password_hash: &str,
) -> Result<(), sqlx::Error> {
    let now = Utc::now().to_rfc3339();
    sqlx::query("UPDATE users SET password_hash = ?1, updated_at = ?2 WHERE id = ?3")
        .bind(new_password_hash)
        .bind(&now)
        .bind(user_id.to_string())
        .execute(pool)
        .await?;
    Ok(())
}

pub async fn seed_servers_if_empty(pool: &DbPool) -> Result<(), sqlx::Error> {
    let count: (i64,) = sqlx::query_as("SELECT COUNT(*) FROM vpn_servers")
        .fetch_one(pool)
        .await?;
    if count.0 > 0 {
        tracing::info!("Database already has {} servers, skipping seed", count.0);
        return Ok(());
    }
    tracing::info!("Seeding VPN servers...");
    sqlx::query(
        r#"INSERT OR IGNORE INTO vpn_servers (id, name, city, country, country_code, region, ip_address, port, public_key, endpoint, dns_servers, protocol, protocols, latency, load_percentage, max_connections, current_connections, is_active, is_premium, status, created_at, updated_at) VALUES
        ('550e8400-e29b-41d4-a716-446655440001', 'US East 1', 'New York', 'United States', 'US', 'North America', '198.51.100.1', 51820, 'wg-pubkey-us-east-1', '198.51.100.1:51820', '1.1.1.1,1.0.0.1', 'WireGuard', 'WireGuard,OpenVPN', 25, 45, 1000, 234, 1, 0, 'online', datetime('now'), datetime('now')),
        ('550e8400-e29b-41d4-a716-446655440002', 'US West 1', 'Los Angeles', 'United States', 'US', 'North America', '198.51.100.2', 51820, 'wg-pubkey-us-west-1', '198.51.100.2:51820', '1.1.1.1,1.0.0.1', 'WireGuard', 'WireGuard,OpenVPN', 35, 62, 1000, 456, 1, 0, 'online', datetime('now'), datetime('now')),
        ('550e8400-e29b-41d4-a716-446655440003', 'UK London 1', 'London', 'United Kingdom', 'GB', 'Europe', '198.51.100.3', 51820, 'wg-pubkey-uk-lon-1', '198.51.100.3:51820', '1.1.1.1,1.0.0.1', 'WireGuard', 'WireGuard,OpenVPN', 120, 38, 1000, 178, 1, 0, 'online', datetime('now'), datetime('now')),
        ('550e8400-e29b-41d4-a716-446655440004', 'DE Frankfurt 1', 'Frankfurt', 'Germany', 'DE', 'Europe', '198.51.100.4', 51820, 'wg-pubkey-de-fra-1', '198.51.100.4:51820', '1.1.1.1,1.0.0.1', 'WireGuard', 'WireGuard', 130, 28, 1000, 90, 1, 0, 'online', datetime('now'), datetime('now')),
        ('550e8400-e29b-41d4-a716-446655440005', 'JP Tokyo 1', 'Tokyo', 'Japan', 'JP', 'Asia', '198.51.100.5', 51820, 'wg-pubkey-jp-tyo-1', '198.51.100.5:51820', '1.1.1.1,1.0.0.1', 'WireGuard', 'WireGuard', 180, 55, 1000, 320, 1, 1, 'online', datetime('now'), datetime('now')),
        ('550e8400-e29b-41d4-a716-446655440006', 'SG Singapore 1', 'Singapore', 'Singapore', 'SG', 'Asia', '198.51.100.6', 51820, 'wg-pubkey-sg-1', '198.51.100.6:51820', '1.1.1.1,1.0.0.1', 'WireGuard', 'WireGuard,OpenVPN', 160, 41, 1000, 205, 1, 1, 'online', datetime('now'), datetime('now')),
        ('550e8400-e29b-41d4-a716-446655440007', 'IN Mumbai 1', 'Mumbai', 'India', 'IN', 'Asia', '198.51.100.7', 51820, 'wg-pubkey-in-mum-1', '198.51.100.7:51820', '1.1.1.1,1.0.0.1', 'WireGuard', 'WireGuard', 50, 72, 1000, 510, 1, 0, 'online', datetime('now'), datetime('now')),
        ('550e8400-e29b-41d4-a716-446655440008', 'AU Sydney 1', 'Sydney', 'Australia', 'AU', 'Oceania', '198.51.100.8', 51820, 'wg-pubkey-au-syd-1', '198.51.100.8:51820', '1.1.1.1,1.0.0.1', 'WireGuard', 'WireGuard', 200, 22, 1000, 67, 1, 1, 'online', datetime('now'), datetime('now'))
        "#
    )
    .execute(pool)
    .await?;
    tracing::info!("✅ Seeded 8 VPN servers.");
    Ok(())
}

pub async fn get_session_by_id(
    pool: &DbPool,
    session_id: Uuid,
) -> Result<Option<UserSession>, sqlx::Error> {
    let row = sqlx::query("SELECT * FROM user_sessions WHERE id = ?1")
        .bind(session_id.to_string())
        .fetch_optional(pool)
        .await?;
    match row {
        Some(row) => {
            let id: String = row.get("id");
            let uid: String = row.get("user_id");
            let sid: String = row.get("server_id");
            let conn: String = row.get("connect_time");
            let disc: Option<String> = row.get("disconnect_time");
            let ip: String = row.get("ip_address");
            Ok(Some(UserSession {
                id: Uuid::from_str(&id).map_err(|e| sqlx::Error::Decode(Box::new(e)))?,
                user_id: Uuid::from_str(&uid).map_err(|e| sqlx::Error::Decode(Box::new(e)))?,
                server_id: Uuid::from_str(&sid).map_err(|e| sqlx::Error::Decode(Box::new(e)))?,
                connect_time: parse_datetime(&conn)
                    .map_err(|e| sqlx::Error::Decode(Box::new(e)))?,
                disconnect_time: disc
                    .map(|s| parse_datetime(&s))
                    .transpose()
                    .map_err(|e| sqlx::Error::Decode(Box::new(e)))?,
                ip_address: ip,
                bytes_in: row.get("bytes_in"),
                bytes_out: row.get("bytes_out"),
                status: row.get("status"),
            }))
        }
        None => Ok(None),
    }
}

pub async fn get_user_sessions(
    pool: &DbPool,
    user_id: Uuid,
) -> Result<Vec<UserSession>, sqlx::Error> {
    let rows = sqlx::query(
        "SELECT * FROM user_sessions WHERE user_id = ?1 ORDER BY connect_time DESC LIMIT 50",
    )
    .bind(user_id.to_string())
    .fetch_all(pool)
    .await?;
    let mut sessions = Vec::new();
    for row in rows {
        let id: String = row.get("id");
        let uid: String = row.get("user_id");
        let sid: String = row.get("server_id");
        let conn: String = row.get("connect_time");
        let disc: Option<String> = row.get("disconnect_time");
        let ip: String = row.get("ip_address");
        sessions.push(UserSession {
            id: Uuid::from_str(&id).map_err(|e| sqlx::Error::Decode(Box::new(e)))?,
            user_id: Uuid::from_str(&uid).map_err(|e| sqlx::Error::Decode(Box::new(e)))?,
            server_id: Uuid::from_str(&sid).map_err(|e| sqlx::Error::Decode(Box::new(e)))?,
            connect_time: parse_datetime(&conn).map_err(|e| sqlx::Error::Decode(Box::new(e)))?,
            disconnect_time: disc
                .map(|s| parse_datetime(&s))
                .transpose()
                .map_err(|e| sqlx::Error::Decode(Box::new(e)))?,
            ip_address: ip,
            bytes_in: row.get("bytes_in"),
            bytes_out: row.get("bytes_out"),
            status: row.get("status"),
        });
    }
    Ok(sessions)
}

pub async fn create_subscription(
    pool: &DbPool,
    user_id: Uuid,
    plan_type: &str,
    max_bandwidth: i64,
    max_connections: i32,
    features: &str,
) -> Result<Subscription, sqlx::Error> {
    let id = Uuid::new_v4();
    let now = Utc::now().to_rfc3339();
    let end_date = if plan_type != "free" {
        Some((Utc::now() + chrono::Duration::days(30)).to_rfc3339())
    } else {
        None
    };
    sqlx::query(
        "INSERT INTO subscriptions (id, user_id, plan_type, status, start_date, end_date, auto_renew, max_bandwidth, max_connections, features, is_active, created_at, updated_at) VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9, ?10, ?11, ?12, ?13)"
    )
    .bind(id.to_string())
    .bind(user_id.to_string())
    .bind(plan_type)
    .bind("active")
    .bind(&now)
    .bind(&end_date)
    .bind(1)
    .bind(max_bandwidth)
    .bind(max_connections)
    .bind(features)
    .bind(1)
    .bind(&now)
    .bind(&now)
    .execute(pool)
    .await?;
    Ok(Subscription {
        id,
        user_id,
        plan_type: plan_type.to_string(),
        status: "active".to_string(),
        start_date: Utc::now(),
        end_date: end_date.map(|_| Utc::now() + chrono::Duration::days(30)),
        auto_renew: true,
        max_bandwidth,
        max_connections,
        features: features.to_string(),
        is_active: true,
        created_at: Utc::now(),
        updated_at: Utc::now(),
    })
}
