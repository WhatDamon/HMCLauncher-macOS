import XCTest

@testable import HMCLauncher

@MainActor
final class JavaLocatorTests: XCTestCase {
    // MARK: - Helper to make JavaInstallation
    private func makeJava(
        major: Int, minor: Int = 0, security: Int = 0,
        arch: String = "arm64", path: String = "/fake/java"
    ) -> JavaInstallation {
        JavaInstallation(
            versionStr: "\(major).\(minor).\(security)",
            version: JavaVersion(major: major, minor: minor, security: security),
            arch: arch,
            path: path
        )
    }

    // MARK: - Test: No Java installed
    func testNoJavaInstalled() {
        _findAllJavaInstallations = { [] }
        _currentArch = { "x86_64" }
        _getDarwinMajorVersion = { 23 }

        do {
            let _ = try selectJavaHome(minVersion: JavaVersion(major: 17))
            XCTFail("Expected noJavaInstalled error")
        } catch let e as JavaSelectionError {
            XCTAssertEqual(e.description, "No Java installation found.")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: - Test: Select native Java
    func testSelectNativeJava() {
        let java17 = makeJava(major: 17, path: "/fake/java17")
        _findAllJavaInstallations = { [java17] }
        _currentArch = { "arm64" }
        _getDarwinMajorVersion = { 23 }

        do {
            let selected = try selectJavaHome(minVersion: JavaVersion(major: 17))
            switch selected {
            case .autoDetected(let path):
                XCTAssertEqual(path, java17.path)
            default:
                XCTFail("Expected autoDetected")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: - Test: Fallback to x86 on arm64 macOS <26
    func testSelectX86FallbackOnArm() {
        let javaX86 = makeJava(major: 17, arch: "x86_64", path: "/fake/javaX86")
        _findAllJavaInstallations = { [javaX86] }
        _currentArch = { "arm64" }
        _getDarwinMajorVersion = { 23 }

        do {
            let selected = try selectJavaHome(minVersion: JavaVersion(major: 17))
            switch selected {
            case .autoDetected(let path):
                XCTAssertEqual(path, javaX86.path)
            default:
                XCTFail("Expected autoDetected fallback to x86")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: - Test: No ARM64 Java on macOS 27+
    func testNoArm64OnNewMacOS() {
        let javaX86 = makeJava(major: 17, arch: "x86_64", path: "/fake/javaX86")
        _findAllJavaInstallations = { [javaX86] }
        _currentArch = { "arm64" }
        _getDarwinMajorVersion = { 27 }

        do {
            let _ = try selectJavaHome(minVersion: JavaVersion(major: 17))
            XCTFail("Expected noArm64OnNewMacOS error")
        } catch let e as JavaSelectionError {
            XCTAssertTrue(
                e.description.contains("Require ARM64"),
                "Unexpected error: \(e)"
            )
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}
