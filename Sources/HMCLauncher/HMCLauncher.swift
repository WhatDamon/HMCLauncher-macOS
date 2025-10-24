import Foundation

// MARK: - Main Entry Point
@main
struct HMCLauncher {
    static func main() {
        // Resolve JAVA_HOME
        var javaHome: String?
        if let hmclJavaHome = env["HMCL_JAVA_HOME"], !hmclJavaHome.isEmpty {
            javaHome = hmclJavaHome
        } else {
            javaHome = resolveJavaHome()
        }

        // Ensure javaHome is valid
        guard let javaHomeUnwrapped = javaHome else {
            showDialog(L.t("JAVA_HOME_MISSING"))
            return
        }

        // Find java executable
        guard let javaExec = findJavaExecutable(javaHome: javaHomeUnwrapped) else {
            showDialog(L.t("JAVA_EXEC_NOT_FOUND"))
            return
        }

        // Get Java major version
        let javaMajorVersion = getJavaMajorVersion(javaExec: javaExec) ?? 0

        // Validate Java version
        if javaMajorVersion < hmclExpectedJavaMajorVersion {
            showDialog(
                L.t("JAVA_TOO_OLD", "\(hmclExpectedJavaMajorVersion)", "\(javaMajorVersion)"),
                title: L.t("JAVA_NOT_SUPPORTED_TITLE"),
                buttons: [L.t("DOWNLOAD_JAVA_BUTTON"), L.t("CANCEL_BUTTON")]
            ) { button in
                if button == L.t("DOWNLOAD_JAVA_BUTTON") {
                    downloadJava()
                }
            }
        }

        print("\(javaHomeUnwrapped), \(javaExec), \(javaMajorVersion)")
    }
}
