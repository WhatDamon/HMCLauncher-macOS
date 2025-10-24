import Foundation

// MARK: - Utility: Show Error Dialog
func showDialog(
    _ message: String,
    title: String = L.t("ERROR_TITLE"),
    buttons: [String] = ["OK"],
    onButtonPressed: ((String) -> Void)? = nil
) {
    let buttonsList = buttons.map { "\"\($0)\"" }.joined(separator: ", ")
    let defaultButton = "\"\(buttons.first ?? "OK")\""

    let script = """
        set response to display alert "\(title)" message "\(message)" buttons {\(buttonsList)} default button \(defaultButton)
        return button returned of response
        """

    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
    process.arguments = ["-e", script]

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
            print("Button pressed: \(output)")
            onButtonPressed?(output)
        }
    } catch {
        print("Failed to show error dialog: \(error)")
    }
}
