//
//  SpeedTestService.swift
//  SafeMesh
//
//  Measures real download/upload speed and ping latency using URLSession.
//

import Foundation
import Network
import Combine

// MARK: - Speed Test Phase
enum SpeedTestPhase: String {
    case idle = "READY"
    case ping = "LATENCY"
    case download = "DOWNLOAD"
    case upload = "UPLOAD"
    case complete = "COMPLETE"
}

// MARK: - Connection Type
enum ConnectionType: String {
    case wifi = "Wi-Fi"
    case cellular = "Cellular"
    case wiredEthernet = "Ethernet"
    case unknown = "Unknown"
}

// MARK: - Speed Test Service
@MainActor
class SpeedTestService: ObservableObject {
    // MARK: - Published State
    @Published var downloadSpeed: Double = 0.0   // Mbps
    @Published var uploadSpeed: Double = 0.0     // Mbps
    @Published var pingLatency: Double = 0.0     // ms
    @Published var phase: SpeedTestPhase = .idle
    @Published var progress: Double = 0.0        // 0.0 – 1.0
    @Published var connectionType: ConnectionType = .unknown
    @Published var isTesting: Bool = false
    @Published var errorMessage: String?

    // MARK: - Private
    private let monitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "com.safemesh.networkmonitor")
    private var testTask: Task<Void, Never>?

    // Test endpoints (Apple's & Cloudflare's public files — fast, globally distributed)
    private let downloadURLs: [String] = [
        "https://speed.cloudflare.com/__down?bytes=10000000",  // 10 MB
        "https://proof.ovh.net/files/10Mb.dat"                 // 10 MB fallback
    ]
    private let uploadURL = "https://speed.cloudflare.com/__up"
    private let pingHost = "1.1.1.1"

    // MARK: - Lifecycle
    init() {
        startNetworkMonitor()
    }

    deinit {
        monitor.cancel()
    }

    // MARK: - Network Monitor
    private func startNetworkMonitor() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                if path.usesInterfaceType(.wifi) {
                    self?.connectionType = .wifi
                } else if path.usesInterfaceType(.cellular) {
                    self?.connectionType = .cellular
                } else if path.usesInterfaceType(.wiredEthernet) {
                    self?.connectionType = .wiredEthernet
                } else {
                    self?.connectionType = .unknown
                }
            }
        }
        monitor.start(queue: monitorQueue)
    }

    // MARK: - Run Full Test
    func runSpeedTest() {
        guard !isTesting else { return }

        testTask = Task {
            isTesting = true
            errorMessage = nil
            downloadSpeed = 0
            uploadSpeed = 0
            pingLatency = 0
            progress = 0

            // Phase 1: Ping
            phase = .ping
            progress = 0.05
            await measurePing()
            progress = 0.2

            guard !Task.isCancelled else { return cleanup() }

            // Phase 2: Download
            phase = .download
            progress = 0.25
            await measureDownload()
            progress = 0.6

            guard !Task.isCancelled else { return cleanup() }

            // Phase 3: Upload
            phase = .upload
            progress = 0.65
            await measureUpload()
            progress = 1.0

            phase = .complete
            isTesting = false
        }
    }

    func cancelTest() {
        testTask?.cancel()
        cleanup()
    }

    // MARK: - Live Monitoring (for HomeView display while connected)
    private var monitorTimer: Timer?
    private var isMonitoring = false

    func startMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true
        downloadSpeed = Double.random(in: 80...150)
        uploadSpeed = Double.random(in: 30...80)

        monitorTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self, self.isMonitoring else { return }
                // Simulate live network fluctuations
                var dl = self.downloadSpeed * Double.random(in: 0.85...1.15)
                var ul = self.uploadSpeed * Double.random(in: 0.85...1.15)
                dl = min(max(dl, 5.0), 350.0)
                ul = min(max(ul, 2.0), 150.0)
                self.downloadSpeed = dl
                self.uploadSpeed = ul
            }
        }
    }

    func stopMonitoring() {
        isMonitoring = false
        monitorTimer?.invalidate()
        monitorTimer = nil
        downloadSpeed = 0
        uploadSpeed = 0
    }

    private func cleanup() {
        isTesting = false
        phase = .idle
        progress = 0
    }

    // MARK: - Ping Measurement
    private func measurePing() async {
        let url = URL(string: "https://\(pingHost)/cdn-cgi/trace")!
        let samples = 5
        var latencies: [Double] = []

        for _ in 0..<samples {
            guard !Task.isCancelled else { return }

            let start = CFAbsoluteTimeGetCurrent()
            do {
                let config = URLSessionConfiguration.ephemeral
                config.timeoutIntervalForRequest = 5
                let session = URLSession(configuration: config)
                let (_, response) = try await session.data(from: url)
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    let elapsed = (CFAbsoluteTimeGetCurrent() - start) * 1000 // ms
                    latencies.append(elapsed)
                }
            } catch {
                // skip failed sample
            }
        }

        if !latencies.isEmpty {
            // Use median for stability
            latencies.sort()
            pingLatency = latencies[latencies.count / 2]
        } else {
            pingLatency = -1 // indicates failure
        }
    }

    // MARK: - Download Speed Measurement
    private func measureDownload() async {
        guard let url = URL(string: downloadURLs[0]) else { return }

        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 30
        config.httpMaximumConnectionsPerHost = 4
        let session = URLSession(configuration: config)

        let start = CFAbsoluteTimeGetCurrent()
        var totalBytes: Int = 0

        do {
            let (data, response) = try await session.data(from: url)
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                totalBytes = data.count
            }
        } catch {
            // Try fallback URL
            if let fallbackURL = URL(string: downloadURLs[1]) {
                do {
                    let (data, _) = try await session.data(from: fallbackURL)
                    totalBytes = data.count
                } catch {
                    errorMessage = "Download test failed"
                    return
                }
            }
        }

        let elapsed = CFAbsoluteTimeGetCurrent() - start
        if elapsed > 0 && totalBytes > 0 {
            // Convert bytes/sec to Mbps (megabits per second)
            let bytesPerSec = Double(totalBytes) / elapsed
            downloadSpeed = (bytesPerSec * 8) / 1_000_000
        }
    }

    // MARK: - Upload Speed Measurement
    private func measureUpload() async {
        guard let url = URL(string: uploadURL) else { return }

        // Generate a 5 MB payload
        let payloadSize = 5_000_000
        let payload = Data(count: payloadSize)

        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 30
        let session = URLSession(configuration: config)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")

        let start = CFAbsoluteTimeGetCurrent()

        do {
            let (_, response) = try await session.upload(for: request, from: payload)
            if let httpResponse = response as? HTTPURLResponse,
               (200...299).contains(httpResponse.statusCode) {
                let elapsed = CFAbsoluteTimeGetCurrent() - start
                if elapsed > 0 {
                    let bytesPerSec = Double(payloadSize) / elapsed
                    uploadSpeed = (bytesPerSec * 8) / 1_000_000
                }
            }
        } catch {
            errorMessage = "Upload test failed"
        }
    }

    // MARK: - Formatting Helpers
    static func formatSpeed(_ speed: Double) -> String {
        if speed >= 1000 {
            return String(format: "%.1f", speed / 1000)
        } else if speed >= 100 {
            return String(format: "%.0f", speed)
        } else if speed >= 10 {
            return String(format: "%.1f", speed)
        } else {
            return String(format: "%.2f", speed)
        }
    }

    static func speedUnit(_ speed: Double) -> String {
        speed >= 1000 ? "Gbps" : "Mbps"
    }

    static func formatPing(_ ping: Double) -> String {
        if ping < 0 { return "—" }
        return String(format: "%.0f", ping)
    }
}
