import Foundation

// MARK: - Environment & Arguments
public struct LauncherEnv {
    // User / Build Configurable Values

    public static let LAUNCHER_VER = "3.8.0"
    public static let HMCL_EXPECTED_JAVA_MAJOR_VERSION = 17
    public static let HMCL_JAR_PATH = "../Resources/HMCL.jar"

    public static let urlHMCLGithubPage = "https://github.com/HMCL-dev/HMCL"
    public static let urlJavaDownloadLinkArm64 = "https://docs.hmcl.net/downloads/macos/arm64.html"
    public static let urlJavaDownloadLinkX86_64 = "https://docs.hmcl.net/downloads/macos/x86_64.html"

    // Raw Process State
    public static let ENV = ProcessInfo.processInfo.environment
    public static let ARGS = CommandLine.arguments

    // Platform Information
    public static let IS_INSIDE_APP_BUNDLE = AppPath.isRunningInsideAppBundle()
    public static let DARWIN_VER = SystemUtils.getDarwinMajorVersion()
    public static let MACOS_VER = SystemUtils.macOSVersionString(fromDarwin: DARWIN_VER)

    // Debug Mode
    public static let IS_DEBUG: Bool = {
        #if DEBUG
            return true
        #else
            return ARGS.contains("--debug")
        #endif
    }()

    // JVM Parameters
    public static let JVM_ARGS: [String] = {
        let envArgs = JVMArgsParser.parse(from: ENV["HMCL_JAVA_OPTS"])
        let cliArgs = JVMArgsParser.parse(from: ARGS)

        var merged: [String: String] = [:]

        for arg in envArgs {
            merged[JVMArgsParser.argKey(arg)] = arg
        }

        for arg in cliArgs {
            merged[JVMArgsParser.argKey(arg)] = arg
        }

        return Array(merged.values)
    }()

    // Logging
    public static let logURL: URL? = {
        guard IS_DEBUG else { return nil }
        return try? AppPath.newLogFileURL()
    }()
}
