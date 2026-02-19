import Foundation

public final class AppPath {
    private init() {}

    // MARK: - Current working directory as URL
    public static var workingDirectory: URL {
        Files.currentDirectory
    }

    // MARK: - Returns cwd, parent, grandparent, etc
    public static func workingDirectoryChain(depth: Int = 2) -> [URL] {
        var urls: [URL] = [workingDirectory]
        var current = workingDirectory

        for _ in 0..<depth {
            current = current.parentDirectory
            urls.append(current)
        }
        return urls
    }

    // MARK: - Locate a Java executable under a base directory
    public static func findJavaExecutable(base: String) -> String? {
        let candidates = [
            "bin/java",
            "Contents/Home/bin/java",
            "Home/bin/java"
        ].map { (base as NSString).appendingPathComponent($0) }

        return candidates.first { Files.isExecutable($0) }
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

        let contents = bundleURL.appending("Contents", isDirectory: true)
        let macOS = contents.appending("MacOS", isDirectory: true)
        let infoPlist = contents.appending("Info.plist", isDirectory: false)

        return contents.fileExists && macOS.fileExists && infoPlist.fileExists
    }

    // MARK: - Get ~/Library/Application Support
    public static func applicationSupportDirectory() throws -> URL {
        try Files.applicationSupport()
    }

    // MARK: - Get log directory
    public static func logsDirectory() throws -> URL {
        let dir = try applicationSupportDirectory()
            .appending("hmcl", isDirectory: true)
            .appending("hmclauncher-logs", isDirectory: true)

        try Files.createDirectory(at: dir)

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
            .appending(filename, isDirectory: false)
    }
}
