//
//  WireGaurdTunnel.swift
//  SafeMesh
//
//  Created by P Deepanshu on 23/02/26.
//

import Foundation
import Network
import CryptoKit
import os.log

class WireGuardTunnel {
    // MARK: - Properties
    private let config: TunnelConfiguration
    private let logger = ExtensionLogger.shared

    private var outboundQueue: DispatchQueue
    private var inboundQueue: DispatchQueue

    private var keyPair: KeyPair
    private var peerKey: P256.KeyAgreement.PublicKey
    private var sessionState: SessionState?

    private var outboundPackets: [(Data, CompletionHandler)] = []
    private var inboundPackets: [Data] = []

    private var isRunning = false
    private var connection: NWConnection?

    // MARK: - Types
    private struct KeyPair {
        let privateKey: P256.KeyAgreement.PrivateKey
        let publicKey: P256.KeyAgreement.PublicKey

        static func generate() -> KeyPair {
            let privateKey = P256.KeyAgreement.PrivateKey()
            return KeyPair(privateKey: privateKey, publicKey: privateKey.publicKey)
        }
    }

    private struct SessionState {
        var handshakeCompleted: Bool = false
        var lastHandshake: Date
        var ephemeralKey: P256.KeyAgreement.PrivateKey?
        var sharedSecret: SymmetricKey?
        var receivingKey: SymmetricKey?
        var sendingKey: SymmetricKey?
        var replayCounter: UInt64 = 0
    }

    typealias CompletionHandler = (Result<Void, Error>) -> Void

    // MARK: - Initialization
    init(configuration: TunnelConfiguration) {
        self.config = configuration

        self.outboundQueue = DispatchQueue(label: "com.safemesh.outbound", qos: .userInitiated)
        self.inboundQueue = DispatchQueue(label: "com.safemesh.inbound", qos: .userInitiated)

        // Initialize key pair from config
        guard let privateKeyData = Data(base64Encoded: config.privateKey),
              let privateKey = try? P256.KeyAgreement.PrivateKey(rawRepresentation: privateKeyData) else {
            fatalError("Invalid private key")
        }

        self.keyPair = KeyPair(privateKey: privateKey, publicKey: privateKey.publicKey)

        // Parse peer public key
        guard let peerKeyData = Data(base64Encoded: config.serverPublicKey),
              let peerKey = try? P256.KeyAgreement.PublicKey(rawRepresentation: peerKeyData) else {
            fatalError("Invalid peer public key")
        }

        self.peerKey = peerKey
    }

    // MARK: - Lifecycle
    func start() throws {
        guard !isRunning else { return }

        logger.log("Starting WireGuard tunnel to \(config.serverAddress):\(config.serverPort)", level: .info)

        // Establish connection to server
        try establishConnection()

        // Perform handshake
        try performHandshake()

        isRunning = true

        // Start packet processing
        startPacketProcessing()

        logger.log("WireGuard tunnel started", level: .info)
    }

    func stop() {
        guard isRunning else { return }

        isRunning = false

        // Close connection
        connection?.cancel()
        connection = nil

        // Clear queues
        outboundQueue.sync {
            outboundPackets.removeAll()
        }

        inboundQueue.sync {
            inboundPackets.removeAll()
        }

        // Clear session state
        sessionState = nil

        logger.log("WireGuard tunnel stopped", level: .info)
    }

    // MARK: - Connection
    private func establishConnection() throws {
        let host = NWEndpoint.Host(config.serverAddress)
        let port = NWEndpoint.Port(rawValue: UInt16(config.serverPort))!

        connection = NWConnection(
            host: host,
            port: port,
            using: .udp
        )

        connection?.stateUpdateHandler = { [weak self] state in
            self?.handleConnectionState(state)
        }

        connection?.start(queue: .global(qos: .userInitiated))
    }

    private func handleConnectionState(_ state: NWConnection.State) {
        switch state {
        case .ready:
            logger.log("Connection established", level: .info)
        case .failed(let error):
            logger.log("Connection failed: \(error)", level: .error)
        case .waiting(let error):
            logger.log("Connection waiting: \(error)", level: .warning)
        default:
            break
        }
    }

    // MARK: - Handshake
    private func performHandshake() throws {
        logger.log("Performing WireGuard handshake", level: .info)

        // Generate ephemeral key for this session
        let ephemeralKey = P256.KeyAgreement.PrivateKey()

        // Perform Diffie-Hellman key exchange
        let sharedSecret = try ephemeralKey.sharedSecretFromKeyAgreement(with: peerKey)

        // Derive encryption keys
        let masterKey = SymmetricKey(data: sharedSecret.withUnsafeBytes { Data(bytes: $0.baseAddress!, count: $0.count) })

        // HKDF to derive keys
        let info1 = "wireguard-sending-key".data(using: .utf8)!
        let info2 = "wireguard-receiving-key".data(using: .utf8)!
        
        let sendingKeyData = HKDF<SHA256>.deriveKey(inputKeyMaterial: masterKey, salt: Data(), info: info1, outputByteCount: 32)
        
        let receivingKeyData = HKDF<SHA256>.deriveKey(inputKeyMaterial: masterKey, salt: Data(), info: info2, outputByteCount: 32)

        // Initialize session state
        sessionState = SessionState(
            handshakeCompleted: true,
            lastHandshake: Date(),
            ephemeralKey: ephemeralKey,
            sharedSecret: masterKey,
            receivingKey: SymmetricKey(data: receivingKeyData),
            sendingKey: SymmetricKey(data: sendingKeyData)
        )

        logger.log("Handshake completed successfully", level: .info)

        // Send keepalive packets periodically
        scheduleKeepalive()
    }

