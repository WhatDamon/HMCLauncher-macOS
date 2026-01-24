import Foundation

// MARK: - Function: Show Error Dialog
public func showDialog(
    _ message: String,
    title: String = L.t("ERROR_TITLE"),
    buttons: [String] = ["OK"],
    isWarning: Bool = false,
    onButtonPressed: ((String) -> Void)? = nil
) {
    let buttonsList = buttons.map { "\"\($0)\"" }.joined(separator: ", ")
    let defaultButton = "\"\(buttons.first ?? "OK")\""
    let styleArg = isWarning ? "as critical" : ""

    let script = """
        set response to display alert "\(title)" message "\(message)" \(styleArg) buttons {\(buttonsList)} default button \(defaultButton)
        return button returned of response
        """

    let dirs: [URL] =
        LauncherEnv.IS_INSIDE_APP_BUNDLE
        ? AppPath.workingDirectoryChain(depth: 2)
        : [AppPath.workingDirectory]

    for dir in dirs {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", script]
        process.currentDirectoryURL = dir
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()

        do {
            try process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines),
                !output.isEmpty
            {
                print("Button pressed: \(output) (executed in \(dir.path))")
                onButtonPressed?(output)
            }
        } catch {
            print("Failed to show dialog in \(dir.path): \(error)")
        }
    }
}
