import Foundation

// MARK: - Struct: JavaVersion
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
        let parts =
            string
            .replacingOccurrences(of: "_", with: ".")
            .replacingOccurrences(of: "-", with: ".")
            .split(separator: ".")
            .compactMap { Int($0) }

        guard !parts.isEmpty else { return nil }

        if parts.first == 1, parts.count >= 2 {
            self.init(
                major: parts.count > 1 ? parts[1] : 0,
                minor: parts.count > 2 ? parts[2] : 0,
                security: parts.count > 3 ? parts[3] : 0
            )
        } else {
            self.init(
                major: parts[0],
                minor: parts.count > 1 ? parts[1] : 0,
                security: parts.count > 2 ? parts[2] : 0
            )
        }
    }

    public static func < (l: Self, r: Self) -> Bool {
        (l.major, l.minor, l.security) < (r.major, r.minor, r.security)
    }

    public var description: String {
        major < 9
            ? "1.\(major).\(minor)_\(security)"
            : "\(major).\(minor).\(security)"
    }
}

// MARK: - Struct: JavaInstallation
public struct JavaInstallation: Sendable {
    public let versionStr: String
    public let arch: String
    public let path: String
    public let version: JavaVersion

    public var isArm64: Bool {
        arch.trimmingCharacters(in: .whitespaces).lowercased() == "arm64"
    }

    public init?(dict: [String: Any]) {
        guard
            (dict["JVMEnabled"] as? Bool) != false,
            let versionStr = dict["JVMVersion"] as? String,
            let version = JavaVersion(from: versionStr),
            let arch = dict["JVMArch"] as? String,
            let path = dict["JVMHomePath"] as? String
        else { return nil }

        self.versionStr = versionStr
        self.version = version
        self.arch = arch
        self.path = path
    }

    public init(
        versionStr: String,
        version: JavaVersion,
        arch: String,
        path: String
    ) {
        self.versionStr = versionStr
        self.version = version
        self.arch = arch
        self.path = path
    }
}

// MARK: - Find All Java Installations
public func findAllJavaInstallations() -> [JavaInstallation] {
    var installations: [JavaInstallation] = []

    // 1. Find system Java via /usr/libexec/java_home
    if let result = try? ProcessRunner.javaHome(arguments: ["-X"]),
        result.isSuccess
    {
        let data = result.outputData
        if let list = try? PropertyListSerialization.propertyList(
            from: data, options: [], format: nil
        ) as? [[String: Any]] {
            installations.append(contentsOf: list.compactMap(JavaInstallation.init(dict:)))
        }
    }

    // 2. Find Homebrew OpenJDK
    if let homebrewPath = HomebrewJava.getHomebrewOpenJDKPath() {
        let javaHome = homebrewPath + "/libexec/openjdk.jdk/Contents/Home"
        let javaExec = javaHome + "/bin/java"

        guard FileManager.default.fileExists(atPath: javaExec) else {
            return installations
        }

        guard
            let versionResult = try? ProcessRunner(executableURL: URL(fileURLWithPath: javaExec))
                .withArguments(["-version"])
                .run(),
            versionResult.isSuccess,
            let versionOutput = versionResult.output
        else {
            return installations
        }

        let versionStr =
            versionOutput
            .components(separatedBy: "\n").first?
            .replacingOccurrences(of: "java version \"", with: "")
            .replacingOccurrences(of: "\"", with: "") ?? ""

        guard let version = JavaVersion(from: versionStr) else {
            return installations
        }

        // Detect architecture
        let arch: String
        if let settingsResult = try? ProcessRunner(executableURL: URL(fileURLWithPath: javaExec))
            .withArguments(["-XshowSettings:all", "-version"])
            .run(),
            let output = settingsResult.output, output.contains("aarch64")
        {
            arch = "arm64"
        } else {
            arch = "x86_64"
        }

        installations.append(
            JavaInstallation(
                versionStr: versionStr,
                version: version,
                arch: arch,
                path: javaHome
            ))
    }

    return installations
}
