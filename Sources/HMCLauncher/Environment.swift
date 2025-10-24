import Foundation

// MARK: - Global Environment and Arguments
let env = ProcessInfo.processInfo.environment
let args = CommandLine.arguments

// MARK: - HMCL Expection
let hmclExpectedJavaMajorVersion: Int = 17
let urlJavaDownloadLinkArm64 = "https://docs.hmcl.net/downloads/macos/arm64.html"
let urlJavaDownloadLinkX86_64 = "https://docs.hmcl.net/downloads/macos/x86_64.html"