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

        guard !parts.isEmpty else {
            DebugLogger.log(
                "Failed to parse JavaVersion from empty string: '\(string)'", level: .warn)
            return nil
        }

        if parts.first == 1, parts.count >= 2 {
            self.init(
                major: parts[safe: 1] ?? 0,
                minor: parts[safe: 2] ?? 0,
                security: parts[safe: 3] ?? 0
            )
        } else {
            self.init(
                major: parts[safe: 0] ?? 0,
                minor: parts[safe: 1] ?? 0,
                security: parts[safe: 2] ?? 0
            )
        }

        DebugLogger.log("Parsed JavaVersion '\(self)' from string '\(string)'", level: .debug)
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
        arch.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) == "arm64"
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
        else {
            DebugLogger.log("Skipping invalid JVM entry: \(dict)", level: .debug)
            return nil
        }

        self.versionStr = versionStr
        self.version = version
        self.arch = arch
        self.vendor = vendor
        self.displayName = displayName
        self.path = path

        DebugLogger.log(
            "Discovered JavaInstallation: \(versionStr) (\(arch)) @ \(path)", level: .info)
    }
}

// MARK: - Function: Get Java Home Data
fileprivate func javaHomeXData() -> Data? {
    do {
        DebugLogger.log("Running /usr/libexec/java_home -X", level: .debug)
        let result = try ProcessRunner.javaHome(arguments: ["-X"])
        
        guard result.isSuccess else {
            DebugLogger.log(
                "/usr/libexec/java_home terminated with \(result.terminationStatus)", level: .warn)
            return nil
        }
        
        DebugLogger.log("/usr/libexec/java_home returned \(result.outputData.count) bytes", level: .debug)
        return result.outputData
    } catch {
        DebugLogger.log("Failed to run /usr/libexec/java_home: \(error)", level: .error)
        return nil
    }
}

// MARK: - Function: Public API
public func findAllJavaInstallations() -> [JavaInstallation] {
    guard
        let data = javaHomeXData(),
        let list = try? PropertyListSerialization.propertyList(
            from: data,
            options: [],
            format: nil
        ) as? [[String: Any]]
    else {
        DebugLogger.log("No Java installations found", level: .warn)
        return []
    }

    let installations = list.compactMap(JavaInstallation.init(dict:))
    DebugLogger.log("Total Java installations found: \(installations.count)", level: .info)
    return installations
}

// MARK: - Helpers
extension Array where Element == JavaInstallation {
    public func sortedByVersionDescending() -> [Element] {
        let sorted = sorted { $0.version > $1.version }
        DebugLogger.log("Sorted Java installations descending by version", level: .debug)
        return sorted
    }

    public func filtered(byMinVersion v: JavaVersion) -> [Element] {
        let filtered = filter { $0.version >= v }
        DebugLogger.log(
            "Filtered Java installations >= \(v): \(filtered.count) remaining", level: .debug)
        return filtered
    }

    public func filtered(byArch a: String) -> [Element] {
        let filtered = filter {
            $0.arch.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) == a.lowercased()
        }
        DebugLogger.log(
            "Filtered Java installations by arch '\(a)': \(filtered.count) remaining", level: .debug
        )
        return filtered
    }
}

extension Array {
    fileprivate subscript(safe i: Index) -> Element? { indices.contains(i) ? self[i] : nil }
}

extension JavaInstallation {
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