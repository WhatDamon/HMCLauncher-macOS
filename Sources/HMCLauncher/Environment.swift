import Foundation

// MARK: - Environment & Arguments
struct LauncherEnv {
    // Environment
    static let ENV = ProcessInfo.processInfo.environment
    static let ARGS = CommandLine.arguments
    static let IS_INSIDE_APP_BUNDLE = AppPath.isRunningInsideAppBundle()

    // Debug mode
    static let IS_DEBUG: Bool = {
        #if DEBUG
            return true
        #else
            return args.contains("--debug")
        #endif
    }()

    // Launcher info
    static let LAUNCHER_VER = "3.8.0"
    static let HMCL_EXPECTED_JAVA_MAJOR_VERSION = 17
    static let HMCL_JAR_PATH = "../Resources/HMCL.jar"

    // URLs
    static let urlHMCLGithubPage = "https://github.com/HMCL-dev/HMCL"
    static let urlJavaDownloadLinkArm64 = "https://docs.hmcl.net/downloads/macos/arm64.html"
    static let urlJavaDownloadLinkX86_64 = "https://docs.hmcl.net/downloads/macos/x86_64.html"
    static let logURL: URL? = {
        guard IS_DEBUG else { return nil }
        do {
            return try AppPath.newLogFileURL()
        } catch {
            return nil
        }
    }()
}
