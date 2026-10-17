import Foundation

public struct ProcessError: Error, CustomStringConvertible {
    public let message: String

    public init(_ message: String) {
        self.message = message
    }

    public var description: String { message }
}

public struct ProcessResult: Sendable {
    public let terminationStatus: Int32
    public let outputData: Data
    public let errorData: Data

    public var output: String? { String(data: outputData, encoding: .utf8) }
    public var error: String? { String(data: errorData, encoding: .utf8) }
    public var isSuccess: Bool { terminationStatus == 0 }
}

private final class DataHolder: @unchecked Sendable {
    var data: Data
    init() { self.data = Data() }
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

        let outputHolder = DataHolder()
        let errorHolder = DataHolder()
        let group = DispatchGroup()
        let queue = DispatchQueue(label: "com.hmcl.processreader")

        try process.run()

        group.enter()
        queue.async {
            outputHolder.data = outputPipe.fileHandleForReading.readDataToEndOfFile()
            group.leave()
        }

        group.enter()
        queue.async {
            errorHolder.data = errorPipe.fileHandleForReading.readDataToEndOfFile()
            group.leave()
        }

        process.waitUntilExit()
        group.wait()

        return ProcessResult(
            terminationStatus: process.terminationStatus,
            outputData: outputHolder.data,
            errorData: errorHolder.data
        )
    }

    public func runOutput() throws -> String {
        try run().output ?? ""
    }
}

extension ProcessRunner {
    public static func javaHome(arguments: [String] = []) throws -> ProcessResult {
        try ProcessRunner(executableURL: URL(fileURLWithPath: "/usr/libexec/java_home"))
            .withArguments(arguments).run()
    }

    public static func openURL(_ urlString: String) throws {
        _ = try ProcessRunner(executableURL: URL(fileURLWithPath: "/usr/bin/open"))
            .withArguments([urlString]).run()
    }

    public static func runAppleScript(_ script: String, directory: URL? = nil) throws -> String {
        let runner = ProcessRunner(executableURL: URL(fileURLWithPath: "/usr/bin/osascript"))
            .withArguments(["-e", script])
        if let dir = directory { runner.inDirectory(dir) }
        return try runner.runOutput()
    }

    public static func runJar(
        jarPath: URL,
        javaHome: String,
        jvmArgs: [String] = [],
        appArgs: [String] = [],
        environment: [String: String]? = nil
    ) throws -> ProcessResult {
        let javaExec = URL(fileURLWithPath: javaHome)
            .appendingPathComponent("bin/java")

        guard FileUtils.isExecutable(javaExec.path) else {
            throw ProcessError("Java executable not found: \(javaExec.path)")
        }

        var env = environment ?? ProcessInfo.processInfo.environment
        env["JAVA_HOME"] = javaHome

        var arguments = jvmArgs
        arguments.append("-jar")
        arguments.append(jarPath.path)
        arguments.append(contentsOf: appArgs)

        return try ProcessRunner(executableURL: javaExec)
            .withArguments(arguments)
            .withEnvironment(env)
            .run()
    }
}