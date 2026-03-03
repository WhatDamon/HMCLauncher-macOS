import Foundation

public final class PathUtils {
    private init() {}

    public static var workingDirectory: URL { FileUtils.currentDirectory }

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

        return candidates.first { FileUtils.isExecutable($0) }
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

        return FileUtils.exists(at: contents.path) &&
               FileUtils.exists(at: macOS.path) &&
               FileUtils.exists(at: infoPlist.path)
    }

    public static func applicationSupportDirectory() throws -> URL {
        try FileUtils.applicationSupport()
    }

    public static func logsDirectory() throws -> URL {
        let dir = try applicationSupportDirectory()
            .appendingPathComponent("hmcl", isDirectory: true)
            .appendingPathComponent("hmclauncher-logs", isDirectory: true)

        try FileUtils.createDirectory(at: dir)

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
            DebugLogger.log("Absolute path rejected in resolveJarPath: \(relativePath)", level: .error)
            return workingDirectory.appendingPathComponent(fileName)
        }
        
        let normalizedPath = (relativePath as NSString).standardizingPath
        if normalizedPath.contains("..") {
            DebugLogger.log("Path traversal attempt blocked: \(relativePath)", level: .error)
            return workingDirectory.appendingPathComponent(fileName)
        }

        if fileName.contains("/") || fileName.contains("\\") {
            DebugLogger.log("Invalid filename rejected: \(fileName)", level: .error)
            return workingDirectory.appendingPathComponent(fileName)
        }
        
        let execDir = executableURL().deletingLastPathComponent()
        let execJar = execDir.appendingPathComponent(relativePath).appendingPathComponent(fileName).standardizedFileURL
        
        let resolvedExecPath = execJar.path
        let baseExecPath = execDir.path
        if resolvedExecPath.hasPrefix(baseExecPath + "/") || resolvedExecPath == baseExecPath {
            if FileUtils.exists(at: execJar.path) {
                return execJar
            }
        } else {
            DebugLogger.log("Path escape attempt blocked in execDir: \(resolvedExecPath)", level: .error)
        }
        
        let workingJar = workingDirectory.appendingPathComponent(relativePath).appendingPathComponent(fileName).standardizedFileURL
        let resolvedWorkingPath = workingJar.path
        let baseWorkingPath = workingDirectory.path
        if resolvedWorkingPath.hasPrefix(baseWorkingPath + "/") || resolvedWorkingPath == baseWorkingPath {
            if FileUtils.exists(at: workingJar.path) {
                return workingJar
            }
        } else {
            DebugLogger.log("Path escape attempt blocked in workingDir: \(resolvedWorkingPath)", level: .error)
        }
        
        return workingDirectory.appendingPathComponent(fileName)
    }
}
