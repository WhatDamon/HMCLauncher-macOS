import Foundation

// MARK: - Environment & Arguments
struct LauncherEnv {
    // User / Build Configurable Values

    static let LAUNCHER_VER = "3.8.0"
    static let HMCL_EXPECTED_JAVA_MAJOR_VERSION = 17
    static let HMCL_JAR_PATH = "../Resources/HMCL.jar"

    static let urlHMCLGithubPage = "https://github.com/HMCL-dev/HMCL"
    static let urlJavaDownloadLinkArm64 = "https://docs.hmcl.net/downloads/macos/arm64.html"
    static let urlJavaDownloadLinkX86_64 = "https://docs.hmcl.net/downloads/macos/x86_64.html"

    // Raw Process State
    static let ENV = ProcessInfo.processInfo.environment
    static let ARGS = CommandLine.arguments

    // Platform Information
    static let IS_INSIDE_APP_BUNDLE = AppPath.isRunningInsideAppBundle()
    static let DARWIN_VER = getDarwinMajorVersion()
    static let MACOS_VER = macOSVersionString(fromDarwin: DARWIN_VER)

    // Debug Mode
    static let IS_DEBUG: Bool = {
        #if DEBUG
            return true
        #else
            return ARGS.contains("--debug")
        #endif
    }()

    // JVM Parameters
    static let JVM_ARGS: [String] = {
        let envArgs = parseJVMArgs(from: ENV["HMCL_JAVA_OPTS"])
        let cliArgs = parseJVMArgs(from: ARGS)

        var merged: [String: String] = [:]

        for arg in envArgs {
            merged[jvmArgKey(arg)] = arg
        }

        for arg in cliArgs {
            merged[jvmArgKey(arg)] = arg
        }

        return Array(merged.values)
    }()

    // Logging
    static let logURL: URL? = {
        guard IS_DEBUG else { return nil }
        return try? AppPath.newLogFileURL()
    }()
}
