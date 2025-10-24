import Foundation

// MARK: - Launcher Existence Check
func checkLauncherExistence() -> Bool {
    let executablePath = args[0]
    let exeDir = (executablePath as NSString).deletingLastPathComponent
    let resourcePath = (exeDir as NSString).appendingPathComponent("\(launcherPath)")
    let standardizedPath = (resourcePath as NSString).standardizingPath
    return FileManager.default.fileExists(atPath: standardizedPath)
}
 