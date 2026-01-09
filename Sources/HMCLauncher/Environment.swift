import Foundation

// MARK: - Environment & Arguments
struct LauncherEnv {
    // Environment
    static let env = ProcessInfo.processInfo.environment
    static let args = CommandLine.arguments

    // Debug mode
    static let isDebug: Bool = {
        #if DEBUG
            return true
        #else
            return args.contains("--debug")
        #endif
    }()

    // Launcher info
    static let launcherVer = "3.8.0"
    static let hmclExpectedJavaMajorVersion = 17
    static let launcherPath = "../Resources/HMCL.jar"

    // URLs
    static let urlHMCLGithubPage = "https://github.com/HMCL-dev/HMCL"
    static let urlJavaDownloadLinkArm64 = "https://docs.hmcl.net/downloads/macos/arm64.html"
    static let urlJavaDownloadLinkX86_64 = "https://docs.hmcl.net/downloads/macos/x86_64.html"
    static let logURL: URL? = nil;
}
