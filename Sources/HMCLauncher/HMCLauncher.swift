import Foundation

// MARK: - Main Entry Point
@main
struct HMCLauncher {
    static func main() {
        DebugLogger.log("HMCLauncher-macOS \(launcherVer) Start")

        do {
            let source = try selectJavaHome()
            let javaHome: String
            switch source {
            case .environment(let path):
                print("Specific JAVA_HOME: \(path)")
                javaHome = path
            case .autoDetected(let path):
                print("Auto select JAVA_HOME: \(path)")
                javaHome = path
            }
        } catch let e as JavaSelectionError {
            print(e.description)
            exit(1)
        } catch {
            print("Unknown error: \(error)")
            exit(1)
        }
    }
}
