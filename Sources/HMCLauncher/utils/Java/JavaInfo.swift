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
    public let vendor: String
    public let displayName: String
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
            let vendor = dict["JVMVendor"] as? String,
            let displayName = dict["JVMName"] as? String,
            let path = dict["JVMHomePath"] as? String
        else { return nil }

        self.versionStr = versionStr
        self.version = version
        self.arch = arch
        self.vendor = vendor
        self.displayName = displayName
        self.path = path
    }

    #if DEBUG
    public init(
        versionStr: String,
        version: JavaVersion,
        arch: String,
        vendor: String,
        displayName: String,
        path: String
    ) {
        self.versionStr = versionStr
        self.version = version
        self.arch = arch
        self.vendor = vendor
        self.displayName = displayName
        self.path = path
    }
    #endif
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
    guard let result = try? ProcessRunner.javaHome(arguments: ["-X"]),
          result.isSuccess else {
        return []
    }
    
    let data = result.outputData
    guard let list = try? PropertyListSerialization.propertyList(
        from: data, options: [], format: nil
    ) as? [[String: Any]] else {
        return []
    }
    return list.compactMap(JavaInstallation.init(dict:))
}
