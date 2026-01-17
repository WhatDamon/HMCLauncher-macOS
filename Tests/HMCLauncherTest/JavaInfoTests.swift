import XCTest

@testable import HMCLauncher

@MainActor
final class JavaInfoTests: XCTestCase {
    // Helper to create JavaInstallation safely
    private func makeJava(dict: [String: Any]) -> JavaInstallation {
        return try! XCTUnwrap(JavaInstallation(dict: dict))
    }

    // MARK: - JavaInstallation Tests
    func testJavaInstallationInit() {
        let dict: [String: Any] = [
            "JVMEnabled": true,
            "JVMVersion": "17.0.17",
            "JVMArch": "arm64",
            "JVMVendor": "Microsoft",
            "JVMName": "Microsoft JDK 17",
            "JVMHomePath": "/Library/Java/JavaVirtualMachines/microsoft-17.jdk/Contents/Home",
        ]
        let java = makeJava(dict: dict)

        XCTAssertEqual(java.versionStr, "17.0.17")
        XCTAssertEqual(java.arch, "arm64")
        XCTAssertEqual(java.vendor, "Microsoft")
        XCTAssertEqual(java.displayName, "Microsoft JDK 17")
        XCTAssertEqual(java.path, dict["JVMHomePath"] as? String)
        XCTAssertTrue(java.isArm64)
        XCTAssertEqual(java.version.major, 17)
        XCTAssertEqual(java.version.minor, 0)
        XCTAssertEqual(java.version.security, 17)
    }

    func testJavaInstallationInitFails() {
        let invalidDicts: [[String: Any]] = [
            [
                "JVMEnabled": false, "JVMVersion": "17.0.17", "JVMArch": "arm64",
                "JVMVendor": "Microsoft", "JVMName": "Microsoft JDK 17", "JVMHomePath": "/path",
            ],
            [
                "JVMEnabled": true, "JVMVersion": "17.0.17", "JVMArch": "arm64",
                "JVMVendor": "Microsoft", "JVMName": "Microsoft JDK 17",
            ],  // Missing path
        ]

        invalidDicts.forEach { dict in
            XCTAssertNil(JavaInstallation(dict: dict))
        }
    }

    // MARK: - JavaVersion Tests
    func testJavaVersionParsing() {
        let versions = [
            ("17", 17, 0, 0),
            ("1.8.0_462", 8, 0, 462),
            ("21.0.7", 21, 0, 7),
        ]

        versions.forEach { str, major, minor, sec in
            let v = try! XCTUnwrap(JavaVersion(from: str))
            XCTAssertEqual(v.major, major)
            XCTAssertEqual(v.minor, minor)
            XCTAssertEqual(v.security, sec)
        }
    }

    func testJavaVersionComparison() {
        let v8 = makeJavaVersion("1.8.0_51")
        let v17 = makeJavaVersion("17")
        let v17_1 = makeJavaVersion("17.0.1")
        let v18 = makeJavaVersion("18.0.1")

        XCTAssertTrue(v8 < v17)
        XCTAssertTrue(v17 < v18)
        XCTAssertTrue(v17 < v17_1)
        XCTAssertTrue(v17_1 < v18)
        XCTAssertTrue(v18 > v17_1)
        XCTAssertEqual(v17, JavaVersion(major: 17))
    }

    private func makeJavaVersion(_ str: String) -> JavaVersion {
        return try! XCTUnwrap(JavaVersion(from: str))
    }

    // MARK: - Array Helpers Tests
    func testFilteringAndSorting() {
        let javaList = [
            makeJava(dict: [
                "JVMEnabled": true, "JVMVersion": "17.0.17", "JVMArch": "arm64",
                "JVMVendor": "Microsoft", "JVMName": "Microsoft JDK 17", "JVMHomePath": "/path1",
            ]),
            makeJava(dict: [
                "JVMEnabled": true, "JVMVersion": "21.0.7", "JVMArch": "arm64", "JVMVendor": "Zulu",
                "JVMName": "Zulu JDK 21", "JVMHomePath": "/path2",
            ]),
            makeJava(dict: [
                "JVMEnabled": true, "JVMVersion": "18.0.2", "JVMArch": "x86_64",
                "JVMVendor": "Oracle", "JVMName": "Oracle JDK 18", "JVMHomePath": "/path3",
            ]),
            makeJava(dict: [
                "JVMEnabled": true, "JVMVersion": "1.8.0_462", "JVMArch": "x86_64",
                "JVMVendor": "Eclipse Temurin", "JVMName": "Eclipse Temurin 8", "JVMHomePath": "/path4",
            ]),
        ]

        let sorted = javaList.sortedByVersionDescending()
        XCTAssertEqual(sorted.map { $0.version.major }, [21, 18, 17, 8])

        let filteredMin18 = javaList.filtered(byMinVersion: JavaVersion(major: 18))
        XCTAssertEqual(filteredMin18.map { $0.version.major }, [21, 18])

        let filteredArm64 = javaList.filtered(byArch: "arm64")
        XCTAssertEqual(filteredArm64.map { $0.arch }, ["arm64", "arm64"])
    }
}
