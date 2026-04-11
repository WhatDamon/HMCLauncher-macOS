import XCTest

@testable import HMCLauncher

final class JVMArgsParserTests: XCTestCase {
    // MARK: - Basic Parsing Tests
    func testParseSimpleArgs() {
        XCTAssertEqual(JVMArgsParser.parse(from: "-Xmx2G"), ["-Xmx2G"])
        XCTAssertEqual(JVMArgsParser.parse(from: "-Dfoo=bar"), ["-Dfoo=bar"])
        XCTAssertEqual(JVMArgsParser.parse(from: "-XX:+UseG1GC"), ["-XX:+UseG1GC"])
        XCTAssertEqual(JVMArgsParser.parse(from: "--add-modules"), ["--add-modules"])
    }

    func testParseMultipleArgs() {
        let result = JVMArgsParser.parse(from: "-Xmx2G -XX:+UseG1GC -Dfoo=bar")
        XCTAssertEqual(result.count, 3)
        XCTAssertTrue(result.contains("-Xmx2G"))
        XCTAssertTrue(result.contains("-XX:+UseG1GC"))
        XCTAssertTrue(result.contains("-Dfoo=bar"))
    }

    func testParseFiltersNonJVMEArgs() {
        let result = JVMArgsParser.parse(from: "-Xmx2G someAppArg -Dfoo=bar")
        XCTAssertEqual(result.count, 2)
        XCTAssertTrue(result.contains("-Xmx2G"))
        XCTAssertTrue(result.contains("-Dfoo=bar"))
    }

    func testParseEmptyString() {
        XCTAssertTrue(JVMArgsParser.parse(from: "").isEmpty)
    }

    func testParseNil() {
        XCTAssertTrue(JVMArgsParser.parse(from: nil).isEmpty)
    }

    func testParseFromArray() {
        let result = JVMArgsParser.parse(from: ["-Xmx2G", "-Dfoo=bar", "appArg"])
        XCTAssertEqual(result.count, 2)
    }

    // MARK: - Quoted String Tests (shell strips quotes)
    func testParseDoubleQuotedArg() {
        let result = JVMArgsParser.parse(from: "-Dmessage=\"Hello World\"")
        XCTAssertEqual(result, ["-Dmessage=Hello World"])
    }

    func testParseSingleQuotedArg() {
        let result = JVMArgsParser.parse(from: "-Dmessage='Hello World'")
        XCTAssertEqual(result, ["-Dmessage=Hello World"])
    }

    func testParseDoubleQuotedWithSpaces() {
        let result = JVMArgsParser.parse(from: "-Dfoo=\"bar baz\"")
        XCTAssertEqual(result, ["-Dfoo=bar baz"])
    }

    func testParseMultipleQuotedArgs() {
        let result = JVMArgsParser.parse(from: "-Dfoo=\"value one\" -Dbar='value two'")
        XCTAssertEqual(result.count, 2)
        XCTAssertTrue(result.contains("-Dfoo=value one"))
        XCTAssertTrue(result.contains("-Dbar=value two"))
    }

    // MARK: - Escape Character Tests
    func testParseEscapedCharacter() {
        let result = JVMArgsParser.parse(from: "-Dpath=C:\\\\Program\\\\Files\\\\Java")
        XCTAssertEqual(result, ["-Dpath=C:\\Program\\Files\\Java"])
    }

    func testParseEmptyQuotedString() {
        let result = JVMArgsParser.parse(from: "-Dfoo=\"\"")
        XCTAssertEqual(result, ["-Dfoo="])
    }

    // MARK: - Whitespace Handling Tests
    func testParseMultipleSpaces() {
        let result = JVMArgsParser.parse(from: "-Xmx2G    -XX:+UseG1GC")
        XCTAssertEqual(result.count, 2)
    }

    func testParseWithTabs() {
        let result = JVMArgsParser.parse(from: "-Xmx2G\t-Dfoo=bar")
        XCTAssertEqual(result.count, 2)
    }

    // MARK: - argKey Tests
    func testArgKeyD() {
        XCTAssertEqual(JVMArgsParser.argKey("-Dfoo=bar"), "-Dfoo")
        XCTAssertEqual(JVMArgsParser.argKey("-Dfoo"), "-Dfoo")
    }

    func testArgKeyXX() {
        XCTAssertEqual(JVMArgsParser.argKey("-XX:+UseG1GC"), "-XX:+UseG1GC")
    }

    func testArgKeyX() {
        XCTAssertEqual(JVMArgsParser.argKey("-Xmx2G"), "-Xmx")
        XCTAssertEqual(JVMArgsParser.argKey("-Xms512m"), "-Xms")
    }

    func testArgKeyOther() {
        XCTAssertEqual(JVMArgsParser.argKey("--add-modules"), "--add-modules")
    }

    // MARK: - Edge Cases
    func testParseMixedArgs() {
        let result = JVMArgsParser.parse(from: "-Xmx4G -Dname=\"John Doe\" -Dfoo=bar")
        XCTAssertEqual(result.count, 3)
        XCTAssertTrue(result.contains("-Xmx4G"))
        XCTAssertTrue(result.contains("-Dname=John Doe"))
        XCTAssertTrue(result.contains("-Dfoo=bar"))
    }

    func testParseJvmArgsWithEqualsInValue() {
        let result = JVMArgsParser.parse(from: "-Durl=http://example.com?foo=bar")
        XCTAssertEqual(result, ["-Durl=http://example.com?foo=bar"])
    }

    func testParseDquoteWithoutClosing() {
        let result = JVMArgsParser.parse(from: "-Dfoo=\"bar")
        XCTAssertEqual(result, ["-Dfoo=bar"])
    }

    func testParseNestedQuotes() {
        let result = JVMArgsParser.parse(from: "-Dmsg='He said \"hello\"'")
        XCTAssertEqual(result, ["-Dmsg=He said \"hello\""])
    }
}
