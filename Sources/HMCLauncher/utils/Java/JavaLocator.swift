import Foundation

// MARK: - Hooks for testing
@MainActor var _findAllJavaInstallations: () -> [JavaInstallation] = findAllJavaInstallations
@MainActor var _currentArch: () -> String = SystemUtils.currentArch
@MainActor var _getDarwinMajorVersion: () -> Int = SystemUtils.getDarwinMajorVersion

// MARK: - Enum: JavaHome Source
public enum JavaHomeSource: Sendable {
    case environment(path: String)
    case autoDetected(path: String)
}

// MARK: - Enum: Errors
public enum JavaSelectionError: Error, CustomStringConvertible {
    case invalidJavaHome
    case userSpecifiedJavaVersionTooLow(path: String, detectedVersion: String, required: JavaVersion)
    case noJavaInstalled
    case newestTooLow(found: JavaInstallation, required: JavaVersion)
    case noCompatibleJava(arch: String, minVer: JavaVersion)
    case noArm64OnNewMacOS(darwin: Int, minVer: JavaVersion)

    public var description: String {
        switch self {
        case .invalidJavaHome: return "Invalid JAVA_HOME."
        case .userSpecifiedJavaVersionTooLow(_, let detected, let required):
            return "Java \(detected) < required \(required)."
        case .noJavaInstalled: return "No Java installation found."
        case .newestTooLow(let found, let required):
            return "Java \(found.version) < required \(required)."
        case .noCompatibleJava(let arch, let minVer):
            return "No \(minVer)+ found for \(arch)."
        case .noArm64OnNewMacOS(let darwin, let minVer):
            return "Require ARM64 \(minVer)+ on macOS \(darwin)."
        }
    }
}

// MARK: - Validate Java at Path
public func validateJavaAtPath(_ basePath: String, minVersion: JavaVersion) throws -> JavaHomeSource {
    guard let java = AppPath.findJavaExecutable(base: basePath) else {
        throw JavaSelectionError.invalidJavaHome
    }

    let result = try ProcessRunner(executableURL: URL(fileURLWithPath: java))
        .withArguments(["-version"])
        .run()

    guard result.isSuccess else { throw JavaSelectionError.invalidJavaHome }

    let versionString = result.error?
        .split(separator: "\n")
        .first { $0.contains("version") }?
        .split(separator: "\"")
        .dropFirst()
        .first
        .map(String.init)

    guard let verStr = versionString, let ver = JavaVersion(from: verStr) else {
        throw JavaSelectionError.invalidJavaHome
    }

    guard ver >= minVersion else {
        throw JavaSelectionError.userSpecifiedJavaVersionTooLow(
            path: basePath, detectedVersion: verStr, required: minVersion
        )
    }

    return .environment(path: basePath)
}

// MARK: - Select Java Home
@MainActor
public func selectJavaHome(
    minVersion: JavaVersion = JavaVersion(from: "\(LauncherEnv.HMCL_EXPECTED_JAVA_MAJOR_VERSION)") 
        ?? JavaVersion(major: LauncherEnv.HMCL_EXPECTED_JAVA_MAJOR_VERSION)
) throws -> JavaHomeSource {

    if let path = LauncherEnv.ENV["HMCL_JAVA_HOME"], !path.trimmingCharacters(in: .whitespaces).isEmpty {
        return try validateJavaAtPath(path, minVersion: minVersion)
    }

    let all = _findAllJavaInstallations()
    guard !all.isEmpty else { throw JavaSelectionError.noJavaInstalled }
    guard let newest = all.sortedByVersionDescending().first, newest.version >= minVersion else {
        throw JavaSelectionError.newestTooLow(found: all.first!, required: minVersion)
    }

    let arch = _currentArch()
    let darwin = _getDarwinMajorVersion()
    let allowX86 = arch == "arm64" && darwin < 27

    let candidates = all.filtered(byMinVersion: minVersion)

    if let native = candidates.filtered(byArch: arch).sortedByVersionDescending().first {
        return .autoDetected(path: native.path)
    }

    if allowX86, let x86 = candidates.filtered(byArch: "x86_64").sortedByVersionDescending().first {
        return .autoDetected(path: x86.path)
    }

    if arch == "arm64" && !allowX86 {
        throw JavaSelectionError.noArm64OnNewMacOS(darwin: darwin, minVer: minVersion)
    }

    throw JavaSelectionError.noCompatibleJava(arch: arch, minVer: minVersion)
}
