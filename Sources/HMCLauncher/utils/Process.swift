import Foundation

// MARK: - Process Result
public struct ProcessResult: Sendable {
    public let terminationStatus: Int32
    public let outputData: Data
    public let errorData: Data

    public var output: String? {
        String(data: outputData, encoding: .utf8)
    }

    public var error: String? {
        String(data: errorData, encoding: .utf8)
    }

    public var isSuccess: Bool {
        terminationStatus == 0
    }
}

// MARK: - Process Runner
public final class ProcessRunner {
    public let executable: URL
    public var arguments: [String] = []
    public var workingDirectory: URL?
    public var environment: [String: String]? = nil

    private let outputPipe = Pipe()
    private let errorPipe = Pipe()

    public init(executable: String) {
        self.executable = URL(fileURLWithPath: executable)
    }

    public init(executableURL: URL) {
        self.executable = executableURL
    }

    // MARK: - Set arguments
    public func withArguments(_ args: [String]) -> Self {
        arguments = args
        return self
    }

    // MARK: - Set working directory
    public func inDirectory(_ directory: URL) -> Self {
        workingDirectory = directory
        return self
    }

    // MARK: - Set environment
    public func withEnvironment(_ env: [String: String]) -> Self {
        environment = env
        return self
    }

    // MARK: - Run synchronously and return result
    public func run() throws -> ProcessResult {
        let process = Process()
        defer { process.terminate() }

        process.executableURL = executable
        process.arguments = arguments
        process.currentDirectoryURL = workingDirectory
        process.environment = environment ?? ProcessInfo.processInfo.environment

        process.standardOutput = outputPipe
        process.standardError = errorPipe

        try process.run()
        process.waitUntilExit()

        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()

        return ProcessResult(
            terminationStatus: process.terminationStatus,
            outputData: outputData,
            errorData: errorData
        )
    }

    // MARK: - Run and return output only (ignoring errors)
    public func runOutput() throws -> String {
        let result = try run()
        return result.output ?? ""
    }

    // MARK: - Run and check success
    public func runSuccessfully() throws {
        let result = try run()
        guard result.isSuccess else {
            throw ProcessError.nonZeroExit(
                status: result.terminationStatus,
                output: result.output ?? "",
                error: result.error ?? ""
            )
        }
    }
}

// MARK: - Process Error
public enum ProcessError: Error, CustomStringConvertible {
    case nonZeroExit(status: Int32, output: String, error: String)
    case executionFailed(String)

    public var description: String {
        switch self {
        case .nonZeroExit(let status, let output, let error):
            var msg = "Process exited with status \(status)"
            if !output.isEmpty {
                msg += ", output: \(output)"
            }
            if !error.isEmpty {
                msg += ", error: \(error)"
            }
            return msg
        case .executionFailed(let reason):
            return "Process execution failed: \(reason)"
        }
    }
}

// MARK: - Convenience Functions
public extension ProcessRunner {
    // MARK: - Run java_home
    static func javaHome(arguments: [String] = []) throws -> ProcessResult {
        try ProcessRunner(executableURL: URL(fileURLWithPath: "/usr/libexec/java_home"))
            .withArguments(arguments)
            .run()
    }

    // MARK: - Open URL in browser
    static func openURL(_ urlString: String) throws {
        try ProcessRunner(executableURL: URL(fileURLWithPath: "/usr/bin/open"))
            .withArguments([urlString])
            .runSuccessfully()
    }

    // MARK: - Run AppleScript
    static func runAppleScript(_ script: String, directory: URL? = nil) throws -> String {
        let runner = ProcessRunner(executableURL: URL(fileURLWithPath: "/usr/bin/osascript"))
            .withArguments(["-e", script])
        
        if let dir = directory {
            _ = runner.inDirectory(dir)
        }
        
        return try runner.runOutput()
    }
}
