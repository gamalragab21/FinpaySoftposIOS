//
//  ReaderLogger.swift
//  FinpaySoftpos
//
//  Created by Gamal Ragab on 04/09/2025.
//

import Foundation

public protocol ReaderLogger {
    func log(_ message: String)
}


// MARK: - Console Logger
public class ConsoleReaderLogger: ReaderLogger {
    public func log(_ message: String) {
        print("[CardProcessor] \(message)")
    }
}

// MARK: - File Logger
public class FileReaderLogger: ReaderLogger {
    private let fileURL: URL
    private let fileHandle: FileHandle?

    static let logFileURL: URL? = {
        return FileReaderLogger.getLogFileURL()
    }()
    
    private static func getLogFileURL() -> URL? {
        do {
            let docs = try FileManager.default.url(for: .documentDirectory,
                                                   in: .userDomainMask,
                                                   appropriateFor: nil,
                                                   create: true)
            return docs.appendingPathComponent("ReaderLogs.txt")
        } catch {
            print("❌ Could not get documents directory: \(error)")
            return nil
        }
    }
    
    
    /// Clear log file contents
      public static func clearLogs() {
           guard let fileURL = logFileURL else { return }
           do {
               try "".write(to: fileURL, atomically: true, encoding: .utf8)
               print("🧹 Logs cleared")
           } catch {
               print("❌ Failed to clear logs: \(error)")
           }
    }
    
    public init?(fileName: String = "ReaderLogs.txt") {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.fileURL = documentsDirectory.appendingPathComponent(fileName)
        
        if !FileManager.default.fileExists(atPath: fileURL.path) {
            FileManager.default.createFile(atPath: fileURL.path, contents: nil, attributes: nil)
        }
        
        do {
            self.fileHandle = try FileHandle(forWritingTo: fileURL)
            self.fileHandle?.seekToEndOfFile()
        } catch {
            print("❌ Failed to open file for logging: \(error)")
            return nil
        }
    }
    
    public func log(_ message: String) {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let logMessage = "[\(timestamp)] [CardProcessor] \(message)\n"
        
        if let data = logMessage.data(using: .utf8) {
            fileHandle?.write(data)
        }
    }
    
    deinit {
        try? fileHandle?.close()
    }
    
    public func readLogs() -> String? {
        return try? String(contentsOf: fileURL, encoding: .utf8)
    }
    
    public func clearLogs() {
        try? "".write(to: fileURL, atomically: true, encoding: .utf8)
    }
    
    
    public func getLogFileURL() -> URL {
        print(fileURL)
        return fileURL
    }
}

// MARK: - Composite Logger
public class CompositeReaderLogger: ReaderLogger {
    private let loggers: [ReaderLogger]
    
    public init(loggers: [ReaderLogger]) {
        self.loggers = loggers
    }
    
    public func log(_ message: String) {
        for logger in loggers {
            logger.log(message)
        }
    }
}
