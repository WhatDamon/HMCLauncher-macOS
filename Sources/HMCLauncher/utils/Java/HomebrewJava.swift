import Foundation

public final class HomebrewJava {
    public enum InstallResult {
        case success
        case cancelled
        case failed(code: Int32, message: String)
    }

    private init() {}

    private static func brewPath() -> String {
        FileManager.default.fileExists(atPath: "/opt/homebrew/bin/brew") 
            ? "/opt/homebrew/bin/brew" 
            : "/usr/local/bin/brew"
    }

    public static func isHomebrewInstalled() -> Bool {
        guard let path = Optional("/opt/homebrew/bin/brew"), 
              FileManager.default.fileExists(atPath: path) else {
            return FileManager.default.fileExists(atPath: "/usr/local/bin/brew")
        }
        let result = try? ProcessRunner(executableURL: URL(fileURLWithPath: path))
            .withArguments(["--version"])
            .run()
        return result?.isSuccess ?? false
    }

    public static func installOpenJDK() -> InstallResult {
        let path = brewPath()
        DebugLogger.log("Running: \(path) install openjdk", level: .info)
        
        let script = """
            do shell script "\(path) install openjdk --formulae 2>&1"
            return result
            """

        do {
            let output = try ProcessRunner.runAppleScript(script)
            DebugLogger.log("brew install output: \(output)", level: .debug)
            
            if output.contains("Already up-to-date") || output.contains("was installed") || output.isEmpty {
                return .success
            }
            if output.lowercased().contains("error") || output.lowercased().contains("failed") {
                return .failed(code: -1, message: output)
            }
            return .success
        } catch {
            DebugLogger.log("brew install error: \(error)", level: .error)
            return .failed(code: -1, message: error.localizedDescription)
        }
    }

    public static func getHomebrewOpenJDKPath() -> String? {
        let path = brewPath()
        guard FileManager.default.fileExists(atPath: path) else { return nil }
        let result = try? ProcessRunner(executableURL: URL(fileURLWithPath: path))
            .withArguments(["--prefix", "openjdk"])
            .run()
        return result?.output?.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
