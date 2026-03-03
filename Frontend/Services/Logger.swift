//
//  Logger.swift
//  SafeMesh
//
//  Created by P Deepanshu on 23/02/26.
//
import Foundation
import os.log

// MARK: - Logger
class Logger {
    // MARK: - Singleton
    static let shared = Logger()

    // MARK: - Private Properties
    private let subsystem = "com.safemesh.app"
    private let logger: OSLog
    private let fileLogger: FileLogger?
    private let isDebug: Bool

    // MARK: - Initialization
    private init() {
        #if DEBUG
        self.isDebug = true
        #else
        self.isDebug = false
        #endif

        self.logger = OSLog(subsystem: subsystem, category: "VPN")
        self.fileLogger = FileLogger()
    }

    // MARK: - Public Methods
    func log(_ message: String, level: LogLevel = .info, file: String = #file, function: String = #function, line: Int = #line) {
        let filename = (file as NSString).lastPathComponent
        let location = "\(filename):\(line) \(function)"

        // Log to system
        os_log("%{public}@ [%{public}@]", log: logger, type: level.osType, message, location)

        // Log to file in debug mode or for errors
        if isDebug || level == .error {
            fileLogger?.log(message, level: level, location: location)
        }
    }

    // MARK: - Convenience Methods
    func debug(_ message: String, file: String = #file, function: String =
#function, line: Int = #line) {
        log(message, level: .debug, file: file, function: function, line: line)
    }

    func info(_ message: String, file: String = #file, function: String = #function,
 line: Int = #line) {
        log(message, level: .info, file: file, function: function, line: line)
    }

    func warning(_ message: String, file: String = #file, function: String =
#function, line: Int = #line) {
        log(message, level: .warning, file: file, function: function, line: line)
    }

    func error(_ message: String, file: String = #file, function: String =
#function, line: Int = #line) {
        log(message, level: .error, file: file, function: function, line: line)
    }

    // MARK: - Log Levels
    enum LogLevel {
        case debug
        case info
        case warning
        case error

        var osType: OSLogType {
            switch self {
            case .debug: return .debug
            case .info: return .info
            case .warning: return .default
            case .error: return .error
            }
        }
    }
}

// MARK: - File Logger
class FileLogger {
    private let fileManager = FileManager.default
    private let logFileURL: URL?
    private let fileHandleQueue = DispatchQueue(label: "com.safemesh.filelogger")
    private var fileHandle: FileHandle?

    private let maxFileSize: UInt64 = 10 * 1024 * 1024 // 10 MB
    private let maxLogFiles = 5

    init() {
        // Setup app group container for shared access
        guard let containerURL =
fileManager.containerURL(forSecurityApplicationGroupIdentifier:
"group.com.safemesh.app") else {
            self.logFileURL = nil
            return
        }

        let logsDirectory = containerURL.appendingPathComponent("Logs", isDirectory:
 true)

        // Create logs directory if it doesn't exist
        try? fileManager.createDirectory(at: logsDirectory,
withIntermediateDirectories: true)

        // Get current log file
        self.logFileURL =
logsDirectory.appendingPathComponent("vpn_\(dateString()).log")

        setupLogFile()
    }

    private func setupLogFile() {
        guard let logFileURL = logFileURL else { return }

        // Check if file exists and is too large
        if fileManager.fileExists(atPath: logFileURL.path) {
            if let attributes = try? fileManager.attributesOfItem(atPath:
logFileURL.path),
               let fileSize = attributes[.size] as? UInt64,
               fileSize > maxFileSize {
                rotateLogs()
            }
        } else {
            fileManager.createFile(atPath: logFileURL.path, contents: nil)
        }

        // Open file handle
        fileHandleQueue.sync {
            fileHandle = try? FileHandle(forWritingTo: logFileURL)
            fileHandle?.seekToEndOfFile()
        }
    }

    private func dateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    private func rotateLogs() {
        guard let logsDirectory = logFileURL?.deletingLastPathComponent() else {
return }

        // Get all log files
        guard let logFiles = try? fileManager.contentsOfDirectory(
            at: logsDirectory,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: []
        ) else { return }

        // Sort by modification date (oldest first)
        let sortedFiles = logFiles.sorted { file1, file2 in
            guard let date1 = try? file1.resourceValues(forKeys:
[.contentModificationDateKey]).contentModificationDate,
                  let date2 = try? file2.resourceValues(forKeys:
[.contentModificationDateKey]).contentModificationDate else {
                return true
            }
            return date1 < date2
        }

        // Delete old files if we have too many
        if sortedFiles.count > maxLogFiles {
            let filesToDelete = sortedFiles.prefix(sortedFiles.count - maxLogFiles)
            for file in filesToDelete {
                try? fileManager.removeItem(at: file)
            }
        }
    }

    func log(_ message: String, level: Logger.LogLevel, location: String) {
        guard let logFileURL = logFileURL else { return }

        let timestamp = ISO8601DateFormatter().string(from: Date())
        let logEntry = "[\(timestamp)] [\(level)] [\(location)] \(message)\n"

        fileHandleQueue.sync {
            if fileHandle == nil {
                setupLogFile()
            }

            if let data = logEntry.data(using: .utf8) {
                fileHandle?.write(data)
            }
        }
    }

    deinit {
        fileHandleQueue.sync {
            fileHandle?.closeFile()
        }
    }
}

// MARK: - Log Viewer
class LogViewer {
    static let shared = LogViewer()

    func getLogs(limit: Int = 1000) -> [String] {
        guard let logsDirectory =
FileManager.default.containerURL(forSecurityApplicationGroupIdentifier:
"group.com.safemesh.app")?.appendingPathComponent("Logs") else {
            return []
        }

        guard let files = try? FileManager.default.contentsOfDirectory(at:
logsDirectory, includingPropertiesForKeys: nil) else {
            return []
        }

        var allLogs: [String] = []

        // Read from all log files (newest first)
        for file in files.reversed() {
            guard let content = try? String(contentsOf: file) else { continue }
            allLogs.append(contentsOf: content.components(separatedBy: "\n").filter
{ !$0.isEmpty })
        }

        return Array(allLogs.suffix(limit))
    }

    func clearLogs() {
        guard let logsDirectory =
FileManager.default.containerURL(forSecurityApplicationGroupIdentifier:
"group.com.safemesh.app")?.appendingPathComponent("Logs") else {
            return
        }

        try? FileManager.default.removeItem(at: logsDirectory)
    }

    func exportLogs() -> URL? {
        guard let logsDirectory =
FileManager.default.containerURL(forSecurityApplicationGroupIdentifier:
"group.com.safemesh.app")?.appendingPathComponent("Logs") else {
            return nil
        }

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(
"vpn_logs_\(Date().timeIntervalSince1970).txt")

        var allContent = ""

        if let files = try? FileManager.default.contentsOfDirectory(at:
logsDirectory, includingPropertiesForKeys: nil) {
            for file in files {
                if let content = try? String(contentsOf: file) {
                    allContent += "\n=== \(file.lastPathComponent) ===\n"
                    allContent += content
                    allContent += "\n"
                }
            }
        }

        try? allContent.write(to: tempURL, atomically: true, encoding: .utf8)

        return tempURL
    }
}

