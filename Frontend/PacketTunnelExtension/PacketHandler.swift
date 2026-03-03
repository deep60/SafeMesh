//
//  PacketHandler.swift
//  SafeMesh
//
//  Created by P Deepanshu on 23/02/26.
//

import Foundation
import NetworkExtension

class PacketHandler {
    // MARK: - Properties
    private let packetFlow: NEPacketTunnelFlow
    private var tunnel: WireGuardTunnel?
    private var isRunning = false

    private var readQueue = DispatchQueue(label: "com.safemesh.read")
    private var writeQueue = DispatchQueue(label: "com.safemesh.write")
    private var logger = ExtensionLogger.shared

    // MARK: - Statistics
    private var packetsProcessed: UInt64 = 0
    private var bytesProcessed: UInt64 = 0

    // MARK: - Constants
    private let maxPacketSize = 1500
    private let readBufferSize = 64 * 1024 // 64 KB buffer

    // MARK: - Initialization
    init(packetFlow: NEPacketTunnelFlow) {
        self.packetFlow = packetFlow
    }

    // MARK: - Lifecycle
    func start(tunnel: WireGuardTunnel) {
        guard !isRunning else { return }

        self.tunnel = tunnel
        isRunning = true

        logger.log("Packet handler started", level: .info)

        // Start reading packets
        startReading()
    }

    func stop() {
        guard isRunning else { return }

        isRunning = false

        logger.log("Packet handler stopped. Packets: \(packetsProcessed), Bytes:\(bytesProcessed)", level: .info)
    }

    // MARK: - Packet Reading
    private func startReading() {
        Task { [weak self] in
            await self?.readPackets()
        }
    }

    private func readPackets() async {
        while isRunning {
            let (packets, protocols) = await packetFlow.readPackets()

            for (packet, protocolFamily) in zip(packets, protocols) {
                processPacket(packet, protocolFamily: protocolFamily.uint32Value)
            }
        }
    }

    // MARK: - Packet Processing
    private func processPacket(_ data: Data, protocolFamily: UInt32) {
        guard let tunnel = tunnel else { return }

        // Check packet size
        guard data.count <= maxPacketSize else {
            logger.log("Packet too large: \(data.count) bytes", level: .warning)
            return
        }

        // Process through WireGuard tunnel
        do {
            let encryptedData = try tunnel.encrypt(data)
            sendToTunnel(encryptedData)

            packetsProcessed += 1
            bytesProcessed += UInt64(data.count)

        } catch {
            logger.log("Encryption failed: \(error)", level: .error)
        }
    }

    // MARK: - Packet Writing
    private func sendToTunnel(_ data: Data) {
        writeQueue.async { [weak self] in
            guard let self = self, let tunnel = self.tunnel else { return }

            do {
                try tunnel.send(data)
            } catch {
                self.logger.log("Failed to send to tunnel: \(error)", level: .error)
            }
        }
    }

    func writePacket(_ data: Data, protocolFamily: sa_family_t) {
        guard isRunning else { return }

        writeQueue.async { [weak self] in
            guard let self = self, let tunnel = self.tunnel else { return }

            do {
                // Decrypt from tunnel
                let decryptedData = try tunnel.decrypt(data)

                // Write to packet flow
                self.packetFlow.writePackets([decryptedData], withProtocols: [NSNumber(value: protocolFamily)])

            } catch {
                self.logger.log("Decryption failed: \(error)", level: .error)
            }
        }
    }

    // MARK: - Statistics
    func getStatistics() -> PacketStatistics {
        return PacketStatistics(
            packetsProcessed: packetsProcessed,
            bytesProcessed: bytesProcessed
        )
    }

    func resetStatistics() {
        packetsProcessed = 0
        bytesProcessed = 0
    }
}

// MARK: - Supporting Types
struct PacketStatistics {
    let packetsProcessed: UInt64
    let bytesProcessed: UInt64

    var formattedBytes: String {
        ByteCountFormatter().string(fromByteCount: Int64(bytesProcessed))
    }
}

// //MARK: - Packet Flow Helper
//extension PacketFlow {
//    func readPacketObjects() throws -> [NEPacket] {
//        var packets: [NEPacket] = []
//
//        // Read packets in a loop until there are no more
//        while true {
//            let packetsArray = self.readPackets()
//
//            if packetsArray.isEmpty {
//                break
//            }
//
//            packets.append(contentsOf: packetsArray)
//        }
//
//        return packets
//    }
//}

// MARK: - Packet Analyzer
class PacketAnalyzer {
    static func analyze(_ packet: NEPacket) -> PacketInfo {
        let data = packet.data
        guard data.count > 0 else {
            return PacketInfo(type: .unknown, size: 0)
        }

        // Get protocol from first byte (IPv4/IPv6)
        let version = (data[0] & 0xF0) >> 4

        switch version {
        case 4:
            return analyzeIPv4(data)
        case 6:
            return analyzeIPv6(data)
        default:
            return PacketInfo(type: .unknown, size: data.count)
        }
    }

    private static func analyzeIPv4(_ data: Data) -> PacketInfo {
        guard data.count >= 20 else {
            return PacketInfo(type: .ipv4, size: data.count)
        }

        let protocolValue = data[9]

        var packetType: PacketInfo.PacketType = .ipv4

        switch protocolValue {
        case 1:
            packetType = .icmp
        case 6:
            packetType = .tcp
        case 17:
            packetType = .udp
        default:
            packetType = .ipv4
        }

        // Extract source and destination
        let sourceIP = "\(data[12]).\(data[13]).\(data[14]).\(data[15])"
        let destIP = "\(data[16]).\(data[17]).\(data[18]).\(data[19])"

        return PacketInfo(type: packetType, size: data.count, source: sourceIP,
destination: destIP)
    }

    private static func analyzeIPv6(_ data: Data) -> PacketInfo {
        guard data.count >= 40 else {
            return PacketInfo(type: .ipv6, size: data.count)
        }

        let nextHeader = data[6]

        var packetType: PacketInfo.PacketType = .ipv6

        switch nextHeader {
        case 58:
            packetType = .icmp6
        case 6:
            packetType = .tcp
        case 17:
            packetType = .udp
        default:
            packetType = .ipv6
        }

        return PacketInfo(type: packetType, size: data.count)
    }
}

struct PacketInfo {
    enum PacketType {
        case unknown, ipv4, ipv6, tcp, udp, icmp, icmp6
    }

    let type: PacketType
    let size: Int
    var source: String?
    var destination: String?
}

