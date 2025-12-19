import Foundation

// MARK: - Utility: Show Error Dialog
func showDialog(
    _ message: String,
    title: String = L.t("ERROR_TITLE"),
    buttons: [String] = ["OK"],
    isWarning: Bool = false,
    onButtonPressed: ((String) -> Void)? = nil
) {
    let buttonsList: String = buttons.map { "\"\($0)\"" }.joined(separator: ", ")
    let defaultButton: String = "\"\(buttons.first ?? "OK")\""
    var styleArg: String = ""

    if isWarning == true {
        styleArg = "as critical"
    }

    let script: String = """
        set response to display alert "\(title)" message "\(message)" \(styleArg) buttons {\(buttonsList)} default button \(defaultButton)
        return button returned of response
        """

    let process: Process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
    process.arguments = ["-e", script]

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
            print("Button pressed: \(output)")
            onButtonPressed?(output)
        }
    } catch {
        print("Failed to show dialog: \(error)")
    }
}
