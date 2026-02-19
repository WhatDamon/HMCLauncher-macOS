import Foundation

// MARK: - Main Entry Point
@main
public struct HMCLauncher {
    public static func main() {
        MiscUtils.basicInfoOutput()

        if LauncherEnv.DARWIN_VER < 19 {
            DebugLogger.log(
                "Unsupported macOS detected: Darwin \(LauncherEnv.DARWIN_VER)", level: .error)
            showDialog(L.t("UNSUPPPRTED_MACOS"), title: L.t("WARNING_TITLE"), isWarning: true)
            exit(1)
        }

        do {
            let javaHomeSource = try selectJavaHome()
            let javaHome: String

            switch javaHomeSource {
            case .environment(let path):
                DebugLogger.log("Using JAVA_HOME: \(path)", level: .info)
                javaHome = path
            case .autoDetected(let path):
                DebugLogger.log("Auto-detected JAVA_HOME: \(path)", level: .info)
                javaHome = path
            }

            try launchHMCL(javaHome: javaHome)

        } catch JavaSelectionError.invalidJavaHome {
            DebugLogger.log("Invalid JAVA_HOME detected", level: .warn)
            showDialog(
                L.t("HMCL_JAVA_HOME_INVALID"),
                title: L.t("WARNING_TITLE"),
                isWarning: true
            )
            exit(1)
        } catch JavaSelectionError.newestTooLow(let installation, _) {
            DebugLogger.log(
                "Java \(installation.versionStr) < required \(LauncherEnv.HMCL_EXPECTED_JAVA_MAJOR_VERSION)",
                level: .warn
            )
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
            exit(1)
        } catch JavaSelectionError.userSpecifiedJavaVersionTooLow(_, let detected, _) {
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
            exit(1)
        } catch let error as JavaSelectionError {
            DebugLogger.log("Java selection error: \(error)", level: .error)
            showDialog(L.t("ERROR_OCCURRED", error.description), isWarning: true)
            exit(1)
        } catch {
            DebugLogger.log("Unknown error: \(error)", level: .error)
            exit(1)
        }
    }

    // MARK: - Launch HMCL
    private static func launchHMCL(javaHome: String) throws {
        let jarPath = AppPath.resolveJarPath(relativePath: LauncherEnv.HMCL_JAR_PATH, fileName: "HMCL.jar")

        guard Files.exists(at: jarPath.path) else {
            DebugLogger.log("HMCL JAR not found: \(jarPath.path)", level: .error)
            showDialog(L.t("CANNOT_FIND_HMCL"), isWarning: true)
            exit(1)
        }

        let javaExecutable = URL(fileURLWithPath: javaHome)
            .appendingPathComponent("bin/java")

        guard Files.isExecutable(javaExecutable.path) else {
            DebugLogger.log("Java executable not found: \(javaExecutable.path)", level: .error)
            exit(1)
        }

        var env = ProcessInfo.processInfo.environment
        env["JAVA_HOME"] = javaHome

        var arguments = LauncherEnv.JVM_ARGS
        arguments.append("-jar")
        arguments.append(jarPath.path)
        arguments.append(contentsOf: LauncherEnv.ARGS.dropFirst())

        DebugLogger.log("Starting HMCL with Java: \(javaExecutable.path)", level: .info)
        DebugLogger.log("Arguments: \(arguments)", level: .debug)

        let result = try ProcessRunner(executableURL: javaExecutable)
            .withArguments(arguments)
            .withEnvironment(env)
            .run()

        DebugLogger.log("HMCL exited with status: \(result.terminationStatus)", level: .info)
    }
}
