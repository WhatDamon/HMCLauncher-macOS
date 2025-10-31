import Foundation

// MARK: - Utility: Detect System Architecture
func detectSystemArchitecture() -> String {
    var sysinfo: utsname = utsname()
    uname(&sysinfo)

    let machineMirror: Mirror = Mirror(reflecting: sysinfo.machine)
    let identifier: String = machineMirror.children.reduce("") { identifier, element in
        guard let value: Int8 = element.value as? Int8, value != 0 else { return identifier }
        return identifier + String(UnicodeScalar(UInt8(value)))
    }

    let lower: String = identifier.lowercased()
    if lower.contains("arm") || lower.contains("aarch64") {
        return "ARM64"
    } else {
        return "X86_64"
    }
}
