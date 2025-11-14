import Foundation

// MARK: - Global Environment and Arguments
let env: [String: String] = ProcessInfo.processInfo.environment
let args: [String] = CommandLine.arguments
let isDebug: Bool = args.contains("--debug")
let launcherVer: String = "3.8.0"

// MARK: - HMCL Expection
let hmclExpectedJavaMajorVersion: Int = 17
let launcherPath: String = "../Resources/HMCL.jar"
let urlHMCLGithubPage: String = "https://github.com/HMCL-dev/HMCL"
let urlJavaDownloadLinkArm64: String = "https://docs.hmcl.net/downloads/macos/arm64.html"
let urlJavaDownloadLinkX86_64: String = "https://docs.hmcl.net/downloads/macos/x86_64.html"
