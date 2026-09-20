import SwiftUI

enum AppSection: String, CaseIterable, Identifiable {
    case icons
    case settings
    case downloads
    case search

    var id: String { rawValue }

    var title: String {
        switch self {
        case .icons: "아이콘"
        case .settings: "설정"
        case .downloads: "다운로드"
        case .search: "검색"
        }
    }

    var icon: String {
        switch self {
        case .icons: "square.grid.2x2"
        case .settings: "gearshape"
        case .downloads: "arrow.down.circle"
        case .search: "magnifyingglass"
        }
    }
}

enum AppLanguage: String, CaseIterable, Identifiable {
    case korean = "한국어"
    case english = "English"

    var id: String { rawValue }
    var localeIdentifier: String { self == .korean ? "ko" : "en" }
}

enum AccentChoice: String, CaseIterable, Identifiable {
    case white = "흰색"
    case gray = "회색"
    case orange = "주황"
    case red = "빨강"
    case green = "초록"
    case purple = "보라"

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .white: .white
        case .gray: .gray
        case .orange: .orange
        case .red: .red
        case .green: .green
        case .purple: .purple
        }
    }
}

struct DownloadRecord: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let date: Date
    let format: String
    let itemCount: Int

    init(name: String, format: String, itemCount: Int) {
        self.id = UUID()
        self.name = name
        self.date = Date()
        self.format = format
        self.itemCount = itemCount
    }
}
