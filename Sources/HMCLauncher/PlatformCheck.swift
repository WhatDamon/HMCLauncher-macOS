import Foundation

// MARK: - Utility: Detect System Architecture
func detectSystemArchitecture() -> String {
    var sysinfo = utsname()
    uname(&sysinfo)

    let machineMirror = Mirror(reflecting: sysinfo.machine)
    let identifier = machineMirror.children.reduce("") { identifier, element in
        guard let value = element.value as? Int8, value != 0 else { return identifier }
        return identifier + String(UnicodeScalar(UInt8(value)))
    }

    let lower = identifier.lowercased()
    if lower.contains("arm") || lower.contains("aarch64") {
        return "ARM64"
    } else {
        return "X86_64"
    }
}