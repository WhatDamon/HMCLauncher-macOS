import Foundation

// MARK:- Function: Get the device current CPU architecture
public func currentArch() -> String {
    #if arch(arm64)
        return "arm64"
    #else
        return "x86_64"
    #endif
}

// MARK: - Function: Get macOS Darwin Major Version
public func getDarwinMajorVersion() -> Int {
    var uts = utsname()
    uname(&uts)

    let release = withUnsafePointer(to: &uts.release) {
        $0.withMemoryRebound(to: CChar.self, capacity: 1) {
            String(cString: $0)
        }
    }

    return Int(release.prefix { $0 != "." }) ?? 0
}

// MARK: - Function: Map Darwin Version to macOS Version
public func macOSVersionString(fromDarwin darwin: Int) -> String {
    switch darwin {
    case ..<19: return "unsupported"
    case 19: return "10.15"
    case 20...24: return "\(darwin - 9)"
    case 25: return "26"
    default: return "\(darwin + 1)"
    }
}
