import Foundation

public final class AppPath {
    private init() {}

    // MARK: - Current working directory as URL
    public static var workingDirectory: URL {
        URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    }

    // MARK: - Returns cwd, parent, grandparent, etc
    public static func workingDirectoryChain(depth: Int = 2) -> [URL] {
        var urls: [URL] = [workingDirectory]
        var current = workingDirectory

        for _ in 0..<depth {
            current = current.deletingLastPathComponent()
            urls.append(current)
        }
        return urls
    }

    // MARK: - Locate a Java executable under a base directory
    public static func findJavaExecutable(base: String) -> String? {
        let fm = FileManager.default
        let candidates = [
            "bin/java",
            "Contents/Home/bin/java",
            "Home/bin/java",
        ].map { (base as NSString).appendingPathComponent($0) }

        return candidates.first { fm.isExecutableFile(atPath: $0) }
    }

    // MARK: - Get absolute path to the running executable
    public static func executableURL() -> URL {
        URL(fileURLWithPath: CommandLine.arguments[0])
            .standardizedFileURL
    }

    // MARK: - Check Path to the enclosing .app bundle
    public static func appBundleURL() -> URL? {
        var url = executableURL()

        while url.pathComponents.count > 1 {
            if url.pathExtension == "app" {
                return url
            }
            url.deleteLastPathComponent()
        }
        return nil
    }

    // MARK: - Is inside a valid macOS App Bundle
    public static func isRunningInsideAppBundle() -> Bool {
        guard let bundleURL = appBundleURL() else { return false }

        let contents = bundleURL.appendingPathComponent("Contents", isDirectory: true)
        let macOS = contents.appendingPathComponent("MacOS", isDirectory: true)
        let infoPlist = contents.appendingPathComponent("Info.plist", isDirectory: false)

        let fm = FileManager.default
        return
            fm.fileExists(atPath: contents.path) && fm.fileExists(atPath: macOS.path)
            && fm.fileExists(atPath: infoPlist.path)
    }

    // MARK: - Get ~/Library/Application Support
    public static func applicationSupportDirectory() throws -> URL {
        try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
    }

    // MARK: - Get log directory
    public static func logsDirectory() throws -> URL {
        let dir = try applicationSupportDirectory()
            .appendingPathComponent("hmcl", isDirectory: true)
            .appendingPathComponent("hmclauncher-logs", isDirectory: true)

        try FileManager.default.createDirectory(
            at: dir,
            withIntermediateDirectories: true
        )

        return dir
    }

    // MARK: - Log file URL
    public static func newLogFileURL(
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
