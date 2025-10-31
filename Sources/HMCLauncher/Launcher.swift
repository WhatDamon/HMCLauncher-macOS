import Foundation

// MARK: - Launcher Existence Check

func checkLauncherExistence() -> Bool {
    let launcherAbsolutePath: String = getExecutablePath(launcherPath)
    return FileManager.default.fileExists(atPath: launcherAbsolutePath)
}

// MARK: - Run Launcher

func runLauncher(_ javaExec: String) {
    let fullPath: String = getExecutablePath(launcherPath)

    let process = Process()
    process.executableURL = URL(fileURLWithPath: javaExec)
    process.arguments = ["-jar", fullPath] + Array(args.dropFirst())

    do {
        try process.run()
    } catch {
        print("Failed to launch executable at \(javaExec): \(error)")
    }
}