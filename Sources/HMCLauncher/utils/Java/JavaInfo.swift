import Foundation

public struct JavaVersion: Comparable, CustomStringConvertible, Sendable {
    public let major: Int
    public let minor: Int
    public let security: Int

    public init(major: Int, minor: Int = 0, security: Int = 0) {
        self.major = major
        self.minor = minor
        self.security = security
    }

    public init?(from string: String) {
        let parts = string
            .replacingOccurrences(of: "_", with: ".")
            .replacingOccurrences(of: "-", with: ".")
            .split(separator: ".")
            .compactMap { Int($0) }

        guard let first = parts.first, !parts.isEmpty else { return nil }

        if first == 1 && parts.count >= 2 {
            self.init(major: parts[1], minor: parts.dropFirst().dropFirst().first ?? 0, security: parts.dropFirst(3).first ?? 0)
        } else {
            self.init(major: first, minor: parts.dropFirst().first ?? 0, security: parts.dropFirst(2).first ?? 0)
        }
    }

    public static func < (l: Self, r: Self) -> Bool {
        (l.major, l.minor, l.security) < (r.major, r.minor, r.security)
    }

    public var description: String {
        major < 9 ? "1.\(major).\(minor)_\(security)" : "\(major).\(minor).\(security)"
    }
}

public struct JavaInstallation: Sendable {
    public let versionStr: String
    public let arch: String
    public let path: String
    public let version: JavaVersion

    public var isArm64: Bool { arch.lowercased() == "arm64" }

    public init?(dict: [String: Any]) {
        guard (dict["JVMEnabled"] as? Bool) != false,
              let versionStr = dict["JVMVersion"] as? String,
              let version = JavaVersion(from: versionStr),
              let arch = dict["JVMArch"] as? String,
              let path = dict["JVMHomePath"] as? String else { return nil }

        self.versionStr = versionStr
        self.version = version
        self.arch = arch
        self.path = path
    }

    public init(versionStr: String, version: JavaVersion, arch: String, path: String) {
        self.versionStr = versionStr
        self.version = version
        self.arch = arch
        self.path = path
    }
}

public func findAllJavaInstallations() -> [JavaInstallation] {
    var installations: [JavaInstallation] = []

    if let result = try? ProcessRunner.javaHome(arguments: ["-X"]),
       let list = try? PropertyListSerialization.propertyList(from: result.outputData, options: [], format: nil) as? [[String: Any]] {
        installations.append(contentsOf: list.compactMap(JavaInstallation.init(dict:)))
    }

    detectHomebrewJava(&installations)

    #if DEBUG
    if installations.isEmpty {
        DebugLogger.log("No Java installations found", level: .debug)
    } else {
        DebugLogger.log("Found \(installations.count) Java installation(s):", level: .debug)
        for (index, java) in installations.enumerated() {
            DebugLogger.log("  [\(index)] \(java.versionStr) (\(java.arch)) - \(java.path)", level: .debug)
        }
    }
    #endif

    return installations
}

private func detectHomebrewJava(_ installations: inout [JavaInstallation]) {
    guard let homebrewPath = HomebrewJava.getHomebrewOpenJDKPath() else { return }

    let javaHome = homebrewPath + "/libexec/openjdk.jdk/Contents/Home"
    let javaExec = javaHome + "/bin/java"

    guard FileManager.default.fileExists(atPath: javaExec),
          let versionResult = try? ProcessRunner(executableURL: URL(fileURLWithPath: javaExec)).withArguments(["-version"]).run(),
          versionResult.isSuccess else { return }

    let versionOutput = versionResult.error ?? ""
    guard let versionLine = versionOutput.components(separatedBy: "\n").first(where: { $0.contains("version") }) else { return }

    let versionStr = versionLine
        .replacingOccurrences(of: "java version \"", with: "")
        .replacingOccurrences(of: "openjdk version \"", with: "")
        .replacingOccurrences(of: "\"", with: "")
        .components(separatedBy: " ").first ?? ""

    guard let version = JavaVersion(from: versionStr) else { return }

    let arch: String
    if let settingsResult = try? ProcessRunner(executableURL: URL(fileURLWithPath: javaExec)).withArguments(["-XshowSettings:all", "-version"]).run() {
        let combined = (settingsResult.output ?? "") + (settingsResult.error ?? "")
        arch = combined.contains("aarch64") ? "arm64" : "x86_64"
    } else {
        arch = "x86_64"
    }

    installations.append(JavaInstallation(versionStr: versionStr, version: version, arch: arch, path: javaHome))
}