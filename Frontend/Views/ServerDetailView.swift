//
//  ServerDetailView.swift
//  SafeMesh
//
//  Created by P Deepanshu on 23/02/26.
//

import SwiftUI

struct ServerDetailView: View {
    let server: VPNServer
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 100, height: 100)

                        CountryFlag(countryCode: server.countryCode)
                            .font(.system(size: 50))
                    }

                    VStack(spacing: 4) {
                        Text(server.city)
                            .font(.title2)
                            .fontWeight(.bold)

                        Text(server.country)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.top, 20)

                // Connection quality
                ConnectionQualityCard(latency: server.latency, load:
server.loadPercentage)

                // Server details
                VStack(spacing: 16) {
                    DetailRow(label: "Region", value: server.region.rawValue)
                    DetailRow(label: "IP Address", value: server.ipAddress)
                    DetailRow(label: "Protocol", value: "WireGuard")
                    DetailRow(label: "Port", value: "51820")
                    DetailRow(label: "DNS", value: server.dnsServers.joined(separator: ", "))
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )

                // Features
                VStack(alignment: .leading, spacing: 12) {
                    Text("Features")
                        .font(.headline)

                    FeatureRow(icon: "lock.shield", title: "Military-grade encryption")
                    FeatureRow(icon: "bolt.fill", title: "High-speed connection")
                    FeatureRow(icon: "eye.slash", title: "No-logs policy")
                    FeatureRow(icon: "arrow.triangle.2.circlepath", title: "Unlimited bandwidth")
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )

                // Connect button
                Button {
                    // Connect to this server
                } label: {
                    Text("Connect to \(server.city)")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [.blue, .blue.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal)
            }
            .padding(.bottom, 20)
        }
        .navigationTitle("Server Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
    }
}

struct ConnectionQualityCard: View {
    let latency: Int
    let load: Int

    private var quality: ConnectionQuality {
        if latency < 100 && load < 50 { return .excellent }
        if latency < 200 && load < 70 { return .good }
        if latency < 300 { return .fair }
        return .poor
    }

    private enum ConnectionQuality {
        case excellent, good, fair, poor

        var color: Color {
            switch self {
            case .excellent: return .green
            case .good: return .blue
            case .fair: return .orange
            case .poor: return .red
            }
        }

        var title: String {
            switch self {
            case .excellent: return "Excellent"
            case .good: return "Good"
            case .fair: return "Fair"
            case .poor: return "Poor"
            }
        }
    }

    var body: some View {
        HStack(spacing: 20) {
            VStack(spacing: 8) {
                Image(systemName: "speedometer")
                    .font(.title2)
                    .foregroundColor(quality.color)

                Text("\(latency)ms")
                    .font(.headline)
                Text("Latency")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Divider()

            VStack(spacing: 8) {
                Image(systemName: "cpu")
                    .font(.title2)
                    .foregroundColor(load > 70 ? .orange : .green)

                Text("\(load)%")
                    .font(.headline)
                Text("Load")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(spacing: 4) {
                Text(quality.title)
                    .font(.headline)
                    .foregroundColor(quality.color)
                Text("Connection Quality")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(quality.color.opacity(0.1))
        )
    }
}

struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)

            Spacer()

            Text(value)
                .fontWeight(.medium)
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)

            Text(title)
                .font(.subheadline)

            Spacer()
        }
    }
}

#Preview {
    NavigationStack {
        ServerDetailView(server: .mock)
    }
}

