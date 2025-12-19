import Foundation

// MARK: - Utility: Debug Logger
struct DebugLogger {
    static let logURL: URL? = nil  // need to be considered

    static func log(_ message: String) {
        guard isDebug, let logURL: URL else { return }

        let formatter: DateFormatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        let time: String = formatter.string(from: Date())

        let line: String = "[\(time)] [HMCLauncher-macOS] \(message)\n"

        guard let data: Data = line.data(using: .utf8) else { return }

        if FileManager.default.fileExists(atPath: logURL.path) {
            if let handle: FileHandle = try? FileHandle(forWritingTo: logURL) {
                handle.seekToEndOfFile()
                handle.write(data)
                try? handle.close()
            }
        } else {
            try? data.write(to: logURL)
        }
    }
}
