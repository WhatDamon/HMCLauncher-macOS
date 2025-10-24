import Foundation

// MARK: - Main Entry Point
@main
struct HMCLauncher {
    static func main() {
        // Resolve JAVA_HOME
        var javaHome: String? = nil

        // HMCL_JAVA_HOME first
        if let hmclJavaHome = env["HMCL_JAVA_HOME"], !hmclJavaHome.isEmpty {
            if FileManager.default.fileExists(atPath: hmclJavaHome) {
                javaHome = hmclJavaHome
            } else {
                showDialog(
                    L.t("HMCL_JAVA_HOME_INVALID"),
                    title: L.t("WARNING_TITLE")
                )
            }
        }

        // Fallback or no HMCL_JAVA_HOME
        if javaHome == nil {
            javaHome = env["JAVA_HOME"]
            if javaHome == nil || javaHome!.isEmpty
                || !FileManager.default.fileExists(atPath: javaHome!)
            {
                javaHome = resolveJavaHome()
            }
        }

        // Ensure javaHome is valid
        guard let javaHomeUnwrapped = javaHome,
            FileManager.default.fileExists(atPath: javaHomeUnwrapped)
        else {
            showDialog(
                L.t("JAVA_HOME_MISSING", "\(hmclExpectedJavaMajorVersion)"),
                title: L.t("JAVA_MISSING_TITLE"),
                buttons: [L.t("DOWNLOAD_JAVA_BUTTON"), L.t("CANCEL_BUTTON")]
            ) { button in
                if button == L.t("DOWNLOAD_JAVA_BUTTON") {
                    downloadJava()
                }
            }
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
            return
        }

        // For test propose
        print("\(javaHomeUnwrapped), \(javaExec), \(javaMajorVersion)")

        // Check HMCL
        if checkLauncherExistence() == false {
            showDialog(L.t("CANNOT_FIND_HMCL"))
        }
    }
}
