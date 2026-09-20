import SwiftUI

@main
struct SymbolShelfApp: App {
    @AppStorage("accentChoice") private var accentChoice = AccentChoice.white.rawValue
    @AppStorage("appLanguage") private var appLanguage = AppLanguage.korean.rawValue

    var body: some Scene {
        WindowGroup {
            ContentView()
                .tint(AccentChoice(rawValue: accentChoice)?.color ?? .primary)
                .environment(
                    \.locale,
                    Locale(identifier: AppLanguage(rawValue: appLanguage)?.localeIdentifier ?? "ko")
                )
        }
    }
}
