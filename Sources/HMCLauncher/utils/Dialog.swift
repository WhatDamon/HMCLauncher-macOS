import Foundation

private func escapeForAppleScript(_ str: String) -> String {
    str.replacingOccurrences(of: "\\", with: "\\\\")
        .replacingOccurrences(of: "\"", with: "\\\"")
        .replacingOccurrences(of: "\n", with: "\\n")
        .replacingOccurrences(of: "\r", with: "\\r")
        .replacingOccurrences(of: "\t", with: "\\t")
}

public func showDialog(
    _ message: String,
    title: String = L.t("ERROR_TITLE"),
    buttons: [String] = ["OK"],
    isWarning: Bool = false,
    onButtonPressed: ((String) -> Void)? = nil
) {
    let escapedTitle = escapeForAppleScript(title)
    let escapedMessage = escapeForAppleScript(message)
    let buttonsList = buttons.map { "\"\(escapeForAppleScript($0))\"" }.joined(separator: ", ")
    let defaultButton = "\"\(escapeForAppleScript(buttons.first ?? "OK"))\""
    let styleArg = isWarning ? "as critical" : ""

    let script = """
        set response to display alert "\(escapedTitle)" message "\(escapedMessage)" \(styleArg) buttons {\(buttonsList)} default button \(defaultButton)
        return button returned of response
        """

    let dirs: [URL] =
        LauncherEnv.IS_INSIDE_APP_BUNDLE
        ? PathUtils.workingDirectoryChain(depth: 2)
        : [PathUtils.workingDirectory]

    for dir in dirs {
        do {
            let output = try ProcessRunner.runAppleScript(script, directory: dir)
                .trimmingCharacters(in: .whitespacesAndNewlines)

            if !output.isEmpty {
                DebugLogger.log(
                    "Button pressed: \(output) (executed in \(dir.path))", level: .debug)
                onButtonPressed?(output)
                return
            }
        } catch {
            DebugLogger.log("Failed to show dialog in \(dir.path): \(error)", level: .error)
        }
    }
}