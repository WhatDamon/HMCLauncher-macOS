import Foundation

public struct ProcessResult: Sendable {
    public let terminationStatus: Int32
    public let outputData: Data
    public let errorData: Data

    public var output: String? { String(data: outputData, encoding: .utf8) }
    public var error: String? { String(data: errorData, encoding: .utf8) }
    public var isSuccess: Bool { terminationStatus == 0 }
}

public final class ProcessRunner {
    public let executable: URL
    public var arguments: [String] = []
    public var workingDirectory: URL?
    public var environment: [String: String]?

    public init(executable: String) {
        self.executable = URL(fileURLWithPath: executable)
    }

    public init(executableURL: URL) {
        self.executable = executableURL
    }

    @discardableResult
    public func withArguments(_ args: [String]) -> Self {
        arguments = args
        return self
    }

    @discardableResult
    public func inDirectory(_ directory: URL) -> Self {
        workingDirectory = directory
        return self
    }

    @discardableResult
    public func withEnvironment(_ env: [String: String]) -> Self {
        environment = env
        return self
    }

    public func run() throws -> ProcessResult {
        let process = Process()
        defer { process.terminate() }

        process.executableURL = executable
        process.arguments = arguments
        process.currentDirectoryURL = workingDirectory
        process.environment = environment ?? ProcessInfo.processInfo.environment

        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        try process.run()
        process.waitUntilExit()

        return ProcessResult(
            terminationStatus: process.terminationStatus,
            outputData: outputPipe.fileHandleForReading.readDataToEndOfFile(),
            errorData: errorPipe.fileHandleForReading.readDataToEndOfFile()
        )
    }

    public func runOutput() throws -> String {
        try run().output ?? ""
    }
}

public extension ProcessRunner {
    static func javaHome(arguments: [String] = []) throws -> ProcessResult {
        try ProcessRunner(executableURL: URL(fileURLWithPath: "/usr/libexec/java_home"))
            .withArguments(arguments).run()
    }

    static func openURL(_ urlString: String) throws {
        _ = try ProcessRunner(executableURL: URL(fileURLWithPath: "/usr/bin/open"))
            .withArguments([urlString]).run()
    }

    static func runAppleScript(_ script: String, directory: URL? = nil) throws -> String {
        let runner = ProcessRunner(executableURL: URL(fileURLWithPath: "/usr/bin/osascript"))
            .withArguments(["-e", script])
        if let dir = directory { runner.inDirectory(dir) }
        return try runner.runOutput()
    }
}
