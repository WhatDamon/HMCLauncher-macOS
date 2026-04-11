import XCTest

@testable import HMCLauncher

@MainActor
final class PathTests: XCTestCase {
    // MARK: - Path Tests
    func testWorkingDirectory() throws {
        let wd = PathUtils.workingDirectory
        XCTAssertTrue(FileManager.default.fileExists(atPath: wd.path))
    }

    func testWorkingDirectoryChain() throws {
        let chain = PathUtils.workingDirectoryChain(depth: 3)
        XCTAssertGreaterThanOrEqual(chain.count, 4)
        XCTAssertEqual(chain.first, PathUtils.workingDirectory)
        XCTAssertEqual(chain[1], PathUtils.workingDirectory.deletingLastPathComponent())
    }

    func testExecutableURL() throws {
        let exeURL = PathUtils.executableURL()
        XCTAssertTrue(
            exeURL.path.hasSuffix(CommandLine.arguments[0].components(separatedBy: "/").last ?? ""))
    }

    func testAppBundleDetection() throws {
        let bundleURL = PathUtils.appBundleURL()
        if let url = bundleURL {
            XCTAssertEqual(url.pathExtension, "app")
        } else {
            XCTAssertNil(bundleURL)
        }
    }

    func testIsRunningInsideAppBundle() throws {
        _ = PathUtils.isRunningInsideAppBundle()
    }

    func testApplicationSupportDirectory() throws {
        let appSupport = try PathUtils.applicationSupportDirectory()
        XCTAssertTrue(FileManager.default.fileExists(atPath: appSupport.path))
    }

    func testLogsDirectoryCreation() throws {
        let logsDir = try PathUtils.logsDirectory()
        XCTAssertTrue(FileManager.default.fileExists(atPath: logsDir.path))
        XCTAssertTrue(logsDir.lastPathComponent == "hmclauncher-logs")
    }

    func testNewLogFileURL() throws {
        let logFile = try PathUtils.newLogFileURL()
        XCTAssertTrue(logFile.path.hasSuffix(".log"))
        XCTAssertTrue(logFile.path.contains("hmcl"))
        XCTAssertTrue(logFile.lastPathComponent.contains("HMCLauncher-macOS"))

        let regex = #"\d{4}-\d{2}-\d{2} \d{2}-\d{2}-\d{2} HMCLauncher-macOS\.log"#
        XCTAssertTrue(
            logFile.lastPathComponent.range(of: regex, options: .regularExpression) != nil)
    }

    func testFindJavaExecutableReturnsNilForInvalidBase() throws {
        let result = PathUtils.findJavaExecutable(base: "/invalid/path")
        XCTAssertNil(result)
    }

    func testFindJavaExecutableReturnsPathForMock() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(
            UUID().uuidString)
        let binDir = tempDir.appendingPathComponent("bin", isDirectory: true)
        try FileManager.default.createDirectory(at: binDir, withIntermediateDirectories: true)

        let javaFile = binDir.appendingPathComponent("java")
        FileManager.default.createFile(
            atPath: javaFile.path, contents: Data(), attributes: [.posixPermissions: 0o755])

        let found = PathUtils.findJavaExecutable(base: tempDir.path)
        XCTAssertEqual(found, javaFile.path)
    }
}
