import Foundation

// MARK: - Main Entry Point
@main
public struct HMCLauncher {
    public static func main() {
        MiscUtils.basicInfoOutput()

        guard LauncherEnv.DARWIN_VER >= 19 else {
            DebugLogger.log("Unsupported macOS: Darwin \(LauncherEnv.DARWIN_VER)", level: .error)
            showDialog(L.t("UNSUPPPRTED_MACOS"), title: L.t("WARNING_TITLE"), isWarning: true)
            exit(1)
        }

        do {
            let javaHome = try selectJavaHome()
            try launchHMCL(javaHome: javaHome)
        } catch {
            handleError(error)
        }
    }

    // MARK: - Handle Errors
    private static func handleError(_ error: Error) {
        guard let javaError = error as? JavaSelectionError else {
            DebugLogger.log("Unknown error: \(error)", level: .error)
            exit(1)
        }

        switch javaError {
        case .invalidJavaHome:
            DebugLogger.log("Invalid JAVA_HOME", level: .warn)
            showDialog(L.t("HMCL_JAVA_HOME_INVALID"), title: L.t("WARNING_TITLE"), isWarning: true)

        case .userSpecifiedJavaVersionTooLow(_, let detected, _):
            DebugLogger.log("Java \(detected) < required \(LauncherEnv.HMCL_EXPECTED_JAVA_MAJOR_VERSION)", level: .warn)
            showDialog(
                L.t("JAVA_TOO_OLD", "\(LauncherEnv.HMCL_EXPECTED_JAVA_MAJOR_VERSION)", detected),
                title: L.t("JAVA_NOT_SUPPORTED_TITLE"),
                buttons: [L.t("DOWNLOAD_JAVA_BUTTON"), L.t("CANCEL_BUTTON")],
                isWarning: true
            ) { button in
                if button == L.t("DOWNLOAD_JAVA_BUTTON") {
                    MiscUtils.downloadJava()
                }
            }

        case .newestTooLow(let installation, _):
            DebugLogger.log("Java \(installation.versionStr) < required \(LauncherEnv.HMCL_EXPECTED_JAVA_MAJOR_VERSION)", level: .warn)
            showDialog(
                L.t("JAVA_TOO_OLD", "\(LauncherEnv.HMCL_EXPECTED_JAVA_MAJOR_VERSION)", installation.versionStr),
                title: L.t("JAVA_NOT_SUPPORTED_TITLE"),
                buttons: [L.t("DOWNLOAD_JAVA_BUTTON"), L.t("CANCEL_BUTTON")],
                isWarning: true
            ) { button in
                if button == L.t("DOWNLOAD_JAVA_BUTTON") {
                    MiscUtils.downloadJava()
                }
            }

        case .noJavaInstalled, .noCompatibleJava, .noArm64OnNewMacOS:
            DebugLogger.log(javaError.description, level: .warn)
            showDialog(L.t("ERROR_OCCURRED", javaError.description), isWarning: true)
        }
        exit(1)
    }

    // MARK: - Launch HMCL
    private static func launchHMCL(javaHome source: JavaHomeSource) throws {
        let javaHome: String
        switch source {
        case .environment(let path):
            DebugLogger.log("Using JAVA_HOME: \(path)", level: .info)
            javaHome = path
        case .autoDetected(let path):
            DebugLogger.log("Auto-detected JAVA_HOME: \(path)", level: .info)
            javaHome = path
        }

        let jarPath = PathUtils.resolveJarPath(relativePath: LauncherEnv.HMCL_JAR_PATH, fileName: LauncherEnv.HMCL_JAR_NAME)

        guard FileUtils.exists(at: jarPath.path) else {
            DebugLogger.log("JAR not found: \(jarPath.path)", level: .error)
            showDialog(L.t("CANNOT_FIND_HMCL"), isWarning: true)
            exit(1)
        }

        let result = try ProcessRunner.runJar(
            jarPath: jarPath,
            javaHome: javaHome,
            jvmArgs: LauncherEnv.JVM_ARGS,
            appArgs: []
        )

        DebugLogger.log("HMCL exited with status: \(result.terminationStatus)", level: .info)
    }
}
