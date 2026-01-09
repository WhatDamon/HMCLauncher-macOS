import Foundation

// MARK: - Debug Logger
struct DebugLogger {
    enum Level: String {
        case debug = "DEBUG"
        case info = "INFO"
        case warn = "WARN"
        case error = "ERROR"
    }

    static var isEnabled: Bool { LauncherEnv.isDebug }
    static let logURL: URL? = nil

    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        return f
    }()

    static func log(
        _ message: String,
        level: Level = .debug,
        file: String = #fileID,
        line: Int = #line
    ) {
        guard isEnabled else { return }

        let time = formatter.string(from: Date())
        let filename = file.split(separator: "/").last ?? ""
        let lineText =
            "[\(time)][\(level.rawValue)][HMCLauncher-macOS][\(filename):\(line)] \(message)"

        print(lineText)

        if let url = logURL, let data = (lineText + "\n").data(using: .utf8) {
            append(data, to: url)
        }
    }

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
