import Foundation

// MARK: - JavaVersion：Version Parser and compare
struct JavaVersion: Comparable, CustomStringConvertible {
    let major, minor, security: Int
    init?(from v: String) {
        let comps = v.replacingOccurrences(of: "_", with: ".")
            .split(separator: ".").compactMap { Int($0) }
        if comps.first == 1 && comps.count >= 2 {
            (major, minor, security) = (
                comps[1], comps.count > 2 ? comps[2] : 0, comps.count > 3 ? comps[3] : 0
            )
        } else {
            (major, minor, security) = (
                comps.first ?? 0, comps.count > 1 ? comps[1] : 0, comps.count > 2 ? comps[2] : 0
            )
        }
    }
    static func < (l: JavaVersion, r: JavaVersion) -> Bool {
        (l.major, l.minor, l.security) < (r.major, r.minor, r.security)
    }
    static func == (l: JavaVersion, r: JavaVersion) -> Bool {
        (l.major, l.minor, l.security) == (r.major, r.minor, r.security)
    }
    var description: String { "\(major).\(minor).\(security)" }
}

// MARK: - JavaInstallation：Single Java Info
struct JavaInstallation {
    let versionStr: String
    let version: JavaVersion
    let arch: String
    let vendor: String
    let displayName: String
    let path: String

    init?(version: String, arch: String, vendor: String, displayName: String, path: String) {
        guard let parsedVersion = JavaVersion(from: version) else {
            return nil
        }

        self.versionStr = version
        self.version = parsedVersion
        self.arch = arch
        self.vendor = vendor
        self.displayName = displayName
        self.path = path
    }
    var isArm64: Bool { arch == "arm64" }
}

// MARK: - Utility: Parser /usr/libexec/java_home -V
func execJavaHomeV() -> String {
    let process = Process()
    let pipe = Pipe()

    process.executableURL = URL(fileURLWithPath: "/usr/libexec/java_home")
    process.arguments = ["-V"]
    process.standardError = pipe

    do {
        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            return ""
        }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(decoding: data, as: UTF8.self)
    } catch {
        return ""
    }
}

func parseJavaInstallations(from output: String) -> [JavaInstallation] {
    let regex = try! NSRegularExpression(
        pattern: #"^(\S+)\s+\(([^)]+)\)\s+"([^"]+)"\s+-\s+"([^"]+)"\s+(.+)$"#)
    return output.split(separator: "\n").compactMap { line in
        let s = String(line).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !s.isEmpty, !s.contains("Matching Java Virtual Machines") else { return nil }
        let range = NSRange(s.startIndex..., in: s)
        guard let m = regex.firstMatch(in: s, range: range) else { return nil }
        let ver = String(s[Range(m.range(at: 1), in: s)!])
        let arch = String(s[Range(m.range(at: 2), in: s)!])
        let vendor = String(s[Range(m.range(at: 3), in: s)!])
        let disp = String(s[Range(m.range(at: 4), in: s)!])
        let path = String(s[Range(m.range(at: 5), in: s)!])
        return JavaInstallation(
            version: ver, arch: arch, vendor: vendor, displayName: disp, path: path)
    }
}

func findAllJavaInstallations() -> [JavaInstallation] {
    parseJavaInstallations(from: execJavaHomeV())
}

extension Array where Element == JavaInstallation {
    func sortedByVersionDescending() -> [JavaInstallation] { sorted { $0.version > $1.version } }
    func filtered(byMinVersion min: JavaVersion) -> [JavaInstallation] {
        filter { $0.version >= min }
    }
    func filtered(byArch arch: String) -> [JavaInstallation] { filter { $0.arch == arch } }
}
