import XCTest
@testable import HMCLauncher

final class LocalizationTests: XCTestCase {
    // MARK: - Localization Tests

    /// Regex pattern to detect format placeholders like %@, %d, %f, etc.
    private let placeholderPattern = "%[0-9\\$]*[sd@f]"

    /// Returns all placeholders in a string
    private func placeholders(in string: String) -> [String] {
        do {
            let regex = try NSRegularExpression(pattern: placeholderPattern)
            let matches = regex.matches(in: string, range: NSRange(string.startIndex..., in: string))
            return matches.map { String(string[Range($0.range, in: string)!]) }
        } catch {
            XCTFail("Regex failed: \(error)")
            return []
        }
    }

    /// Test all localized strings for presence, non-empty value, and placeholder consistency
    func testAllLocalizedStrings() {
        let allStrings = L.allLocalizedStrings
        let englishStrings = allStrings[.en] ?? [:]

        for (lang, table) in allStrings {
            for key in englishStrings.keys {
                let localized = table[key] ?? englishStrings[key]

                XCTAssertNotNil(localized, "Missing localized string for key '\(key)' in language \(lang.rawValue)")
                XCTAssertFalse(localized!.isEmpty, "Empty localized string for key '\(key)' in language \(lang.rawValue)")

                let englishPlaceholders = placeholders(in: englishStrings[key]!)
                let localizedPlaceholders = placeholders(in: localized!)

                XCTAssertEqual(
                    englishPlaceholders, localizedPlaceholders,
                    "Placeholder mismatch for key '\(key)' in language \(lang.rawValue): expected \(englishPlaceholders), found \(localizedPlaceholders)"
                )
            }
        }
    }

    /// Test that if English contains placeholders, other languages also contain the same number of placeholders
    func testPlaceholderConsistencyAcrossLanguages() {
        let allStrings = L.allLocalizedStrings
        let englishStrings = allStrings[.en] ?? [:]

        for (lang, table) in allStrings {
            guard lang != .en else { continue } // Skip English itself

            for (key, englishText) in englishStrings {
                let localized = table[key] ?? englishText
                let englishCount = placeholders(in: englishText).count
                let localizedCount = placeholders(in: localized).count

                if englishCount > 0 {
                    XCTAssertEqual(
                        localizedCount, englishCount,
                        "Placeholder count mismatch for key '\(key)' in language \(lang.rawValue). English has \(englishCount), localized has \(localizedCount)"
                    )
                }
            }
        }
    }
}