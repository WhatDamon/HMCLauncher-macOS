import Foundation

// MARK: - Debug Logger

struct DebugLogger {

    // MARK: Configuration
    static var isEnabled: Bool { LauncherEnv.isDebug }
    static let logURL: URL? = nil  // set externally if needed

    // MARK: Log Level
    enum Level: String {
        case debug = "DEBUG"
        case info = "INFO"
        case warn = "WARN"
        case error = "ERROR"
    }

    // MARK: Private State
    private static let queue = DispatchQueue(
        label: "hmclauncher.debug.logger",
        qos: .utility
    )

    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        return f
    }()

    // MARK: Logging API
    static func log(
        _ message: String,
        level: Level = .debug,
        file: String = #fileID,
        line: Int = #line
    ) {
        guard isEnabled else { return }

        queue.async {
            let time = formatter.string(from: Date())
            let filename = file.split(separator: "/").last ?? ""

            let lineText =
                "[\(time)][\(level.rawValue)][HMCLauncher-macOS][\(filename):\(line)] \(message)"

            print(lineText)

            if let url = logURL, let data = (lineText + "\n").data(using: .utf8) {
                append(data, to: url)
            }
        }
    }

    // MARK: File Writing
    private static func append(_ data: Data, to url: URL) {
        let fm = FileManager.default

        if fm.fileExists(atPath: url.path),
            let handle = try? FileHandle(forWritingTo: url)
        {
            defer { try? handle.close() }
            handle.seekToEndOfFile()
            handle.write(data)
        } else {
            try? data.write(to: url, options: .atomic)
        }
    }
}
