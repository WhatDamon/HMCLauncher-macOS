import Foundation

enum AppPath {
    // MARK: - Function: Get absolute path to the running executable
    static func executableURL() -> URL {
        URL(fileURLWithPath: CommandLine.arguments[0])
            .standardizedFileURL
    }

    // MARK: - Function: Check Path to the enclosing .app bundle
    static func appBundleURL() -> URL? {
        var url = executableURL()

        while url.pathComponents.count > 1 {
            if url.pathExtension == "app" {
                return url
            }
            url.deleteLastPathComponent()
        }
        return nil
    }

    // MARK: - Function: Is inside a valid macOS App Bundle
    static func isRunningInsideAppBundle() -> Bool {
        guard let bundleURL = appBundleURL() else { return false }

        let contents = bundleURL.appendingPathComponent("Contents", isDirectory: true)
        let macOS = contents.appendingPathComponent("MacOS", isDirectory: true)
        let infoPlist = contents.appendingPathComponent("Info.plist", isDirectory: false)

        let fm = FileManager.default
        return
            fm.fileExists(atPath: contents.path) &&
            fm.fileExists(atPath: macOS.path) &&
            fm.fileExists(atPath: infoPlist.path)
    }

    // MARK: - Function: Get ~/Library/Application Support
    static func applicationSupportDirectory() throws -> URL {
        try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
    }

    // MARK: - Function: Get log directory
    static func logsDirectory() throws -> URL {
        let dir = try applicationSupportDirectory()
            .appendingPathComponent("hmcl", isDirectory: true)
            .appendingPathComponent("hmclauncher-logs", isDirectory: true)

        try FileManager.default.createDirectory(
            at: dir,
            withIntermediateDirectories: true
        )

        return dir
    }

    // MARK: - Function: Log file URL
    static func newLogFileURL(
        prefix: String = "HMCLauncher-macOS"
    ) throws -> URL {

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd HH-mm-ss"

        let filename = "\(formatter.string(from: Date())) \(prefix).log"

        return try logsDirectory()
            .appendingPathComponent(filename, isDirectory: false)
    }
}