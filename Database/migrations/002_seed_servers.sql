-- SafeMesh VPN Database: Seed Data
-- Inserts sample VPN servers for development/testing

INSERT OR IGNORE INTO vpn_servers (id, name, city, country, country_code, region, ip_address, port, public_key, endpoint, dns_servers, protocol, protocols, latency, load_percentage, max_connections, current_connections, is_active, is_premium, status, created_at, updated_at)
VALUES
    ('550e8400-e29b-41d4-a716-446655440001', 'US East 1', 'New York', 'United States', 'US', 'North America', '198.51.100.1', 51820, 'wg-pubkey-us-east-1', '198.51.100.1:51820', '1.1.1.1,1.0.0.1', 'WireGuard', 'WireGuard,OpenVPN', 25, 45, 1000, 234, 1, 0, 'online', datetime('now'), datetime('now')),

    ('550e8400-e29b-41d4-a716-446655440002', 'US West 1', 'Los Angeles', 'United States', 'US', 'North America', '198.51.100.2', 51820, 'wg-pubkey-us-west-1', '198.51.100.2:51820', '1.1.1.1,1.0.0.1', 'WireGuard', 'WireGuard,OpenVPN', 35, 62, 1000, 456, 1, 0, 'online', datetime('now'), datetime('now')),

    ('550e8400-e29b-41d4-a716-446655440003', 'UK London 1', 'London', 'United Kingdom', 'GB', 'Europe', '198.51.100.3', 51820, 'wg-pubkey-uk-lon-1', '198.51.100.3:51820', '1.1.1.1,1.0.0.1', 'WireGuard', 'WireGuard,OpenVPN', 120, 38, 1000, 178, 1, 0, 'online', datetime('now'), datetime('now')),

    ('550e8400-e29b-41d4-a716-446655440004', 'DE Frankfurt 1', 'Frankfurt', 'Germany', 'DE', 'Europe', '198.51.100.4', 51820, 'wg-pubkey-de-fra-1', '198.51.100.4:51820', '1.1.1.1,1.0.0.1', 'WireGuard', 'WireGuard', 130, 28, 1000, 90, 1, 0, 'online', datetime('now'), datetime('now')),

    ('550e8400-e29b-41d4-a716-446655440005', 'JP Tokyo 1', 'Tokyo', 'Japan', 'JP', 'Asia', '198.51.100.5', 51820, 'wg-pubkey-jp-tyo-1', '198.51.100.5:51820', '1.1.1.1,1.0.0.1', 'WireGuard', 'WireGuard', 180, 55, 1000, 320, 1, 1, 'online', datetime('now'), datetime('now')),

    ('550e8400-e29b-41d4-a716-446655440006', 'SG Singapore 1', 'Singapore', 'Singapore', 'SG', 'Asia', '198.51.100.6', 51820, 'wg-pubkey-sg-1', '198.51.100.6:51820', '1.1.1.1,1.0.0.1', 'WireGuard', 'WireGuard,OpenVPN', 160, 41, 1000, 205, 1, 1, 'online', datetime('now'), datetime('now')),

    ('550e8400-e29b-41d4-a716-446655440007', 'IN Mumbai 1', 'Mumbai', 'India', 'IN', 'Asia', '198.51.100.7', 51820, 'wg-pubkey-in-mum-1', '198.51.100.7:51820', '1.1.1.1,1.0.0.1', 'WireGuard', 'WireGuard', 50, 72, 1000, 510, 1, 0, 'online', datetime('now'), datetime('now')),

    ('550e8400-e29b-41d4-a716-446655440008', 'AU Sydney 1', 'Sydney', 'Australia', 'AU', 'Oceania', '198.51.100.8', 51820, 'wg-pubkey-au-syd-1', '198.51.100.8:51820', '1.1.1.1,1.0.0.1', 'WireGuard', 'WireGuard', 200, 22, 1000, 67, 1, 1, 'online', datetime('now'), datetime('now'));
