import XCTest

@testable import HMCLauncher

@MainActor
final class JavaLocatorTests: XCTestCase {
    private var originalFindAll: () -> [JavaInstallation] = { [] }
    private var originalArch: () -> String = { "x86_64" }
    private var originalDarwin: () -> Int = { 23 }

    // MARK: - Setup / Teardown
    override func setUp() async throws {
        try await super.setUp()
        originalFindAll = _findAllJavaInstallations
        originalArch = _currentArch
        originalDarwin = _getDarwinMajorVersion
    }

    override func tearDown() async throws {
        _findAllJavaInstallations = originalFindAll
        _currentArch = originalArch
        _getDarwinMajorVersion = originalDarwin
        try await super.tearDown()
    }

    // MARK: - Helpers
    private func makeJava(
        major: Int, minor: Int = 0, security: Int = 0,
        arch: String = "arm64", vendor: String = "Vendor",
        name: String = "JDK", path: String = "/fake/java"
    ) -> JavaInstallation {
        JavaInstallation(
            versionStr: "\(major).\(minor).\(security)",
            version: JavaVersion(major: major, minor: minor, security: security),
            arch: arch,
            vendor: vendor,
            displayName: name,
            path: path
        )
    }

    private func mockSystem(
        javaList: [JavaInstallation],
        arch: String,
        darwin: Int
    ) async {
        _findAllJavaInstallations = { javaList }
        _currentArch = { arch }
        _getDarwinMajorVersion = { darwin }
    }

    // MARK: - Tests
    func testNoJavaInstalled() async throws {
        await mockSystem(javaList: [], arch: "x86_64", darwin: 23)

        do {
            _ = try selectJavaHome(minVersion: JavaVersion(major: 17))
            XCTFail("Expected noJavaInstalled error")
        } catch let e as JavaSelectionError {
            XCTAssertEqual(e.description, "No Java installation found.")
        }
    }

    func testSelectNativeJava() async throws {
        let java17 = makeJava(major: 17, path: "/fake/java17")
        await mockSystem(javaList: [java17], arch: "arm64", darwin: 23)

        let selected = try selectJavaHome(minVersion: JavaVersion(major: 17))
        switch selected {
        case .autoDetected(let path):
            XCTAssertEqual(path, java17.path)
        default:
            XCTFail("Expected autoDetected")
        }
    }

    func testSelectX86FallbackOnArm() async throws {
        let javaX86 = makeJava(major: 17, arch: "x86_64", path: "/fake/javaX86")
        await mockSystem(javaList: [javaX86], arch: "arm64", darwin: 23)

        let selected = try selectJavaHome(minVersion: JavaVersion(major: 17))
        switch selected {
        case .autoDetected(let path):
            XCTAssertEqual(path, javaX86.path)
        default:
            XCTFail("Expected autoDetected fallback to x86")
        }
    }

    func testNoArm64OnNewMacOS() async throws {
        let javaX86 = makeJava(major: 17, arch: "x86_64", path: "/fake/javaX86")
        await mockSystem(javaList: [javaX86], arch: "arm64", darwin: 26)

        do {
            _ = try selectJavaHome(minVersion: JavaVersion(major: 17))
            XCTFail("Expected noArm64OnNewMacOS error")
        } catch let e as JavaSelectionError {
            XCTAssertTrue(
                e.description.contains("Require ARM64 Java"),
                "Unexpected error: \(e)"
            )
        }
    }
}
