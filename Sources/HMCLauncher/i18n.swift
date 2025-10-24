import Foundation

// MARK: - Utility: Localization Helper
enum L {
    enum Language: String {
        case en
        case zhHans = "zh-Hans"

    }

    static let current: Language = {
        let locale = Locale.current.identifier.lowercased()
        return locale.contains("zh") ? .zhHans : .en
    }()

    private static let localizedStrings: [Language: [String: String]] = [
        .en: [
            "ERROR_TITLE": "Error",
            "WARNING_TITLE": "Warning",
            "CANCEL_BUTTON": "Cancel",
            "JAVA_HOME_MISSING": "HMCL requires Java %@ or later to run!",
            "JAVA_MISING_TITLE": "Missing Java",
            "HMCL_JAVA_HOME_INVALID": "The Java path specified by HMCL_JAVA_HOME is invalid.\nPlease update it to a valid Java installation path or remove this environment variable.",
            "JAVA_EXEC_NOT_FOUND": "No java executable found!",
            "JAVA_TOO_OLD": "Please upgrade to Java %@ or above!\nYou are using Java %@",
            "JAVA_NOT_SUPPORTED_TITLE": "Java is not supported",
            "JAVA_RESOLVE_FAILED": "Failed to resolve JAVA_HOME:\n%@",
            "JAVA_CANONICALIZE_FAILED": "Failed to canonicalize JAVA_HOME:\n%@",
            "JAVA_EXEC_NOT_FOUND_AT": "No java executable found at:\n%@",
            "JAVA_VERSION_EXIT_CODE": "java -version failed with exit code: %@",
            "JAVA_VERSION_PARSER_ERROR": "Failed to read or parse java -version output",
            "JAVA_VERSION_ERROR": "Error running java -version:\n%@",
            "DOWNLOAD_JAVA_BUTTON": "Download a Supported Version",
            "CANNOT_FIND_HMCL": "HMCL not found, unable to run"
        ],
        .zhHans: [
            "ERROR_TITLE": "错误",
            "WARNING_TITLE": "警告",
            "CANCEL_BUTTON": "取消",
            "JAVA_HOME_MISSING": "HMCL 需要 Java %@ 或更高版本才能运行",
            "JAVA_MISING_TITLE": "找不到 Java",
            "HMCL_JAVA_HOME_INVALID": "HMCL_JAVA_HOME 所指向的 Java 路径无效，请更新或删除该变量。",
            "JAVA_EXEC_NOT_FOUND": "未找到 Java 可执行文件！",
            "JAVA_TOO_OLD": "请升级到 Java %@ 或更高版本！\n当前版本: Java %@",
            "JAVA_NOT_SUPPORTED_TITLE": "Java 版本不受支持",
            "JAVA_RESOLVE_FAILED": "获取 JAVA_HOME 失败: \n%@",
            "JAVA_CANONICALIZE_FAILED": "规范化 JAVA_HOME 路径时失败:\n%@",
            "JAVA_EXEC_NOT_FOUND_AT": "未在此目录找到 Java 可执行文件:\n%@",
            "JAVA_VERSION_EXIT_CODE": "执行 java -version 失败并返回代码: %@",
            "JAVA_VERSION_PARSER_ERROR": "格式化 java -version 输出失败",
            "JAVA_VERSION_ERROR": "执行 java -version 错误:\n%@",
            "DOWNLOAD_JAVA_BUTTON": "下载受支持的版本",
            "CANNOT_FIND_HMCL": "找不到 HMCL, 无法运行"
        ]
    ]

    static func t(_ key: String, _ args: CVarArg...) -> String {
        let table = localizedStrings[current] ?? [:]
        let template = table[key] ?? localizedStrings[.en]?[key] ?? key
        return String(format: template, arguments: args)
    }
}