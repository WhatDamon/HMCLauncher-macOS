import Foundation

// MARK: - Hooks for testing
@MainActor var _findAllJavaInstallations: () -> [JavaInstallation] = findAllJavaInstallations
@MainActor var _currentArch: () -> String = currentArch
@MainActor var _getDarwinMajorVersion: () -> Int = getDarwinMajorVersion

// MARK: - Enum: JavaHome Source
enum JavaHomeSource {
    case environment(path: String)
    case autoDetected(path: String)
}

// MARK: - Enum: Errors
enum JavaSelectionError: Error, CustomStringConvertible {
    case invalidJavaHome
    case userSpecifiedJavaVersionTooLow(
        path: String, detectedVersion: String, required: JavaVersion)
    case noJavaInstalled
    case newestTooLow(found: JavaInstallation, required: JavaVersion)
    case noCompatibleJava(arch: String, minVer: JavaVersion, all: [JavaInstallation])
    case noArm64OnNewMacOS(darwin: Int, minVer: JavaVersion, arm64List: [JavaInstallation])

    var description: String {
        switch self {
        case .invalidJavaHome:
            return "Invalid JAVA_HOME."
        case .userSpecifiedJavaVersionTooLow(_, let detectedVersion, let required):
            return "Java \(detectedVersion) is lower than required \(required)."
        case .noJavaInstalled:
            return "No Java installation found."
        case .newestTooLow(let found, let required):
            return "Newest Java \(found.version) is lower than required \(required)."
        case .noCompatibleJava(let arch, let minVer, _):
            return "No Java \(minVer)+ found for \(arch)."
        case .noArm64OnNewMacOS(let darwin, let minVer, _):
            return "Require ARM64 Java \(minVer)+ on Darwin \(darwin)."
        }
    }
}

// MARK: - Function: Version Extraction
private func extractJavaVersion(from output: String) -> String? {
    let version =
        output
        .split(separator: "\n")
        .first { $0.contains("version") }?
        .split(separator: "\"")
        .dropFirst()
        .first
        .map(String.init)

    if let v = version {
        DebugLogger.log("Extracted Java version string: \(v)", level: .debug)
    } else {
        DebugLogger.log("Failed to extract Java version from output", level: .warn)
    }

    return version
}

// MARK: - Function: JAVA_HOME Validation
private func findJavaExecutable(in base: String) -> String? {
    let fm = FileManager.default
    let candidates = [
        "bin/java",
        "Contents/Home/bin/java",
        "Home/bin/java",
    ].map { (base as NSString).appendingPathComponent($0) }

    let executable = candidates.first { fm.isExecutableFile(atPath: $0) }

    if let exe = executable {
        DebugLogger.log("Found Java executable at \(exe)", level: .debug)
    } else {
        DebugLogger.log("No Java executable found in \(base)", level: .warn)
    }

    return executable
}

// MARK: - Function: Validate Java at Path
func validateJavaAtPath(
    _ basePath: String,
    minVersion: JavaVersion
) throws -> JavaHomeSource {

    DebugLogger.log("Validating JAVA_HOME at: \(basePath)", level: .info)

    guard let java = findJavaExecutable(in: basePath) else {
        DebugLogger.log("Validation failed: JAVA_HOME missing executable", level: .warn)
        throw JavaSelectionError.invalidJavaHome
    }

    let p = Process()
    let pipe = Pipe()
    p.executableURL = URL(fileURLWithPath: java)
    p.arguments = ["-version"]
    p.standardError = pipe

    do {
        DebugLogger.log("Running '\(java) -version'", level: .debug)
        try p.run()
        p.waitUntilExit()

        guard p.terminationStatus == 0 else {
            DebugLogger.log("Process terminated with status \(p.terminationStatus)", level: .warn)
            throw JavaSelectionError.invalidJavaHome
        }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard
            let out = String(data: data, encoding: .utf8),
            let verStr = extractJavaVersion(from: out),
            let ver = JavaVersion(from: verStr)
        else {
            DebugLogger.log("Failed to parse Java version from output", level: .warn)
            throw JavaSelectionError.invalidJavaHome
        }

        DebugLogger.log("Detected Java version \(ver) at \(basePath)", level: .info)

        guard ver >= minVersion else {
            DebugLogger.log(
                "Detected version \(ver) < required \(minVersion)", level: .warn
            )
            throw JavaSelectionError.userSpecifiedJavaVersionTooLow(
                path: basePath,
                detectedVersion: verStr,
                required: minVersion
            )
        }

        DebugLogger.log("JAVA_HOME validated successfully: \(basePath)", level: .info)
        return .environment(path: basePath)

    } catch let e as JavaSelectionError {
        throw e
    } catch {
        DebugLogger.log("Error while validating JAVA_HOME: \(error)", level: .error)
        throw JavaSelectionError.invalidJavaHome
    }
}

// MARK: - Function: Java Selection
@MainActor
func selectJavaHome(
    minVersion: JavaVersion = JavaVersion(from: "\(LauncherEnv.HMCL_EXPECTED_JAVA_MAJOR_VERSION)")!
) throws -> JavaHomeSource {

    DebugLogger.log("Selecting JavaHome with minimum version \(minVersion)", level: .info)

    if let path = LauncherEnv.ENV["HMCL_JAVA_HOME"],
        !path.trimmingCharacters(in: .whitespaces).isEmpty
    {
        DebugLogger.log("HMCL_JAVA_HOME environment variable found: \(path)", level: .debug)
        return try validateJavaAtPath(path, minVersion: minVersion)
    }

    let all = _findAllJavaInstallations()
    DebugLogger.log("Found \(all.count) Java installations", level: .info)
    guard !all.isEmpty else {
        DebugLogger.log("No Java installations available", level: .warn)
        throw JavaSelectionError.noJavaInstalled
    }

    guard let newest = all.sortedByVersionDescending().first,
        newest.version >= minVersion
    else {
        DebugLogger.log(
            "Newest Java version (\(all.first?.versionStr ?? "unknown")) < required \(minVersion)",
            level: .warn
        )
        throw JavaSelectionError.newestTooLow(found: all.first!, required: minVersion)
    }

    let arch = _currentArch()
    let darwin = _getDarwinMajorVersion()
    let allowX86 =
        arch.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) == "arm64" && darwin < 26

    let candidates = all.filtered(byMinVersion: minVersion)
    DebugLogger.log("Filtered \(candidates.count) candidates >= min version", level: .debug)

    if let native = candidates.filtered(byArch: arch).sortedByVersionDescending().first {
        DebugLogger.log(
            "Selected native Java (\(native.versionStr)) for arch \(arch)", level: .info)
        return .autoDetected(path: native.path)
    }

    if allowX86,
        let x86 = candidates.filtered(byArch: "x86_64").sortedByVersionDescending().first
    {
        DebugLogger.log(
            "Falling back to x86_64 Java (\(x86.versionStr)) on arm64 macOS <26", level: .info)
        return .autoDetected(path: x86.path)
    }

    if arch == "arm64" && !allowX86 {
        let arm64List = candidates.filtered(byArch: "arm64")
        DebugLogger.log(
            "No arm64 Java available on macOS \(darwin), candidates: \(arm64List.map { $0.versionStr })",
            level: .warn)
        throw JavaSelectionError.noArm64OnNewMacOS(
            darwin: darwin,
            minVer: minVersion,
            arm64List: arm64List
        )
    }

    DebugLogger.log(
        "No compatible Java found for arch \(arch) with min version \(minVersion)", level: .warn)
    throw JavaSelectionError.noCompatibleJava(
        arch: arch,
        minVer: minVersion,
        all: all
    )
}
