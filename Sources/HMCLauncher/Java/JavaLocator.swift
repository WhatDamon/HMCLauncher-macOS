import Foundation

// MARK: - JavaHome Source
enum JavaHomeSource {
    case environment(path: String)
    case autoDetected(path: String)
}

// MARK: - Custom Errors
enum JavaSelectionError: Error, CustomStringConvertible {
    case invalidJavaHome(reason: String)
    case userSpecifiedJavaVersionTooLow(
        path: String, detectedVersion: String, required: JavaVersion)
    case noJavaInstalled
    case newestTooLow(found: JavaInstallation, required: JavaVersion)
    case noCompatibleJava(arch: String, minVer: JavaVersion, all: [JavaInstallation])
    case noArm64OnNewMacOS(darwin: Int, minVer: JavaVersion, arm64List: [JavaInstallation])

    var description: String {
        switch self {
        case .invalidJavaHome(let reason):
            return "The specified JAVA_HOME is invalid: \(reason)"
        case .userSpecifiedJavaVersionTooLow(let path, let ver, let req):
            return "The specified Java version is low: \(ver) < \(req)(Path: \(path))"
        case .noJavaInstalled:
            return "No Java found."
        case .newestTooLow(let f, let r):
            return
                "The newest installed Java (\(f.versionStr)) is lower than requirement: Java \(r)）"
        case .noCompatibleJava(let arch, let min, let all):
            _ = all.map { "- \($0.versionStr) (\($0.arch)) @ \($0.path)" }.joined(
                separator: "\n  ")
            return
                "No compatiable Java >= \(min) \(arch) build found"
        case .noArm64OnNewMacOS(let d, let min, let arm64s):
            _ =
                arm64s.isEmpty
                ? "(EMPTY)"
                : arm64s.map { "- \($0.versionStr) @ \($0.path)" }.joined(separator: "\n  ")
            return
                "Rosetta 2 has been desperated in Darwin \(d), please use >= Java \(min) arm64 build"
        }
    }
}

// MARK: - Utility: Extract Java Version
func extractVersion(fromJavaVersionOutput output: String) -> String? {
    let lines = output.split(separator: "\n")
    for line in lines {
        let s = String(line)
        if s.contains("version") {
            let components = s.components(separatedBy: "\"")
            if components.count >= 2 {
                return components[1]
            }
        }
    }
    return nil
}

// MARK: - Verify the user-specified JAVA_HOME
func findJavaExecutable(in basePath: String) -> String? {
    let fm = FileManager.default
    let candidates = [
        (basePath as NSString).appendingPathComponent("bin/java"),
        (basePath as NSString).appendingPathComponent("Contents/Home/bin/java"),
        (basePath as NSString).appendingPathComponent("Home/bin/java")
    ]
    
    for path in candidates {
        if fm.fileExists(atPath: path) && fm.isExecutableFile(atPath: path) {
            return path
        }
    }
    return nil
}

func validateJavaAtPath(_ basePath: String, minVersion: JavaVersion) throws -> JavaHomeSource {
    guard let javaExec = findJavaExecutable(in: basePath) else {
        throw JavaSelectionError.invalidJavaHome(reason: "Cannot find JAVA_HOME at \(basePath)")
    }

    let task = Process(), pipe = Pipe()
    task.executableURL = URL(fileURLWithPath: javaExec)
    task.arguments = ["-version"]
    task.standardOutput = nil
    task.standardError = pipe
    task.standardInput = nil

    do {
        try task.run()
        task.waitUntilExit()
        guard task.terminationStatus == 0 else {
            throw JavaSelectionError.invalidJavaHome(reason: "Error while running \(javaExec), Exit code: \(task.terminationStatus)")
        }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let output = String(data: data, encoding: .utf8) else {
            throw JavaSelectionError.invalidJavaHome(reason: "Cannot read the output of \(javaExec)")
        }

        guard let versionStr = extractVersion(fromJavaVersionOutput: output) else {
            throw JavaSelectionError.invalidJavaHome(reason: "Cannot extract version from output")
        }

        guard let detectedVersion = JavaVersion(from: versionStr) else {
            throw JavaSelectionError.invalidJavaHome(reason: "Cannot parser version string: \(versionStr)")
        }

        if detectedVersion >= minVersion {
            return .environment(path: basePath)
        } else {
            throw JavaSelectionError.userSpecifiedJavaVersionTooLow(
                path: basePath,
                detectedVersion: versionStr,
                required: minVersion
            )
        }
    } catch let error as JavaSelectionError {
        throw error
    } catch {
        throw JavaSelectionError.invalidJavaHome(reason: "Error while running \(javaExec) : \(error)")
    }
}

// MARK: - Select JavaHome
func selectJavaHome(minVersion: JavaVersion = JavaVersion(from: "\(hmclExpectedJavaMajorVersion)")!)
    throws -> JavaHomeSource
{
    // Environment variables check
    if let path = env["HMCL_JAVA_HOME"],
        !path.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    {
        return try validateJavaAtPath(path, minVersion: minVersion)
    }
    if let path = env["JAVA_HOME"], !path.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        return try validateJavaAtPath(path, minVersion: minVersion)
    }

    // Automatic
    let all = findAllJavaInstallations()
    guard !all.isEmpty else { throw JavaSelectionError.noJavaInstalled }

    let latest = all.sortedByVersionDescending().first!
    guard latest.version >= minVersion else {
        throw JavaSelectionError.newestTooLow(found: latest, required: minVersion)
    }

    let arch = currentArch()
    let darwin = getDarwinMajorVersion()
    let allowX86Fallback = (arch == "arm64") && (darwin < 26)

    let candidates = all.filtered(byMinVersion: minVersion)
    let native = candidates.filtered(byArch: arch).sortedByVersionDescending()
    if let best = native.first { return .autoDetected(path: best.path) }

    if allowX86Fallback {
        let x86 = candidates.filtered(byArch: "x86_64").sortedByVersionDescending()
        if let fallback = x86.first { return .autoDetected(path: fallback.path) }
    }

    if arch == "arm64" && !allowX86Fallback {
        throw JavaSelectionError.noArm64OnNewMacOS(
            darwin: darwin, minVer: minVersion, arm64List: candidates.filtered(byArch: "arm64"))
    }

    throw JavaSelectionError.noCompatibleJava(arch: arch, minVer: minVersion, all: all)
}
