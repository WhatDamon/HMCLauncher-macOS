import XCTest

@testable import HMCLauncher

final class JVMArgsParserTests: XCTestCase {
    // MARK: - Basic Parsing Tests
    func testParseSimpleArgs() {
        XCTAssertEqual(parseJVMArgs(from: "-Xmx2G"), ["-Xmx2G"])
        XCTAssertEqual(parseJVMArgs(from: "-Dfoo=bar"), ["-Dfoo=bar"])
        XCTAssertEqual(parseJVMArgs(from: "-XX:+UseG1GC"), ["-XX:+UseG1GC"])
        XCTAssertEqual(parseJVMArgs(from: "--add-modules"), ["--add-modules"])
    }

    func testParseMultipleArgs() {
        let result = parseJVMArgs(from: "-Xmx2G -XX:+UseG1GC -Dfoo=bar")
        XCTAssertEqual(result.count, 3)
        XCTAssertTrue(result.contains("-Xmx2G"))
        XCTAssertTrue(result.contains("-XX:+UseG1GC"))
        XCTAssertTrue(result.contains("-Dfoo=bar"))
    }

    func testParseFiltersNonJVMEArgs() {
        let result = parseJVMArgs(from: "-Xmx2G someAppArg -Dfoo=bar")
        XCTAssertEqual(result.count, 2)
        XCTAssertTrue(result.contains("-Xmx2G"))
        XCTAssertTrue(result.contains("-Dfoo=bar"))
    }

    func testParseEmptyString() {
        XCTAssertTrue(parseJVMArgs(from: "").isEmpty)
    }

    func testParseNil() {
        XCTAssertTrue(parseJVMArgs(from: nil).isEmpty)
    }

    func testParseFromArray() {
        let result = parseJVMArgs(from: ["-Xmx2G", "-Dfoo=bar", "appArg"])
        XCTAssertEqual(result.count, 2)
    }

    // MARK: - Quoted String Tests (shell strips quotes)
    func testParseDoubleQuotedArg() {
        let result = parseJVMArgs(from: "-Dmessage=\"Hello World\"")
        XCTAssertEqual(result, ["-Dmessage=Hello World"])
    }

    func testParseSingleQuotedArg() {
        let result = parseJVMArgs(from: "-Dmessage='Hello World'")
        XCTAssertEqual(result, ["-Dmessage=Hello World"])
    }

    func testParseDoubleQuotedWithSpaces() {
        let result = parseJVMArgs(from: "-Dfoo=\"bar baz\"")
        XCTAssertEqual(result, ["-Dfoo=bar baz"])
    }

    func testParseMultipleQuotedArgs() {
        let result = parseJVMArgs(from: "-Dfoo=\"value one\" -Dbar='value two'")
        XCTAssertEqual(result.count, 2)
        XCTAssertTrue(result.contains("-Dfoo=value one"))
        XCTAssertTrue(result.contains("-Dbar=value two"))
    }

    // MARK: - Escape Character Tests
    func testParseEscapedCharacter() {
        let result = parseJVMArgs(from: "-Dpath=C:\\\\Program\\\\Files\\\\Java")
        XCTAssertEqual(result, ["-Dpath=C:\\Program\\Files\\Java"])
    }

    func testParseEmptyQuotedString() {
        let result = parseJVMArgs(from: "-Dfoo=\"\"")
        XCTAssertEqual(result, ["-Dfoo="])
    }

    // MARK: - Whitespace Handling Tests
    func testParseMultipleSpaces() {
        let result = parseJVMArgs(from: "-Xmx2G    -XX:+UseG1GC")
        XCTAssertEqual(result.count, 2)
    }

    func testParseWithTabs() {
        let result = parseJVMArgs(from: "-Xmx2G\t-Dfoo=bar")
        XCTAssertEqual(result.count, 2)
    }

    // MARK: - jvmArgKey Tests
    func testJvmArgKeyD() {
        XCTAssertEqual(jvmArgKey("-Dfoo=bar"), "-Dfoo")
        XCTAssertEqual(jvmArgKey("-Dfoo"), "-Dfoo")
    }

    func testJvmArgKeyXX() {
        XCTAssertEqual(jvmArgKey("-XX:+UseG1GC"), "-XX:+UseG1GC")
    }

    func testJvmArgKeyX() {
        XCTAssertEqual(jvmArgKey("-Xmx2G"), "-Xmx")
        XCTAssertEqual(jvmArgKey("-Xms512m"), "-Xms")
    }

    func testJvmArgKeyOther() {
        XCTAssertEqual(jvmArgKey("--add-modules"), "--add-modules")
    }

    // MARK: - Edge Cases
    func testParseMixedArgs() {
        let result = parseJVMArgs(from: "-Xmx4G -Dname=\"John Doe\" -Dfoo=bar")
        XCTAssertEqual(result.count, 3)
        XCTAssertTrue(result.contains("-Xmx4G"))
        XCTAssertTrue(result.contains("-Dname=John Doe"))
        XCTAssertTrue(result.contains("-Dfoo=bar"))
    }

    func testParseJvmArgsWithEqualsInValue() {
        let result = parseJVMArgs(from: "-Durl=http://example.com?foo=bar")
        XCTAssertEqual(result, ["-Durl=http://example.com?foo=bar"])
    }

    func testParseDquoteWithoutClosing() {
        let result = parseJVMArgs(from: "-Dfoo=\"bar")
        XCTAssertEqual(result, ["-Dfoo=bar"])
    }

    func testParseNestedQuotes() {
        let result = parseJVMArgs(from: "-Dmsg='He said \"hello\"'")
        XCTAssertEqual(result, ["-Dmsg=He said \"hello\""])
    }
}
