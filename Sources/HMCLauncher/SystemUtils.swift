import Foundation

// MARK:- Function: Get the device current CPU architecture
func currentArch() -> String {
    #if arch(arm64)
        return "arm64"
    #else
        return "x86_64"
    #endif
}

// MARK: - Function: Get macOS Darwin Major Version
func getDarwinMajorVersion() -> Int {
    var uts = utsname()
    uname(&uts)

    let release = withUnsafePointer(to: &uts.release) {
        $0.withMemoryRebound(to: CChar.self, capacity: 1) {
            String(cString: $0)
        }
    }

    return Int(release.prefix { $0 != "." }) ?? 0
}
