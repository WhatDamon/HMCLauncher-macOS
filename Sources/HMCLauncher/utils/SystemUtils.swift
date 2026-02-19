import Foundation

// MARK: - System Utilities
public final class SystemUtils {
    // MARK: - Get the device current CPU architecture
    public static func currentArch() -> String {
        #if arch(arm64)
            return "arm64"
        #else
            return "x86_64"
        #endif
    }

    // MARK: - Get macOS Darwin Major Version
    public static func getDarwinMajorVersion() -> Int {
        var uts = utsname()
        uname(&uts)

        let release = withUnsafePointer(to: &uts.release) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                String(cString: $0)
            }
        }

        return Int(release.prefix { $0 != "." }) ?? 0
    }

    // MARK: - Map Darwin Version to macOS Version
    public static func macOSVersionString(fromDarwin darwin: Int) -> String {
        switch darwin {
        case ..<19: return "unsupported"
        case 19: return "10.15"
        case 20...24: return "\(darwin - 9)"
        case 25: return "26"
        default: return "\(darwin + 1)"
        }
    }
}
