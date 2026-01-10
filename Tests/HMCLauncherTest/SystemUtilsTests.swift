import XCTest

@testable import HMCLauncher

final class SystemUtilTests: XCTestCase {
    // MARK: - SystemUtil Tests
    func testCurrentArch() throws {
        let arch = currentArch()
        XCTAssertTrue(arch == "arm64" || arch == "x86_64")
    }

    func testDarwinMajorVersion() throws {
        let darwin = getDarwinMajorVersion()
        XCTAssertGreaterThan(darwin, 0)
    }

    func testMacOSVersionMapping() throws {
        XCTAssertEqual(macOSVersionString(fromDarwin: 19), "10.15")
        XCTAssertEqual(macOSVersionString(fromDarwin: 20), "11")
        XCTAssertEqual(macOSVersionString(fromDarwin: 24), "15")
        XCTAssertEqual(macOSVersionString(fromDarwin: 25), "26")
        XCTAssertEqual(macOSVersionString(fromDarwin: 26), "27")
        XCTAssertEqual(macOSVersionString(fromDarwin: 30), "31")
    }

    func testUnsupportedOldDarwinVersion() throws {
        let version = macOSVersionString(fromDarwin: 18)
        XCTAssertEqual(version, "unsupported")
    }
}
