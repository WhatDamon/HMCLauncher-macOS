import Foundation

// MARK: - Enum: Localization Helper
public enum L {
    public enum Language: String, CaseIterable, Sendable {
        case en
        case zhHans = "zh-Hans"
    }

    private static let current: Language = {
        let languages: [String]? =
            UserDefaults.standard.array(forKey: "AppleLanguages") as? [String]
        let primaryLang: String = languages?.first?.lowercased() ?? "en"
        return primaryLang.contains("zh") ? .zhHans : .en
    }()

    private static let localizedStrings: [Language: [String: String]] = [
        .en: [
            "ERROR_TITLE": "Error",
            "WARNING_TITLE": "Warning",
            "CANCEL_BUTTON": "Cancel",
            "INSTALL_BUTTON": "Install",
            "JAVA_NOT_FOUND_TITLE": "Java Not Found",
            "HOMEWREW_INSTALL_PROMPT": "No suitable Java found. Install OpenJDK via Homebrew?\nRecommended: OpenJDK %@+",
            "INSTALL_FAILED": "Installation failed: %@",
            "ERROR_OCCURRED": "An error has occurred:\n%@",
            "UNSUPPORTED_MACOS": "Unsupported macOS!\nMinimum supported version is 10.15.",
            "HMCL_JAVA_HOME_INVALID":
                "The Java path specified by HMCL_JAVA_HOME is invalid.\nPlease update it to a valid Java installation path or remove this environment variable.",
            "JAVA_TOO_OLD": "Please upgrade to Java %@ or above!\nYou are using Java %@",
            "JAVA_NOT_SUPPORTED_TITLE": "Java is not supported",
            "DOWNLOAD_JAVA_BUTTON": "Download a Supported Version",
            "CANNOT_OPEN_JAVA_DOWNLOAD":
                "Unable to open webpage.\nPlease visit %@ manually to download Java.",
            "CANNOT_FIND_HMCL": "HMCL not found, unable to run"
        ],
        .zhHans: [
            "ERROR_TITLE": "错误",
            "WARNING_TITLE": "警告",
            "CANCEL_BUTTON": "取消",
            "INSTALL_BUTTON": "安装",
            "JAVA_NOT_FOUND_TITLE": "未找到 Java",
            "HOMEWREW_INSTALL_PROMPT": "未找到合适的 Java。是否通过 Homebrew 安装 OpenJDK?\n建议版本: OpenJDK %@+",
            "INSTALL_FAILED": "安装失败: %@",
            "ERROR_OCCURRED": "遇到了一个问题:\n%@",
            "UNSUPPORTED_MACOS": "不受支持的 macOS!\n最低支持的 macOS 版本为 10.15.",
            "HMCL_JAVA_HOME_INVALID": "HMCL_JAVA_HOME 所指向的 Java 路径无效，请更新或删除该变量",
            "JAVA_TOO_OLD": "请升级到 Java %@ 或更高版本！\n当前版本: Java %@",
            "JAVA_NOT_SUPPORTED_TITLE": "Java 版本不受支持",
            "DOWNLOAD_JAVA_BUTTON": "下载受支持的版本",
            "CANNOT_OPEN_JAVA_DOWNLOAD": "无法打开网页,\n请手动访问 %@ 下载Java",
            "CANNOT_FIND_HMCL": "找不到 HMCL, 无法运行"
        ]
    ]

    // MARK: - Public API
    public static func t(_ key: String, _ args: CVarArg...) -> String {
        let table: [String: String] = localizedStrings[current] ?? [:]
        let template: String = table[key] ?? localizedStrings[.en]?[key] ?? key
        return String(format: template, arguments: args)
    }

    // MARK: - Var: Exposes all language tables (currently for test)
    public static var allLocalizedStrings: [Language: [String: String]] {
        return localizedStrings
    }
}
