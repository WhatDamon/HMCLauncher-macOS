import Foundation

// MARK: - Miscellaneous Utilities
public final class MiscUtils {
    private init() {}

    // MARK: - Basic Information Output
    public static func basicInfoOutput() {
        DebugLogger.log("*** HMCL Launcher for macOS \(LauncherEnv.LAUNCHER_VER) ***", level: .info)
        DebugLogger.log(
            "- OS: macOS \(LauncherEnv.MACOS_VER) (Darwin \(LauncherEnv.DARWIN_VER))", level: .info)
        DebugLogger.log("- Architecture: \(SystemUtils.currentArch())", level: .info)
        DebugLogger.log(
            "- Running inside App Bundle: \(LauncherEnv.IS_INSIDE_APP_BUNDLE)", level: .info)

        if !LauncherEnv.JVM_ARGS.isEmpty {
            DebugLogger.log("- JVM Options (\(LauncherEnv.JVM_ARGS.count)):", level: .info)
            for (i, arg) in LauncherEnv.JVM_ARGS.enumerated() {
                DebugLogger.log("  [\(i)]: \(arg)", level: .info)
            }
        } else {
            DebugLogger.log("- JVM Options: Null", level: .info)
        }

        DebugLogger.log(
            "- Current working directory: \(PathUtils.workingDirectory.path)", level: .info)
        DebugLogger.log("- Executable path: \(PathUtils.executableURL().path)", level: .info)
    }

    // MARK: - Open Java Download Page
    public static func downloadJava() {
        let url =
            SystemUtils.currentArch() == "arm64"
            ? LauncherEnv.urlJavaDownloadLinkArm64
            : LauncherEnv.urlJavaDownloadLinkX86_64

        do {
            try ProcessRunner.openURL(url)
        } catch {
            DebugLogger.log("Failed to open Java download link: \(error)", level: .error)
            showDialog(L.t("CANNOT_OPEN_JAVA_DOWNLOAD", "\(url)"), isWarning: true)
        }
    }
}
