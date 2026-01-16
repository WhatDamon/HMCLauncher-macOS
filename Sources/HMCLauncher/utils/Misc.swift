import Foundation

// MARK: - Basic Information Output
func basicInfoOutput() {
    DebugLogger.log("*** HMCL Launcher for macOS \(LauncherEnv.LAUNCHER_VER) ***", level: .info)
    DebugLogger.log("- OS: macOS \(LauncherEnv.MACOS_VER) (Darwin \(LauncherEnv.DARWIN_VER))", level: .info)
    DebugLogger.log("- Architecture: \(currentArch())", level: .info)
    DebugLogger.log("- Running inside App Bundle: \(LauncherEnv.IS_INSIDE_APP_BUNDLE)", level: .info)
    
    if !LauncherEnv.ARGS.isEmpty {
        DebugLogger.log("- Command-line arguments (\(LauncherEnv.ARGS.count)):", level: .info)
        for (i, arg) in LauncherEnv.ARGS.enumerated() {
            DebugLogger.log("  [\(i)]: \(arg)", level: .info)
        }
    } else {
        DebugLogger.log("- No command-line arguments provided", level: .info)
    }

    DebugLogger.log("- Current working directory: \(AppPath.workingDirectory.path)", level: .info)
    DebugLogger.log("- Executable path: \(AppPath.executableURL().path)", level: .info)
}

// MARK: - Function: Open Java Download Page
func downloadJava() {
    let url =
        currentArch() == "arm64"
        ? LauncherEnv.urlJavaDownloadLinkArm64
        : LauncherEnv.urlJavaDownloadLinkX86_64

    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
    process.arguments = [url]

    do {
        try process.run()
    } catch {
        print("Failed to open Java download link: \(error)")
        showDialog(L.t("CANNOT_OPEN_JAVA_DOWNLOAD", "\(url)"), isWarning: true)
    }
}
