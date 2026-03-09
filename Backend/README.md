# VPN Application Backend - Rust Implementation

## Overview
This is a complete backend implementation for a VPN application built with Rust. The backend provides RESTful APIs for user authentication, VPN server management, connection tracking, and subscription management.

## Features Implemented

### 1. Core Architecture
- **Web Framework**: Actix-web for high-performance HTTP server
- **Database**: SQLite with SQLx ORM
- **Authentication**: JWT-based authentication with bcrypt password hashing
- **Configuration**: Environment-based configuration management
- **Logging**: Tracing for structured logging

### 2. API Endpoints
- **Authentication**
  - `POST /api/v1/register` - User registration
  - `POST /api/v1/login` - User login with JWT token generation

- **VPN Servers**
  - `GET /api/v1/servers` - List all available VPN servers

- **Connections**
  - `POST /api/v1/connect/{server_id}` - Connect to a VPN server
  - `POST /api/v1/disconnect/{session_id}` - Disconnect from a VPN server

- **User Profile**
  - `GET /api/v1/profile` - Get user profile information (placeholder)

### 3. Data Models
- **User**: User account with authentication details
- **VpnServer**: VPN server configuration and status
- **UserSession**: Connection tracking and statistics
- **Subscription**: User subscription information

### 4. Security Features
- Password hashing with bcrypt
- JWT token-based authentication
- Input validation and sanitization

## Project Structure
```
Backend/
├── Cargo.toml              # Project dependencies
├── .env                   # Environment configuration
├── src/
│   ├── main.rs            # Application entry point
│   ├── lib.rs             # Library exports
│   ├── api/               # API routing
│   ├── auth/              # Authentication logic
│   ├── config/            # Configuration management
│   ├── database/          # Database operations
│   ├── handlers/          # Request handlers
│   ├── models/            # Data models
│   ├── services/          # Business logic
│   └── utils/             # Utility functions
└── migrations/            # Database migrations
```

## Setup Instructions

1. **Prerequisites**
   - Rust and Cargo installed
   - SQLite (usually pre-installed on most systems)

2. **Configuration**
   - Copy `.env.example` to `.env` and adjust settings as needed
   - Default settings work out of the box

3. **Running the Application**
   ```bash
   cd Backend
   cargo run
   ```

4. **Building for Production**
   ```bash
   cargo build --release
   ```

## API Usage Examples

### User Registration
```bash
curl -X POST http://localhost:8080/api/v1/register \
  -H "Content-Type: application/json" \
  -d '{"username":"testuser","email":"test@example.com","password":"password123"}'
```

### User Login
```bash
curl -X POST http://localhost:8080/api/v1/login \
  -H "Content-Type: application/json" \
  -d '{"username":"testuser","password":"password123"}'
```

### Get VPN Servers
```bash
curl -X GET http://localhost:8080/api/v1/servers \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

## Future Enhancements
- Implement full middleware for JWT validation
- Add rate limiting and DDoS protection
- Implement subscription management
- Add server health checking
- Implement OpenAPI/Swagger documentation
- Add unit and integration tests
- Implement load balancing logic