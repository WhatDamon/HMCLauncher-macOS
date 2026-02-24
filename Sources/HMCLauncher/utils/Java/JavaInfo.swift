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
        let parts = string
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

// MARK: - Java Installation Queries
public extension Array where Element == JavaInstallation {
    func sortedByVersionDescending() -> [Element] {
        sorted { $0.version > $1.version }
    }

    func filtered(byMinVersion v: JavaVersion) -> [Element] {
        self.filter { $0.version >= v }
    }

    func filtered(byArch a: String) -> [Element] {
        let target = a.trimmingCharacters(in: .whitespaces).lowercased()
        return self.filter { $0.arch.trimmingCharacters(in: .whitespaces).lowercased() == target }
    }
}

// MARK: - Find All Java Installations
public func findAllJavaInstallations() -> [JavaInstallation] {
    var installations: [JavaInstallation] = []
    
    if let result = try? ProcessRunner.javaHome(arguments: ["-X"]),
       result.isSuccess {
        let data = result.outputData
        if let list = try? PropertyListSerialization.propertyList(
            from: data, options: [], format: nil
        ) as? [[String: Any]] {
            installations.append(contentsOf: list.compactMap(JavaInstallation.init(dict:)))
        }
    }
    
    if let homebrewJava = findHomebrewOpenJDK() {
        installations.append(homebrewJava)
    }
    
    return installations
}

// MARK: - Find Homebrew OpenJDK
private func findHomebrewOpenJDK() -> JavaInstallation? {
    let brewPath = FileManager.default.fileExists(atPath: "/opt/homebrew/bin/brew") 
        ? "/opt/homebrew/bin/brew" 
        : (FileManager.default.fileExists(atPath: "/usr/local/bin/brew") 
            ? "/usr/local/bin/brew" 
            : nil)
    
    guard let brew = brewPath,
          let prefixResult = try? ProcessRunner(executableURL: URL(fileURLWithPath: brew))
            .withArguments(["--prefix", "openjdk"])
            .run(),
          prefixResult.isSuccess,
          let prefix = prefixResult.output?.trimmingCharacters(in: .whitespacesAndNewlines),
          !prefix.isEmpty else {
        return nil
    }
    
    let javaHome = prefix + "/libexec/openjdk.jdk/Contents/Home"
    let javaExec = javaHome + "/bin/java"
    
    guard FileManager.default.fileExists(atPath: javaExec) else {
        return nil
    }
    
    guard let versionResult = try? ProcessRunner(executableURL: URL(fileURLWithPath: javaExec))
        .withArguments(["-version"])
        .run(),
          versionResult.isSuccess,
          let versionOutput = versionResult.output else {
        return nil
    }
    
    let versionStr = versionOutput
        .components(separatedBy: "\n").first?
        .replacingOccurrences(of: "java version \"", with: "")
        .replacingOccurrences(of: "\"", with: "") ?? ""
    
    guard let version = JavaVersion(from: versionStr) else {
        return nil
    }
    
    let arch: String
    if let settingsResult = try? ProcessRunner(executableURL: URL(fileURLWithPath: javaExec))
        .withArguments(["-XshowSettings:all", "-version"])
        .run(),
       let output = settingsResult.output, output.contains("aarch64") {
        arch = "arm64"
    } else {
        arch = "x86_64"
    }
    
    return JavaInstallation(
        versionStr: versionStr,
        version: version,
        arch: arch,
        path: javaHome
    )
}
