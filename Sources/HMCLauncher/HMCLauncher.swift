import Foundation

// MARK: - Main Entry Point
@main
struct HMCLauncher {
    static func main() {
        DebugLogger.log("HMCLauncher-macOS \(launcherVer) Start")

        do {
            let source = try selectJavaHome()
            let javaHome: String
            switch source {
            case .environment(let path):
                print("Specific JAVA_HOME: \(path)")
                javaHome = path
            case .autoDetected(let path):
                print("Auto select JAVA_HOME: \(path)")
                javaHome = path
            }
        } catch JavaSelectionError.invalidJavaHome(_) {
            showDialog(
                L.t("HMCL_JAVA_HOME_INVALID"),
                title: L.t("WARNING_TITLE"),
                isWarning: true
            )
            exit(1)
        } catch JavaSelectionError.newestTooLow(let JavaInstallation, _) {
            showDialog(
                L.t(
                    "JAVA_TOO_OLD", "\(hmclExpectedJavaMajorVersion)",
                    "\(JavaInstallation.versionStr)"),
                title: L.t("JAVA_NOT_SUPPORTED_TITLE"),
                buttons: [L.t("DOWNLOAD_JAVA_BUTTON"), L.t("CANCEL_BUTTON")],
                isWarning: true
            ) { button in
                if button == L.t("DOWNLOAD_JAVA_BUTTON") {
                    downloadJava()
                }
            }
            exit(1)
        } catch JavaSelectionError.userSpecifiedJavaVersionTooLow(
            _, let detectedVersion, _)
        {
            showDialog(
                L.t(
                    "JAVA_TOO_OLD", "\(hmclExpectedJavaMajorVersion)", "\(detectedVersion)"),
                title: L.t("JAVA_NOT_SUPPORTED_TITLE"),
                buttons: [L.t("DOWNLOAD_JAVA_BUTTON"), L.t("CANCEL_BUTTON")],
                isWarning: true
            ) { button in
                if button == L.t("DOWNLOAD_JAVA_BUTTON") {
                    downloadJava()
                }
            }
            exit(1)
        } catch let e as JavaSelectionError {
            print(e.description)
            showDialog(L.t("ERROR_OCCURRED", "\(e.description)"), isWarning: true)
            exit(1)
        } catch {
            print("Unknown error: \(error)")
            exit(1)
        }
    }
}
