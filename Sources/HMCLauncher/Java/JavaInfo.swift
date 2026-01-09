import Foundation

// MARK: - Internal Utilities
private extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Internal JavaVersion Implementation
fileprivate struct _JavaVersion: Comparable, CustomStringConvertible {
    let major: Int
    let minor: Int
    let security: Int

    init(major: Int, minor: Int = 0, security: Int = 0) {
        self.major = major
        self.minor = minor
        self.security = security
    }

    init?(string: String) {
        let normalized = string
            .replacingOccurrences(of: "_", with: ".")
            .replacingOccurrences(of: "-", with: ".")

        let components = normalized
            .split(separator: ".")
            .compactMap { Int($0) }

        guard !components.isEmpty else { return nil }

        if components.first == 1, components.count >= 2 {
            // Java 8 and earlier: 1.x.y_z
            self.init(
                major: components[safe: 1] ?? 0,
                minor: components[safe: 2] ?? 0,
                security: components[safe: 3] ?? 0
            )
        } else {
            // Java 9+
            self.init(
                major: components[safe: 0] ?? 0,
                minor: components[safe: 1] ?? 0,
                security: components[safe: 2] ?? 0
            )
        }
    }

    static func < (lhs: _JavaVersion, rhs: _JavaVersion) -> Bool {
        (lhs.major, lhs.minor, lhs.security)
            < (rhs.major, rhs.minor, rhs.security)
    }

    var description: String {
        major < 9
            ? "1.\(major).\(minor)_\(security)"
            : "\(major).\(minor).\(security)"
    }
}

// MARK: - Public JavaVersion (Compatibility Wrapper)
struct JavaVersion: Comparable, Equatable, CustomStringConvertible {
    let major: Int
    let minor: Int
    let security: Int

    private let impl: _JavaVersion

    init(major: Int, minor: Int = 0, security: Int = 0) {
        let impl = _JavaVersion(
            major: major,
            minor: minor,
            security: security
        )
        self.impl = impl
        self.major = impl.major
        self.minor = impl.minor
        self.security = impl.security
    }

    init?(from versionString: String) {
        guard let impl = _JavaVersion(string: versionString) else {
            return nil
        }
        self.impl = impl
        self.major = impl.major
        self.minor = impl.minor
        self.security = impl.security
    }

    static func < (lhs: JavaVersion, rhs: JavaVersion) -> Bool {
        lhs.impl < rhs.impl
    }

    var description: String {
        impl.description
    }
}

// MARK: - Public JavaInstallation
struct JavaInstallation {
    let versionStr: String
    let version: JavaVersion
    let arch: String
    let vendor: String
    let displayName: String
    let path: String

    var isArm64: Bool { arch == "arm64" }

    fileprivate init?(from dict: [String: Any]) {
        guard
            let versionStr = dict["JVMVersion"] as? String,
            let implVersion = _JavaVersion(string: versionStr),
            let arch = dict["JVMArch"] as? String,
            let vendor = dict["JVMVendor"] as? String,
            let displayName = dict["JVMName"] as? String,
            let path = dict["JVMHomePath"] as? String,
            (dict["JVMEnabled"] as? Bool) != false
        else { return nil }

        self.versionStr = versionStr
        self.version = JavaVersion(
            major: implVersion.major,
            minor: implVersion.minor,
            security: implVersion.security
        )
        self.arch = arch
        self.vendor = vendor
        self.displayName = displayName
        self.path = path
    }
}

// MARK: - java_home Integration
private func execJavaHomeXData() -> Data? {
    let task = Process()
    let pipe = Pipe()

    task.executableURL = URL(fileURLWithPath: "/usr/libexec/java_home")
    task.arguments = ["-X"]
    task.standardOutput = pipe

    do {
        try task.run()
        task.waitUntilExit()
        guard task.terminationStatus == 0 else { return nil }
        return pipe.fileHandleForReading.readDataToEndOfFile()
    } catch {
        return nil
    }
}

// MARK: - Public API
func findAllJavaInstallations() -> [JavaInstallation] {
    guard
        let data = execJavaHomeXData(),
        let array = try? PropertyListSerialization.propertyList(
            from: data,
            options: [],
            format: nil
        ) as? [[String: Any]]
    else {
        return []
    }

    return array.compactMap(JavaInstallation.init(from:))
}

// MARK: - Collection Extensions
extension Array where Element == JavaInstallation {

    func sortedByVersionDescending() -> [JavaInstallation] {
        sorted { $0.version > $1.version }
    }

    func filtered(byMinVersion min: JavaVersion) -> [JavaInstallation] {
        filter { $0.version >= min }
    }

    func filtered(byArch arch: String) -> [JavaInstallation] {
        filter { $0.arch == arch }
    }
}