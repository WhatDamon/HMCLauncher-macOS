import XCTest

@testable import HMCLauncher

@MainActor
final class SystemUtilTests: XCTestCase {
    // MARK: - SystemUtil Tests
    func testCurrentArch() throws {
        let arch = SystemUtils.currentArch()
        XCTAssertTrue(arch == "arm64" || arch == "x86_64")
    }

    func testDarwinMajorVersion() throws {
        let darwin = SystemUtils.getDarwinMajorVersion()
        XCTAssertGreaterThan(darwin, 0)
    }

    func testMacOSVersionMapping() throws {
        XCTAssertEqual(SystemUtils.macOSVersionString(fromDarwin: 19), "10.15")
        XCTAssertEqual(SystemUtils.macOSVersionString(fromDarwin: 20), "11")
        XCTAssertEqual(SystemUtils.macOSVersionString(fromDarwin: 24), "15")
        XCTAssertEqual(SystemUtils.macOSVersionString(fromDarwin: 25), "26")
        XCTAssertEqual(SystemUtils.macOSVersionString(fromDarwin: 26), "27")
        XCTAssertEqual(SystemUtils.macOSVersionString(fromDarwin: 30), "31")
    }

    func testUnsupportedOldDarwinVersion() throws {
        let version = SystemUtils.macOSVersionString(fromDarwin: 18)
        XCTAssertEqual(version, "unsupported")
    }
}
