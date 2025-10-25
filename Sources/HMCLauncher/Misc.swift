import Foundation

// MARK: - Function: Open Java Download Page
func downloadJava() {
    let url = detectSystemArchitecture() == "ARM64"
        ? urlJavaDownloadLinkArm64
        : urlJavaDownloadLinkX86_64

    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
    process.arguments = [url]

    do {
        try process.run()
    } catch {
        print("Failed to open Java download link: \(error)")
        showDialog(L.t("CANNOT_OPEN_JAVA_DOWNLOAD", "\(url)"))
    }
}