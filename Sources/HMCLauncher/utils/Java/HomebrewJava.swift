import Foundation

public final class HomebrewJava {
    public enum InstallResult {
        case success
        case cancelled
        case failed(code: Int32, message: String)
    }

    private init() {}

    private static let allowedBrewPaths = [
        "/opt/homebrew/bin/brew",
        "/usr/local/bin/brew"
    ]

    private static func brewPath() -> String? {
        for path in allowedBrewPaths {
            if FileManager.default.fileExists(atPath: path),
               FileManager.default.isExecutableFile(atPath: path) {
                return path
            }
        }
        return nil
    }

    public static func isHomebrewInstalled() -> Bool {
        guard let path = brewPath() else { return false }
        let result = try? ProcessRunner(executableURL: URL(fileURLWithPath: path))
            .withArguments(["--version"])
            .run()
        return result?.isSuccess ?? false
    }

    public static func installOpenJDK() -> InstallResult {
        guard let path = brewPath() else {
            return .failed(code: -1, message: "Homebrew not found or not in allowed paths")
        }

        DebugLogger.log("Running: \(path) install openjdk --formulae", level: .info)

        let result = try? ProcessRunner(executableURL: URL(fileURLWithPath: path))
            .withArguments(["install", "openjdk", "--formulae"])
            .run()

        guard let processResult = result else {
            return .failed(code: -1, message: "Failed to execute brew command")
        }

        let output = processResult.output ?? ""
        let errorOutput = processResult.error ?? ""
        let combinedOutput = output + errorOutput

        DebugLogger.log("brew install output: \(combinedOutput)", level: .debug)

        if processResult.isSuccess ||
           combinedOutput.contains("Already up-to-date") ||
           combinedOutput.contains("was installed") {
            return .success
        }

        return .failed(code: processResult.terminationStatus, message: combinedOutput)
    }

    public static func getHomebrewOpenJDKPath() -> String? {
        guard let path = brewPath() else { return nil }
        let result = try? ProcessRunner(executableURL: URL(fileURLWithPath: path))
            .withArguments(["--prefix", "openjdk"])
            .run()
        return result?.output?.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
