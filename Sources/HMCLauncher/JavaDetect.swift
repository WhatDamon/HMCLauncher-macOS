import Foundation

// MARK: - Utility: Resolve JAVA_HOME
func resolveJavaHome() -> String? {
    if let javaHome: String = env["JAVA_HOME"], !javaHome.isEmpty {
        return javaHome
    }

    let process: Process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/libexec/java_home")

    let pipe: Pipe = Pipe()
    process.standardOutput = pipe
    process.standardError = Pipe()

    do {
        try process.run()
        process.waitUntilExit()
        let data: Data = pipe.fileHandleForReading.readDataToEndOfFile()
        if let output: String = String(data: data, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines),
            !output.isEmpty
        {
            return output
        }
    } catch {
        print("Failed to resolve JAVA_HOME: \(error)")
        showDialog(L.t("ERROR_OCCURRED", "\(error)"))
    }

    return nil
}

// MARK: - Utility: Find Java Executable
func findJavaExecutable(_ javaHome: String) -> String? {
    guard let normalizedPath: String = try? FileManager.default.canonicalizePath(javaHome) else {
        print("Failed to canonicalize JAVA_HOME: \(javaHome)")
        showDialog(L.t("ERROR_OCCURRED", "Failed to canonicalize JAVA_HOME:\n\(javaHome)"))
        return nil
    }

    let candidatePaths: [String] = [
        normalizedPath + "/bin/java",
        normalizedPath + "/Contents/Home/bin/java",
        normalizedPath + "/Home/bin/java",
    ]

    for path: String in candidatePaths where FileManager.default.fileExists(atPath: path) {
        return path
    }

    // Fallback check
    let fallback: String = normalizedPath + "/bin/java"
    if FileManager.default.fileExists(atPath: fallback) {
        return fallback
    }

    print("No java executable found at: \(javaHome)")
    showDialog(L.t("ERROR_OCCURED", "No java executable found at:\n\(javaHome)"))
    return nil
}

// MARK: - Utility: Get Java Major Version
func getJavaMajorVersion(_ javaExec: String) -> Int? {
    let task: Process = Process()
    task.executableURL = URL(fileURLWithPath: javaExec)
    task.arguments = ["-version"]

    let errorPipe: Pipe = Pipe()
    task.standardError = errorPipe

    do {
        try task.run()
        task.waitUntilExit()

        guard task.terminationStatus == 0 else {
            print("java -version failed with exit code \(task.terminationStatus)")
            showDialog(L.t("ERROR_OCCURED", "java -version failed with exit code \(task.terminationStatus)"))
            return nil
        }

        let data: Data = errorPipe.fileHandleForReading.readDataToEndOfFile()
        guard let output: String = String(data: data, encoding: .utf8),
            let firstLine: String.SubSequence = output.split(separator: "\n").first
        else {
            print("Failed to read or parse java -version output")
            showDialog(L.t("ERROR_OCCURRED", "Failed to read or parse java -version output"))
            return nil
        }

        let line: String = String(firstLine)
        let regexPattern: String = #""([^"]+)""#
        if let regex: NSRegularExpression = try? NSRegularExpression(pattern: regexPattern),
            let match: NSTextCheckingResult = regex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)),
            let range: Range<String.Index> = Range(match.range(at: 1), in: line)
        {
            let versionString: String = String(line[range])
            let components: [String.SubSequence] = versionString.split(separator: ".", maxSplits: 1)

            if components.first == "1" {
                if components.count > 1,
                    let minor: Substring.SubSequence = components[1].split(separator: ".").first,
                    let major: Int = Int(minor)
                {
                    return major
                }
            } else {
                if let major: Int = Int(components[0]) {
                    return major
                }
            }
        }

    } catch {
        print("Error running java -version: \(error)")
        showDialog(L.t("ERROR_OCCURRED", "\(error)"))
    }

    return nil
}