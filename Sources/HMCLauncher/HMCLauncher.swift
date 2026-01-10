import Foundation

// MARK: - Main Entry Point
@main
struct HMCLauncher {
    static func main() {
        basicInfoOutput()

        if LauncherEnv.DARWIN_VER < 19 {
            DebugLogger.log(
                "Unsupported macOS detected: Darwin \(LauncherEnv.DARWIN_VER)", level: .error)
            showDialog(L.t("UNSUPPPRTED_MACOS"), title: L.t("WARNING_TITLE"), isWarning: true)
            exit(1)
        }

        do {
            DebugLogger.log("Attempting to select JAVA_HOME...", level: .debug)
            let source = try selectJavaHome()
            let javaHome: String

            switch source {
            case .environment(let path):
                DebugLogger.log("Using user-specified JAVA_HOME: \(path)", level: .info)
                javaHome = path
            case .autoDetected(let path):
                DebugLogger.log("Auto-detected JAVA_HOME: \(path)", level: .info)
                javaHome = path
            }

            DebugLogger.log("Final JAVA_HOME selected: \(javaHome)", level: .debug)
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
                "Newest installed Java (\(installation.versionStr)) is lower than required (\(LauncherEnv.HMCL_EXPECTED_JAVA_MAJOR_VERSION))",
                level: .warn
            )
            showDialog(
                L.t(
                    "JAVA_TOO_OLD",
                    "\(LauncherEnv.HMCL_EXPECTED_JAVA_MAJOR_VERSION)",
                    installation.versionStr
                ),
                title: L.t("JAVA_NOT_SUPPORTED_TITLE"),
                buttons: [L.t("DOWNLOAD_JAVA_BUTTON"), L.t("CANCEL_BUTTON")],
                isWarning: true
            ) { button in
                if button == L.t("DOWNLOAD_JAVA_BUTTON") {
                    DebugLogger.log("User chose to download Java", level: .info)
                    downloadJava()
                } else {
                    DebugLogger.log("User cancelled Java download", level: .info)
                }
            }
            exit(1)
        } catch JavaSelectionError.userSpecifiedJavaVersionTooLow(_, let detected, _) {
            DebugLogger.log(
                "User-specified JAVA_HOME version \(detected) is lower than required (\(LauncherEnv.HMCL_EXPECTED_JAVA_MAJOR_VERSION))",
                level: .warn
            )
            showDialog(
                L.t(
                    "JAVA_TOO_OLD",
                    "\(LauncherEnv.HMCL_EXPECTED_JAVA_MAJOR_VERSION)",
                    detected
                ),
                title: L.t("JAVA_NOT_SUPPORTED_TITLE"),
                buttons: [L.t("DOWNLOAD_JAVA_BUTTON"), L.t("CANCEL_BUTTON")],
                isWarning: true
            ) { button in
                if button == L.t("DOWNLOAD_JAVA_BUTTON") {
                    DebugLogger.log("User chose to download Java", level: .info)
                    downloadJava()
                } else {
                    DebugLogger.log("User cancelled Java download", level: .info)
                }
            }
            exit(1)
        } catch let error as JavaSelectionError {
            DebugLogger.log("Java selection error: \(error)", level: .error)
            showDialog(
                L.t("ERROR_OCCURRED", error.description),
                isWarning: true
            )
            exit(1)
        } catch {
            DebugLogger.log("Unknown error occurred: \(error)", level: .error)
            exit(1)
        }
        DebugLogger.log("HMCLauncher main completed successfully", level: .info)
    }
}
