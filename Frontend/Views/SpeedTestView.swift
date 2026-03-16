//
//  SpeedTestView.swift
//  SafeMesh
//
//  Animated speed test gauge UI — shows download, upload, and ping.
//

import SwiftUI

struct SpeedTestView: View {
    @StateObject private var speedTest = SpeedTestService()
    @State private var animatedDownload: Double = 0
    @State private var animatedUpload: Double = 0
    @State private var animatedPing: Double = 0

    var body: some View {
        ZStack {
            Theme.Colors.primaryBackground
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("SPEED TEST")
                                .techFont(.title2)
                                .foregroundColor(.white)
                                .tracking(3)
                            Text(speedTest.connectionType.rawValue.uppercased())
                                .techFont(.caption)
                                .foregroundColor(Theme.Colors.neonCyan)
                                .tracking(2)
                        }
                        Spacer()
                        // Connection type icon
                        Image(systemName: connectionIcon)
                            .font(.title2)
                            .foregroundColor(Theme.Colors.neonCyan)
                            .neonGlow(color: Theme.Colors.neonCyan, radius: .sm)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)

                    // Main Gauge
                    ZStack {
                        // Background ring
                        Circle()
                            .stroke(Theme.Colors.secondaryBackground, lineWidth: 20)
                            .frame(width: 240, height: 240)
                        
                        
                        // Progress arc
                        Circle()
                            .trim(from: 0, to: speedTest.progress)
                            .stroke(
                                AngularGradient(
                                    colors: [Theme.Colors.neonCyan, Theme.Colors.neonBlue, Theme.Colors.neonMagenta],
                                    center: .center
                                ),
                                style: StrokeStyle(lineWidth: 12, lineCap: .round)
                            )
                            .frame(width: 220, height: 220)
                            .rotationEffect(.degrees(-90))
                            .animation(.easeInOut(duration: 0.5), value: speedTest.progress)

                        // Inner glow
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [phaseColor.opacity(0.08), .clear],
                                    center: .center,
                                    startRadius: 30,
                                    endRadius: 110
                                )
                            )
                            .frame(width: 220, height: 220)

                        // Center content
                        VStack(spacing: 6) {
                            Text(speedTest.phase.rawValue)
                                .techFont(.caption)
                                .foregroundColor(phaseColor)
                                .tracking(3)

                            Text(centerValue)
                                .font(.system(size: 44, weight: .bold, design: .monospaced))
                                .foregroundColor(.white)
                                .contentTransition(.numericText())

                            Text(centerUnit)
                                .techFont(.caption)
                                .foregroundColor(Theme.Colors.secondaryText)
                        }
                    }
                    .padding(.vertical, 8)

                    // Start / Stop Button
                    Button(action: {
                        if speedTest.isTesting {
                            speedTest.cancelTest()
                        } else {
                            speedTest.runSpeedTest()
                        }
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: speedTest.isTesting ? "stop.fill" : "bolt.fill")
                                .font(.headline)
                            Text(speedTest.isTesting ? "STOP TEST" : "START TEST")
                                .techFont(.headline)
                                .tracking(2)
                        }
                        .foregroundColor(Theme.Colors.primaryBackground)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            Theme.buttonGradient(color: speedTest.isTesting ? Theme.Colors.neonMagenta : Theme.Colors.neonCyan)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.lg))
                        .neonGlow(color: speedTest.isTesting ? Theme.Colors.neonMagenta : Theme.Colors.neonCyan, radius: .sm)
                    }
                    .padding(.horizontal, 40)

                    // Error message
                    if let error = speedTest.errorMessage {
                        Text(error)
                            .techFont(.caption)
                            .foregroundColor(Theme.Colors.neonMagenta)
                            .padding(.horizontal, 24)
                    }

                    // Results Cards
                    HStack(spacing: 16) {
                        SpeedResultCard(
                            icon: "arrow.down",
                            title: "DOWNLOAD",
                            value: SpeedTestService.formatSpeed(animatedDownload),
                            unit: SpeedTestService.speedUnit(animatedDownload),
                            color: Theme.Colors.neonCyan
                        )

                        SpeedResultCard(
                            icon: "arrow.up",
                            title: "UPLOAD",
                            value: SpeedTestService.formatSpeed(animatedUpload),
                            unit: SpeedTestService.speedUnit(animatedUpload),
                            color: Theme.Colors.neonLime
                        )
                    }
                    .padding(.horizontal, 24)

                    // Ping Card
                    HStack(spacing: 16) {
                        SpeedResultCard(
                            icon: "antenna.radiowaves.left.and.right",
                            title: "PING",
                            value: SpeedTestService.formatPing(animatedPing),
                            unit: "ms",
                            color: Theme.Colors.neonOrange
                        )

                        SpeedResultCard(
                            icon: "network",
                            title: "TYPE",
                            value: speedTest.connectionType.rawValue,
                            unit: "",
                            color: Theme.Colors.neonBlue
                        )
                    }
                    .padding(.horizontal, 24)

                    Spacer(minLength: 40)
                }
            }
        }
        .onChange(of: speedTest.downloadSpeed) { _, newValue in
            withAnimation(.easeOut(duration: 0.4)) {
                animatedDownload = newValue
            }
        }
        .onChange(of: speedTest.uploadSpeed) { _, newValue in
            withAnimation(.easeOut(duration: 0.4)) {
                animatedUpload = newValue
            }
        }
        .onChange(of: speedTest.pingLatency) { _, newValue in
            withAnimation(.easeOut(duration: 0.4)) {
                animatedPing = newValue
            }
        }
    }

    // MARK: - Computed Properties
    private var connectionIcon: String {
        switch speedTest.connectionType {
        case .wifi: return "wifi"
        case .cellular: return "antenna.radiowaves.left.and.right"
        case .wiredEthernet: return "cable.connector"
        default: return "questionmark.circle"
        }
    }

    private var phaseColor: Color {
        switch speedTest.phase {
        case .idle: return Theme.Colors.secondaryText
        case .ping: return Theme.Colors.neonOrange
        case .download: return Theme.Colors.neonCyan
        case .upload: return Theme.Colors.neonLime
        case .complete: return Theme.Colors.neonCyan
        }
    }

    private var centerValue: String {
        switch speedTest.phase {
        case .idle: return "—"
        case .ping: return SpeedTestService.formatPing(speedTest.pingLatency)
        case .download: return SpeedTestService.formatSpeed(speedTest.downloadSpeed)
        case .upload: return SpeedTestService.formatSpeed(speedTest.uploadSpeed)
        case .complete: return SpeedTestService.formatSpeed(speedTest.downloadSpeed)
        }
    }

    private var centerUnit: String {
        switch speedTest.phase {
        case .idle: return "TAP TO START"
        case .ping: return "ms"
        case .download: return "Mbps ↓"
        case .upload: return "Mbps ↑"
        case .complete: return "Mbps ↓"
        }
    }
}

// MARK: - Speed Result Card
struct SpeedResultCard: View {
    let icon: String
    let title: String
    let value: String
    let unit: String
    let color: Color

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title3.weight(.light))
                .foregroundColor(color)
                .neonGlow(color: color, radius: .sm)

            Text(title)
                .techFont(.caption2)
                .foregroundColor(Theme.Colors.secondaryText)
                .tracking(2)

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 22, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                    .contentTransition(.numericText())

                if !unit.isEmpty {
                    Text(unit)
                        .techFont(.caption2)
                        .foregroundColor(color.opacity(0.8))
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .padding(.horizontal, 12)
        .themedCard(
            borderColor: color.opacity(0.25),
            borderWidth: 1,
            glowColor: color.opacity(0.08),
            glowRadius: 8
        )
    }
}

#Preview {
    SpeedTestView()
        .preferredColorScheme(.dark)
}
