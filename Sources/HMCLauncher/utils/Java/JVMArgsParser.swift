import Foundation

// MARK: - JVM Argument Parser
public final class JVMArgsParser {
    // MARK: - Shell Argument Parser
    private static func parseShellArgs(_ input: String) -> [String] {
        var args: [String] = []
        var current = ""
        var inSingleQuote = false
        var inDoubleQuote = false
        var escaping = false

        for char in input {
            if escaping {
                current.append(char)
                escaping = false
                continue
            }

            switch char {
            case "\\":
                escaping = true
            case "'":
                if inDoubleQuote {
                    current.append(char)
                } else {
                    inSingleQuote.toggle()
                }
            case "\"":
                if inSingleQuote {
                    current.append(char)
                } else {
                    inDoubleQuote.toggle()
                }
            case " ", "\t", "\n":
                if inSingleQuote || inDoubleQuote {
                    current.append(char)
                } else if !current.isEmpty {
                    args.append(current)
                    current = ""
                }
            default:
                current.append(char)
            }
        }

        if !current.isEmpty {
            args.append(current)
        }

        return args
    }

    private static func isJVMArg(_ arg: String) -> Bool {
        arg.hasPrefix("-X")
            || arg.hasPrefix("-D")
            || arg.hasPrefix("-XX:")
            || arg.hasPrefix("--add-")
    }

    // MARK: - Public API
    public static func parse(from source: Any?) -> [String] {
        let args: [String]

        if let str = source as? String {
            args = parseShellArgs(str)
        } else if let arr = source as? [String] {
            args = arr
        } else {
            return []
        }

        return args.filter(isJVMArg)
    }

    public static func argKey(_ arg: String) -> String {
        if arg.hasPrefix("-D") || arg.hasPrefix("-XX:") {
            return arg.split(separator: "=", maxSplits: 1)
                .first
                .map(String.init) ?? arg
        }

        if arg.hasPrefix("-X") {
            return String(arg.prefix(4))
        }

        return arg
    }
}
