import Foundation

// MARK: - URL Extensions
public extension URL {
    // MARK: - Get parent directory
    var parentDirectory: URL {
        deletingLastPathComponent()
    }

    // MARK: - Check if file exists
    var fileExists: Bool {
        FileManager.default.fileExists(atPath: path)
    }

    // MARK: - Check if directory exists
    var directoryExists: Bool {
        var isDir: ObjCBool = false
        return FileManager.default.fileExists(atPath: path, isDirectory: &isDir) && isDir.boolValue
    }

    // MARK: - Check if executable exists
    var isExecutable: Bool {
        FileManager.default.isExecutableFile(atPath: path)
    }

    // MARK: - Get file size
    var fileSize: Int? {
        try? resourceValues(forKeys: [.fileSizeKey]).fileSize
    }

    // MARK: - Append path component safely
    func appending(_ component: String, isDirectory: Bool = false) -> URL {
        appendingPathComponent(component, isDirectory: isDirectory)
    }

    // MARK: - Get relative path from base
    func relativePath(from base: URL) -> String {
        let basePath = base.standardizedFileURL.path
        let selfPath = standardizedFileURL.path
        
        if selfPath.hasPrefix(basePath) {
            var result = String(selfPath.dropFirst(basePath.count))
            if result.hasPrefix("/") {
                result = String(result.dropFirst())
            }
            return result
        }
        return selfPath
    }
}
