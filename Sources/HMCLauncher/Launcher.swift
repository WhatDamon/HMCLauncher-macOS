import Foundation

// MARK: - Launcher Existence Check
func checkLauncherExistence() -> Bool {
    let executablePath: String = args[0]
    let exeDir: String = (executablePath as NSString).deletingLastPathComponent
    let resourcePath: String = (exeDir as NSString).appendingPathComponent("\(launcherPath)")
    let standardizedPath: String = (resourcePath as NSString).standardizingPath
    return FileManager.default.fileExists(atPath: standardizedPath)
}

// MARK: - Run Launcher
func runLauncher(javaExec: String) {

}
