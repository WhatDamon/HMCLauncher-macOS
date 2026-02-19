import Foundation

// MARK: - File Utilities
public final class Files {
    private nonisolated(unsafe) static let fileManager: FileManager = .default

    private init() {}

    // MARK: - Check if path exists
    public static func exists(at path: String) -> Bool {
        fileManager.fileExists(atPath: path)
    }

    // MARK: - Check if path exists and is directory
    public static func isDirectory(_ path: String) -> Bool {
        var isDir: ObjCBool = false
        return fileManager.fileExists(atPath: path, isDirectory: &isDir) && isDir.boolValue
    }

    // MARK: - Check if file is executable
    public static func isExecutable(_ path: String) -> Bool {
        fileManager.isExecutableFile(atPath: path)
    }

    // MARK: - Create directory
    public static func createDirectory(
        at url: URL,
        withIntermediateDirectories: Bool = true
    ) throws {
        try fileManager.createDirectory(
            at: url,
            withIntermediateDirectories: withIntermediateDirectories
        )
    }

    // MARK: - Get Application Support directory
    public static func applicationSupport() throws -> URL {
        try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
    }

    // MARK: - Get Caches directory
    public static func caches() throws -> URL {
        try fileManager.url(
            for: .cachesDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
    }

    // MARK: - Get temp directory
    public static var tempDirectory: URL {
        fileManager.temporaryDirectory
    }

    // MARK: - Get current working directory
    public static var currentDirectory: URL {
        URL(fileURLWithPath: fileManager.currentDirectoryPath)
    }

    // MARK: - List directory contents
    public static func contents(of directory: URL) throws -> [URL] {
        try fileManager.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil,
            options: []
        )
    }

    // MARK: - Copy item
    public static func copyItem(from source: URL, to destination: URL) throws {
        try fileManager.copyItem(at: source, to: destination)
    }

    // MARK: - Move item
    public static func moveItem(from source: URL, to destination: URL) throws {
        try fileManager.moveItem(at: source, to: destination)
    }

    // MARK: - Remove item
    public static func removeItem(at url: URL) throws {
        try fileManager.removeItem(at: url)
    }

    // MARK: - Read text file
    public static func readText(at url: URL) throws -> String {
        try String(contentsOf: url, encoding: .utf8)
    }

    // MARK: - Write text file
    public static func writeText(_ text: String, to url: URL, atomically: Bool = true) throws {
        try text.write(to: url, atomically: atomically, encoding: .utf8)
    }

    // MARK: - Read data
    public static func readData(at url: URL) throws -> Data {
        try Data(contentsOf: url)
    }

    // MARK: - Write data
    public static func writeData(_ data: Data, to url: URL, atomically: Bool = true) throws {
        try data.write(to: url, options: atomically ? .atomic : [])
    }
}
