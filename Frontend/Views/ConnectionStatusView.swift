//
//  ConnectionStatusView.swift
//  SafeMesh
//
//  Created by P Deepanshu on 23/02/26.
//

import SwiftUI

struct ConnectionStatusView: View {
    let status: VPNStatus
    let server: VPNServer?
    let duration: String?

    var body: some View {
        HStack(spacing: 16) {
            // Status indicator
            ZStack {
                Circle()
                    .fill(status.color.opacity(0.2))
                    .frame(width: 50, height: 50)

                if status == .connecting || status == .disconnecting {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: status.icon)
                        .font(.title3)
                        .foregroundColor(status.color)
                }
            }

            // Status info
            VStack(alignment: .leading, spacing: 4) {
                Text(status.displayText)
                    .font(.headline)

                if let server = server {
                    HStack(spacing: 4) {
                        CountryFlag(countryCode: server.countryCode, size: 16)
                        Text("\(server.city), \(server.country)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }

                if let duration = duration {
                    Text(duration)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // IP address
            if status == .connected, let ip = currentIP {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(ip)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("IP")
                        .font(.caption2)
                        .foregroundColor(.secondary.opacity(0.7))
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }

    private var currentIP: String? {
        // In a real app, this would come from the VPN manager
        "192.168.1.1"
    }
}

#Preview {
    VStack(spacing: 12) {
        ConnectionStatusView(status: .disconnected, server: nil, duration: nil)
        ConnectionStatusView(status: .connecting, server: .mock, duration: nil)
        ConnectionStatusView(status: .connected, server: .mock, duration: "15:32")
    }
    .padding()
}

