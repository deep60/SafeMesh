use lettre::{
    transport::smtp::authentication::Credentials, AsyncSmtpTransport, AsyncTransport, Message,
    Tokio1Executor,
};

/// SMTP configuration (all optional — falls back to console logging)
#[derive(Debug, Clone)]
pub struct SmtpConfig {
    pub host: Option<String>,
    pub port: Option<u16>,
    pub user: Option<String>,
    pub password: Option<String>,
    pub from_email: Option<String>,
}

impl SmtpConfig {
    pub fn from_env() -> Self {
        Self {
            host: std::env::var("SMTP_HOST").ok(),
            port: std::env::var("SMTP_PORT").ok().and_then(|p| p.parse().ok()),
            user: std::env::var("SMTP_USER").ok(),
            password: std::env::var("SMTP_PASSWORD").ok(),
            from_email: std::env::var("SMTP_FROM_EMAIL").ok(),
        }
    }

    pub fn is_configured(&self) -> bool {
        self.host.is_some() && self.user.is_some() && self.password.is_some()
    }
}

/// Send a password reset email. Falls back to console logging if SMTP is not configured.
pub async fn send_password_reset_email(
    to_email: &str,
    reset_token: &str,
    smtp_config: &SmtpConfig,
) -> Result<(), Box<dyn std::error::Error>> {
    let reset_link = format!("https://safemesh.com/reset-password?token={}", reset_token);

    if !smtp_config.is_configured() {
        tracing::info!(
            "📧 [DEV MODE] Password reset email for {}: {}",
            to_email,
            reset_link
        );
        tracing::info!("   Token: {}", reset_token);
        tracing::info!("   (Set SMTP_HOST, SMTP_USER, SMTP_PASSWORD env vars to send real emails)");
        return Ok(());
    }

    let from = smtp_config
        .from_email
        .as_deref()
        .unwrap_or("noreply@safemesh.com");

    let email = Message::builder()
        .from(from.parse()?)
        .to(to_email.parse()?)
        .subject("SafeMesh — Password Reset")
        .body(format!(
            "Hi,\n\n\
             You requested a password reset for your SafeMesh account.\n\n\
             Click the link below to reset your password (valid for 1 hour):\n\
             {}\n\n\
             If you didn't request this, you can safely ignore this email.\n\n\
             — SafeMesh Team",
            reset_link
        ))?;

    let host = smtp_config.host.as_deref().unwrap();
    let creds = Credentials::new(
        smtp_config.user.clone().unwrap(),
        smtp_config.password.clone().unwrap(),
    );

    let mailer = AsyncSmtpTransport::<Tokio1Executor>::relay(host)?
        .credentials(creds)
        .build();

    mailer.send(email).await?;
    tracing::info!("Password reset email sent to {}", to_email);
    Ok(())
}
