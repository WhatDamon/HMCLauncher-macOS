import Foundation

// MARK: - Helper: Get Executable Path
func getExecutablePath(_ relativePath: String) -> String {
    let executablePath = args[0]
    let exeDir = (executablePath as NSString).deletingLastPathComponent
    let fullPath = (exeDir as NSString).appendingPathComponent(relativePath)
    return (fullPath as NSString).standardizingPath
}

//MARK: - Helper: Get CWD
func getCWD(_ relativePath: String) -> String {
    let cwd = FileManager.default.currentDirectoryPath
    let fullPath = URL(fileURLWithPath: relativePath, relativeTo: URL(fileURLWithPath: cwd))
        .standardized.path
    return fullPath
}

// MARK: - Helper: Canonicalize File Path
extension FileManager {
    func canonicalizePath(_ path: String) throws -> String {
        var result: String = path
        if let resolved: String = try? self.destinationOfSymbolicLink(atPath: path) {
            result = resolved
        }
        return (result as NSString).standardizingPath
    }
}