import Foundation

// MARK: - File Utilities
public final class Files {
    private nonisolated(unsafe) static let fileManager: FileManager = .default

    private init() {}

    public static func exists(at path: String) -> Bool {
        fileManager.fileExists(atPath: path)
    }

    public static func isDirectory(_ path: String) -> Bool {
        var isDir: ObjCBool = false
        return fileManager.fileExists(atPath: path, isDirectory: &isDir) && isDir.boolValue
    }

    public static func isExecutable(_ path: String) -> Bool {
        fileManager.isExecutableFile(atPath: path)
    }

    public static func createDirectory(at url: URL, withIntermediateDirectories: Bool = true) throws {
        try fileManager.createDirectory(at: url, withIntermediateDirectories: withIntermediateDirectories)
    }

    public static func applicationSupport() throws -> URL {
        try fileManager.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
    }

    public static var tempDirectory: URL { fileManager.temporaryDirectory }

    public static var currentDirectory: URL {
        URL(fileURLWithPath: fileManager.currentDirectoryPath)
    }

    public static func readText(at url: URL) throws -> String {
        try String(contentsOf: url, encoding: .utf8)
    }

    public static func writeText(_ text: String, to url: URL, atomically: Bool = true) throws {
        try text.write(to: url, atomically: atomically, encoding: .utf8)
    }

    public static func writeData(_ data: Data, to url: URL, atomically: Bool = true) throws {
        try data.write(to: url, options: atomically ? .atomic : [])
    }
}

// MARK: - URL Extensions
public extension URL {
    var parentDirectory: URL { deletingLastPathComponent() }
    var fileExists: Bool { Files.exists(at: path) }
    var isExecutable: Bool { Files.isExecutable(path) }

    func appending(_ component: String, isDirectory: Bool = false) -> URL {
        appendingPathComponent(component, isDirectory: isDirectory)
    }
}
