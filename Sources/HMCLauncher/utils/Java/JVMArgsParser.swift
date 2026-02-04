import Foundation

// MARK: - JVM Argument Helpers
public func parseJVMArgs(from source: Any?) -> [String] {
    let args: [String]

    if let str = source as? String {
        args = str.split(separator: " ").map(String.init)
    } else if let arr = source as? [String] {
        args = arr
    } else {
        return []
    }

    return args.filter(isJVMArg)
}

private func isJVMArg(_ arg: String) -> Bool {
    arg.hasPrefix("-X")
        || arg.hasPrefix("-D")
        || arg.hasPrefix("-XX:")
        || arg.hasPrefix("--add-")
}

public func jvmArgKey(_ arg: String) -> String {
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
