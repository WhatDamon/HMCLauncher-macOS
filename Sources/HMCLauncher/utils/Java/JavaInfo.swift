import Foundation

// MARK: - Struct: JavaVersion
struct JavaVersion: Comparable, CustomStringConvertible {
    let major: Int
    let minor: Int
    let security: Int

    init(major: Int, minor: Int = 0, security: Int = 0) {
        self.major = major
        self.minor = minor
        self.security = security
    }

    init?(from string: String) {
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

    static func < (l: Self, r: Self) -> Bool {
        (l.major, l.minor, l.security) < (r.major, r.minor, r.security)
    }

    var description: String {
        major < 9
            ? "1.\(major).\(minor)_\(security)"
            : "\(major).\(minor).\(security)"
    }
}

// MARK: - Struct: JavaInstallation
struct JavaInstallation {
    let versionStr, arch, vendor, displayName, path: String
    let version: JavaVersion

    var isArm64: Bool {
        arch.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) == "arm64"
    }

    init?(dict: [String: Any]) {
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
private func javaHomeXData() -> Data? {
    let p = Process()
    p.executableURL = URL(fileURLWithPath: "/usr/libexec/java_home")
    p.arguments = ["-X"]

    let pipe = Pipe()
    p.standardOutput = pipe

    do {
        DebugLogger.log("Running /usr/libexec/java_home -X", level: .debug)
        try p.run()
        p.waitUntilExit()
        guard p.terminationStatus == 0 else {
            DebugLogger.log(
                "/usr/libexec/java_home terminated with \(p.terminationStatus)", level: .warn)
            return nil
        }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        DebugLogger.log("/usr/libexec/java_home returned \(data.count) bytes", level: .debug)
        return data
    } catch {
        DebugLogger.log("Failed to run /usr/libexec/java_home: \(error)", level: .error)
        return nil
    }
}

// MARK: - Function: Public API
internal func findAllJavaInstallations() -> [JavaInstallation] {
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
    func sortedByVersionDescending() -> [Element] {
        let sorted = sorted { $0.version > $1.version }
        DebugLogger.log("Sorted Java installations descending by version", level: .debug)
        return sorted
    }

    func filtered(byMinVersion v: JavaVersion) -> [Element] {
        let filtered = filter { $0.version >= v }
        DebugLogger.log(
            "Filtered Java installations >= \(v): \(filtered.count) remaining", level: .debug)
        return filtered
    }

    func filtered(byArch a: String) -> [Element] {
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
    init(
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