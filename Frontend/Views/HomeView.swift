//
//  HomeView.swift
//  SafeMesh
//
//  Created by P Deepanshu on 23/02/26.
//

import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = VPNViewModel()
    @StateObject private var speedTest = SpeedTestService()
    @State private var showServerSelector = false
    @State private var pulseAnimation = false

    var body: some View {
        ZStack {
            // Navy gradient background
            LinearGradient(
                colors: [
                    Color(red: 0.10, green: 0.14, blue: 0.28),
                    Theme.Colors.primaryBackground
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Subtle world map pattern overlay
            WorldMapOverlay()
                .opacity(viewModel.status.isConnected ? 0.12 : 0.06)

            VStack(spacing: 0) {
                // Top Bar — Menu icon + Premium badge
                HStack {
                    // Menu dots
                    Button(action: {}) {
                        VStack(spacing: 4) {
                            HStack(spacing: 4) {
                                Circle().frame(width: 6, height: 6)
                                Circle().frame(width: 6, height: 6)
                            }
                            HStack(spacing: 4) {
                                Circle().frame(width: 6, height: 6)
                                Circle().frame(width: 6, height: 6)
                            }
                        }
                        .foregroundColor(.white.opacity(0.7))
                    }

                    Spacer()

                    // Premium badge
                    HStack(spacing: 6) {
                        Image(systemName: "crown.fill")
                            .font(.caption)
                            .foregroundColor(Theme.Colors.neonOrange)
                        Text("Premium")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Theme.Colors.secondaryBackground.opacity(0.8))
                            .overlay(
                                Capsule()
                                    .strokeBorder(Theme.Colors.neonOrange.opacity(0.3), lineWidth: 1)
                            )
                    )
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)

                Spacer()

                // Connection Time
                VStack(spacing: 8) {
                    Text(viewModel.status.isConnected ? "Connecting Time" : "Disconnected")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.white.opacity(0.6))

                    Text(viewModel.connectedDuration)
                        .font(.system(size: 52, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                        .tracking(2)
                        .contentTransition(.numericText())
                }

                Spacer().frame(height: 32)

                // Power Button
                Button(action: {
                    viewModel.toggleConnection()
                    toggleSpeedMonitoring()
                }) {
                    ZStack {
                        // Outer ring
                        Circle()
                            .stroke(
                                viewModel.status.isConnected
                                    ? Theme.Colors.neonCyan.opacity(0.4)
                                    : Color.white.opacity(0.25),
                                lineWidth: 3
                            )
                            .frame(width: 120, height: 120)

                        // Pulse ring when connected
                        if viewModel.status.isConnected {
                            Circle()
                                .stroke(Theme.Colors.neonCyan.opacity(0.15), lineWidth: 2)
                                .frame(width: 140, height: 140)
                                .scaleEffect(pulseAnimation ? 1.2 : 1.0)
                                .opacity(pulseAnimation ? 0 : 0.6)
                                .animation(.easeOut(duration: 1.8).repeatForever(autoreverses: false), value: pulseAnimation)
                        }

                        // Inner glow
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        (viewModel.status.isConnected ? Theme.Colors.neonCyan : Color.white).opacity(0.06),
                                        .clear
                                    ],
                                    center: .center,
                                    startRadius: 10,
                                    endRadius: 60
                                )
                            )
                            .frame(width: 120, height: 120)

                        // Power icon
                        Image(systemName: "power")
                            .font(.system(size: 38, weight: .regular))
                            .foregroundColor(
                                viewModel.status.isConnected ? Theme.Colors.neonCyan : .white.opacity(0.8)
                            )

                        // Loading spinner
                        if viewModel.isConnecting || viewModel.isDisconnecting {
                            Circle()
                                .trim(from: 0, to: 0.3)
                                .stroke(Theme.Colors.neonCyan, lineWidth: 3)
                                .frame(width: 120, height: 120)
                                .rotationEffect(.degrees(pulseAnimation ? 360 : 0))
                                .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: pulseAnimation)
                        }
                    }
                }
                .buttonStyle(.plain)

                Spacer().frame(height: 32)

                // Server Card
                Button(action: { showServerSelector = true }) {
                    HStack(spacing: 14) {
                        // Country flag placeholder
                        if let server = viewModel.currentServer {
                            Text(countryFlag(for: server.countryCode))
                                .font(.system(size: 28))
                        } else {
                            Image(systemName: "globe")
                                .font(.title2)
                                .foregroundColor(.white.opacity(0.5))
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(viewModel.currentServer?.country ?? "Select Server")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                            Text(viewModel.currentServer?.ipAddress ?? "Tap to choose")
                                .font(.system(size: 12, weight: .regular, design: .monospaced))
                                .foregroundColor(.white.opacity(0.5))
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.callout.weight(.semibold))
                            .foregroundColor(.white.opacity(0.3))
                            .padding(10)
                            .background(Circle().fill(Color.white.opacity(0.08)))
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.Radius.lg)
                            .fill(Theme.Colors.secondaryBackground.opacity(0.7))
                            .overlay(
                                RoundedRectangle(cornerRadius: Theme.Radius.lg)
                                    .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 24)

                Spacer().frame(height: 28)

                // Download / Upload Speed Bar
                HStack(spacing: 0) {
                    // Download
                    HStack(spacing: 10) {
                        Image(systemName: "arrow.down")
                            .font(.caption.weight(.bold))
                            .foregroundColor(Theme.Colors.neonCyan)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Download")
                                .font(.system(size: 11, weight: .regular))
                                .foregroundColor(.white.opacity(0.5))
                            HStack(alignment: .firstTextBaseline, spacing: 2) {
                                Text(SpeedTestService.formatSpeed(speedTest.downloadSpeed))
                                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                                    .foregroundColor(.white)
                                    .contentTransition(.numericText())
                                Text("Mbp")
                                    .font(.system(size: 11, weight: .regular))
                                    .foregroundColor(.white)
                                + Text("/s")
                                    .font(.system(size: 11, weight: .regular))
                                    .foregroundColor(Theme.Colors.neonCyan)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)

                    // Divider
                    Rectangle()
                        .fill(Color.white.opacity(0.12))
                        .frame(width: 1, height: 40)

                    // Upload
                    HStack(spacing: 10) {
                        Image(systemName: "arrow.up")
                            .font(.caption.weight(.bold))
                            .foregroundColor(Theme.Colors.neonLime)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Upload")
                                .font(.system(size: 11, weight: .regular))
                                .foregroundColor(.white.opacity(0.5))
                            HStack(alignment: .firstTextBaseline, spacing: 2) {
                                Text(SpeedTestService.formatSpeed(speedTest.uploadSpeed))
                                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                                    .foregroundColor(.white)
                                    .contentTransition(.numericText())
                                Text("Mbp")
                                    .font(.system(size: 11, weight: .regular))
                                    .foregroundColor(.white)
                                + Text("/s")
                                    .font(.system(size: 11, weight: .regular))
                                    .foregroundColor(Theme.Colors.neonLime)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 24)

                Spacer()

                // Bottom globe / earth visual
                EarthVisual()
                    .frame(height: 180)
                    .clipped()
            }
        }
        .sheet(isPresented: $showServerSelector) {
            ServerListView()
                .preferredColorScheme(.dark)
        }
        .task {
            await viewModel.loadCurrentServer()
            pulseAnimation = true
        }
        .onChange(of: viewModel.status) { _, _ in
            toggleSpeedMonitoring()
        }
    }

    // MARK: - Helpers
    private func toggleSpeedMonitoring() {
        let service = speedTest
        if viewModel.status.isConnected {
            service.startMonitoring()
        } else {
            service.stopMonitoring()
        }
    }

    // Convert country code to emoji flag
    private func countryFlag(for code: String) -> String {
        let base: UInt32 = 127397
        var flag = ""
        for scalar in code.uppercased().unicodeScalars {
            flag.append(String(UnicodeScalar(base + scalar.value)!))
        }
        return flag
    }
}

// MARK: - World Map Overlay
struct WorldMapOverlay: View {
    var body: some View {
        GeometryReader { geo in
            // Create a subtle dotted world map pattern
            Canvas { context, size in
                let cols = 40
                let rows = 20
                let stepX = size.width / CGFloat(cols)
                let stepY = size.height / CGFloat(rows)

                for col in 0..<cols {
                    for row in 0..<rows {
                        // Very rough world map approximation — just a pattern texture
                        let x = CGFloat(col) * stepX + stepX / 2
                        let y = CGFloat(row) * stepY + stepY / 2

                        // Create denser dots in areas that resemble continent positions
                        let normalizedX = Double(col) / Double(cols)
                        let normalizedY = Double(row) / Double(rows)

                        let isLand = worldMapPoint(normalizedX, normalizedY)
                        if isLand {
                            let rect = CGRect(x: x - 1.5, y: y - 1.5, width: 3, height: 3)
                            context.fill(
                                Path(ellipseIn: rect),
                                with: .color(.white.opacity(0.3))
                            )
                        }
                    }
                }
            }
        }
    }

    // Very rough approximation of world map (for visual effect only)
    private func worldMapPoint(_ x: Double, _ y: Double) -> Bool {
        // North America
        if x > 0.08 && x < 0.30 && y > 0.15 && y < 0.45 { return Double.random(in: 0...1) > 0.5 }
        // South America
        if x > 0.18 && x < 0.35 && y > 0.50 && y < 0.85 { return Double.random(in: 0...1) > 0.6 }
        // Europe
        if x > 0.40 && x < 0.55 && y > 0.15 && y < 0.40 { return Double.random(in: 0...1) > 0.5 }
        // Africa
        if x > 0.40 && x < 0.58 && y > 0.35 && y < 0.75 { return Double.random(in: 0...1) > 0.5 }
        // Asia
        if x > 0.55 && x < 0.85 && y > 0.10 && y < 0.50 { return Double.random(in: 0...1) > 0.4 }
        // Australia
        if x > 0.75 && x < 0.90 && y > 0.60 && y < 0.80 { return Double.random(in: 0...1) > 0.6 }
        return false
    }
}

// MARK: - Earth Visual (Bottom Illustration)
struct EarthVisual: View {
    var body: some View {
        ZStack {
            // Atmosphere glow
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 0.1, green: 0.5, blue: 0.9).opacity(0.3),
                            Color(red: 0.05, green: 0.2, blue: 0.6).opacity(0.15),
                            .clear
                        ],
                        center: .center,
                        startRadius: 40,
                        endRadius: 200
                    )
                )
                .frame(width: 400, height: 400)
                .offset(y: 140)

            // Earth body
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.1, green: 0.4, blue: 0.8),
                            Color(red: 0.05, green: 0.15, blue: 0.5),
                            Color(red: 0.02, green: 0.08, blue: 0.3)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 360, height: 360)
                .offset(y: 170)
                .overlay(
                    // Cloud/land patterns
                    Ellipse()
                        .fill(
                            AngularGradient(
                                colors: [
                                    .white.opacity(0.08),
                                    Color(red: 0.2, green: 0.6, blue: 0.3).opacity(0.12),
                                    .white.opacity(0.05),
                                    Color(red: 0.15, green: 0.5, blue: 0.25).opacity(0.10),
                                    .white.opacity(0.08)
                                ],
                                center: .center
                            )
                        )
                        .frame(width: 340, height: 340)
                        .offset(y: 170)
                )

            // Horizon glow line
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.clear, Theme.Colors.neonCyan.opacity(0.2), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 2)
                .offset(y: 0)
        }
    }
}

#Preview {
    HomeView()
}