    // MARK: - Packet Processing
    private func startPacketProcessing() {
        // Start receiving packets from server
        startReceiving()

        // Process queued outbound packets
        processOutboundQueue()
    }

    private func startReceiving() {
        connection?.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] (data, context, isComplete, error) in
            guard let self = self else { return }

            if let data = data {
                self.inboundQueue.async {
                    self.handleInboundPacket(data)
                }
            }

            if self.isRunning {
                self.startReceiving()
            }
        }
    }

    private func processOutboundQueue() {
        outboundQueue.async { [weak self] in
            guard let self = self else { return }

            while self.isRunning && !self.outboundPackets.isEmpty {
                let (packet, completion) = self.outboundPackets.removeFirst()
                self.sendToServer(packet, completion: completion)
            }
        }
    }

    // MARK: - Encryption/Decryption
    func encrypt(_ data: Data) throws -> Data {
        guard var state = sessionState, state.handshakeCompleted else {
            throw TunnelError.tunnelFailed
        }

        // Create packet header
        var packet = Data()

        // Type (0x01 for data)
        packet.append(0x01)

        // Sender index (simplified)
        packet.append(contentsOf: [0x00, 0x00, 0x00, 0x01])

        // Replay counter
        let counterData = withUnsafeBytes(of: state.replayCounter.bigEndian) { Data($0) }
        packet.append(counterData)
        state.replayCounter += 1
        
        // save updated state
        sessionState = state

        // Encrypt payload
        let nonce = try AES.GCM.Nonce(data: counterData[0..<12])
        let sealedBox = try AES.GCM.seal(data, using: state.sendingKey!, nonce: nonce)

        // Append encrypted data and tag
        packet.append(sealedBox.ciphertext)
        packet.append(sealedBox.tag)

        return packet
    }

    func decrypt(_ data: Data) throws -> Data {
        guard let state = sessionState, state.handshakeCompleted else {
            throw TunnelError.tunnelFailed
        }

        guard data.count > 17 else { // Minimum packet size
            throw TunnelError.invalidConfiguration
        }

        // Extract nonce (from replay counter)
        let counterStart = 5
        let counterEnd = counterStart + 8

        // Extract ciphertext and tag
        let ciphertextEnd = data.count - 16
        let ciphertext = data[17..<ciphertextEnd]
        let tag = data[ciphertextEnd..<data.count]

        // Decrypt
        let nonce = try AES.GCM.Nonce(data: data[counterStart..<counterEnd])
        let sealedBox = try AES.GCM.SealedBox(nonce: nonce, ciphertext: Data(ciphertext), tag: Data(tag))
        let decryptedData = try AES.GCM.open(sealedBox, using: state.receivingKey!)

        return decryptedData
    }

    // MARK: - Send/Receive
    func send(_ data: Data, completion: CompletionHandler? = nil) {
        guard isRunning else {
            completion?(.failure(TunnelError.tunnelFailed))
            return
        }

        outboundQueue.async { [weak self] in
            self?.outboundPackets.append((data, completion ?? { _ in }))
            self?.processOutboundQueue()
        }
    }

    private func sendToServer(_ data: Data, completion: CompletionHandler? = nil) {
        connection?.send(content: data, completion: .contentProcessed { error in
            if let error = error {
                self.logger.log("Send error: \(error)", level: .error)
                completion?(.failure(error))
            } else {
                completion?(.success(()))
            }
        })
    }

    private func handleInboundPacket(_ data: Data) {
        do {
            let decrypted = try decrypt(data)

            // Process through packet handler (would be called back to PacketHandler)
            // For now, just log
            logger.log("Received packet: \(decrypted.count) bytes", level: .debug)

        } catch {
            logger.log("Decryption error: \(error)", level: .error)
        }
    }

    // MARK: - Keepalive
    private func scheduleKeepalive() {
        let interval = TimeInterval(config.keepAlive)

        DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + interval) { [weak self] in
            guard let self = self, self.isRunning else { return }

            self.sendKeepalive()
            self.scheduleKeepalive()
        }
    }

    private func sendKeepalive() {
        let keepalivePacket = Data()
        connection?.send(content: keepalivePacket, completion: .contentProcessed { error in
            if let error = error {
                self.logger.log("Keepalive failed: \(error)", level: .warning)
            }
        })
    }
}


