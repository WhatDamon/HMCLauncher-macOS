import Foundation

public final class AppPath {
    private init() {}

    public static var workingDirectory: URL { Files.currentDirectory }

    public static func workingDirectoryChain(depth: Int = 2) -> [URL] {
        var urls: [URL] = [workingDirectory]
        var current = workingDirectory

        for _ in 0..<depth {
            current = current.parent
            urls.append(current)
        }
        return urls
    }

    public static func findJavaExecutable(base: String) -> String? {
        let candidates = [
            "bin/java",
            "Contents/Home/bin/java",
            "Home/bin/java"
        ].map { (base as NSString).appendingPathComponent($0) }

        return candidates.first { Files.isExecutable($0) }
    }

    public static func executableURL() -> URL {
        URL(fileURLWithPath: CommandLine.arguments[0]).standardizedFileURL
    }

    public static func appBundleURL() -> URL? {
        var url = executableURL()

        while url.pathComponents.count > 1 {
            if url.pathExtension == "app" { return url }
            url.deleteLastPathComponent()
        }
        return nil
    }

    public static func isRunningInsideAppBundle() -> Bool {
        guard let bundleURL = appBundleURL() else { return false }

        let contents = bundleURL.appendingPathComponent("Contents", isDirectory: true)
        let macOS = contents.appendingPathComponent("MacOS", isDirectory: true)
        let infoPlist = contents.appendingPathComponent("Info.plist", isDirectory: false)

        return Files.exists(at: contents.path) &&
               Files.exists(at: macOS.path) &&
               Files.exists(at: infoPlist.path)
    }

    public static func applicationSupportDirectory() throws -> URL {
        try Files.applicationSupport()
    }

    public static func logsDirectory() throws -> URL {
        let dir = try applicationSupportDirectory()
            .appendingPathComponent("hmcl", isDirectory: true)
            .appendingPathComponent("hmclauncher-logs", isDirectory: true)

        try Files.createDirectory(at: dir)

        return dir
    }

    public static func newLogFileURL(prefix: String = "HMCLauncher-macOS") throws -> URL {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd HH-mm-ss"

        let filename = "\(formatter.string(from: Date())) \(prefix).log"

        return try logsDirectory().appendingPathComponent(filename, isDirectory: false)
    }

    // MARK: - Resolve JAR Path
    public static func resolveJarPath(relativePath: String, fileName: String) -> URL {
        if relativePath.hasPrefix("/") {
            return URL(fileURLWithPath: relativePath).appendingPathComponent(fileName)
        }

        if let bundlePath = appBundleURL() {
            let jarInBundle = bundlePath
                .appendingPathComponent("Contents/Resources", isDirectory: true)
                .appendingPathComponent(fileName)
            if Files.exists(at: jarInBundle.path) {
                return jarInBundle
            }
        }

        let execDir = executableURL().deletingLastPathComponent()
        let relativeToExec = execDir.appendingPathComponent(relativePath).appendingPathComponent(fileName)
        if Files.exists(at: relativeToExec.path) {
            return relativeToExec
        }

        let workingDir = workingDirectory.appendingPathComponent(relativePath).appendingPathComponent(fileName)
        if Files.exists(at: workingDir.path) {
            return workingDir
        }

        return URL(fileURLWithPath: relativePath).appendingPathComponent(fileName)
    }
}
