import SwiftUI
import UIKit

struct SymbolItem: Identifiable, Hashable, Codable {
    let name: String
    let category: SymbolCategory

    var id: String { name }

    var title: String {
        name
            .split(separator: ".")
            .map { $0.prefix(1).uppercased() + $0.dropFirst() }
            .joined(separator: " ")
    }

    var isAvailable: Bool {
        UIImage(systemName: name) != nil
    }
}

struct SymbolFamily: Identifiable, Hashable {
    let key: String
    let representative: SymbolItem
    let variants: [SymbolItem]

    var id: String { key }
    var category: SymbolCategory { representative.category }

    var title: String {
        key
            .split(separator: ".")
            .map { $0.prefix(1).uppercased() + $0.dropFirst() }
            .joined(separator: " ")
    }
}

enum SymbolCategory: String, CaseIterable, Codable, Identifiable {
    case all = "전체"
    case favorites = "즐겨찾기"
    case communication = "소통"
    case objects = "사물"
    case media = "미디어"
    case weather = "날씨"
    case transport = "이동"
    case people = "사람"
    case nature = "자연"
    case commerce = "상거래"
    case system = "시스템"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .all: "square.grid.2x2"
        case .favorites: "heart.fill"
        case .communication: "bubble.left.and.bubble.right"
        case .objects: "lightbulb"
        case .media: "play.rectangle"
        case .weather: "cloud.sun"
        case .transport: "car"
        case .people: "person.2"
        case .nature: "leaf"
        case .commerce: "cart"
        case .system: "gearshape"
        }
    }
}

enum SymbolWeight: String, CaseIterable, Identifiable, Codable {
    case ultraLight = "Ultra Light"
    case thin = "Thin"
    case light = "Light"
    case regular = "Regular"
    case medium = "Medium"
    case semibold = "Semibold"
    case bold = "Bold"
    case heavy = "Heavy"
    case black = "Black"

    var id: String { rawValue }

    var uiWeight: UIImage.SymbolWeight {
        switch self {
        case .ultraLight: .ultraLight
        case .thin: .thin
        case .light: .light
        case .regular: .regular
        case .medium: .medium
        case .semibold: .semibold
        case .bold: .bold
        case .heavy: .heavy
        case .black: .black
        }
    }

    var fontWeight: Font.Weight {
        switch self {
        case .ultraLight: .ultraLight
        case .thin: .thin
        case .light: .light
        case .regular: .regular
        case .medium: .medium
        case .semibold: .semibold
        case .bold: .bold
        case .heavy: .heavy
        case .black: .black
        }
    }
}

enum ExportFormat: String, CaseIterable, Identifiable, Codable {
    case png = "PNG"
    case svg = "SVG"

    var id: String { rawValue }
    var fileExtension: String { rawValue.lowercased() }
}

enum ExportBackground: String, CaseIterable, Identifiable, Codable {
    case transparent = "투명"
    case white = "흰색"
    case black = "검정"

    var id: String { rawValue }
}

enum SymbolRenderingStyle: String, CaseIterable, Identifiable, Codable {
    case monochrome = "단색"
    case hierarchical = "계층형"
    case palette = "팔레트"
    case multicolor = "멀티컬러"

    var id: String { rawValue }
}

enum ExportTint: String, CaseIterable, Identifiable, Codable {
    case primary = "기본"
    case black = "검정"
    case white = "흰색"
    case blue = "파랑"
    case purple = "보라"
    case red = "빨강"
    case green = "초록"
    case orange = "주황"

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .primary: .primary
        case .black: .black
        case .white: .white
        case .blue: .blue
        case .purple: .purple
        case .red: .red
        case .green: .green
        case .orange: .orange
        }
    }

    var uiColor: UIColor {
        switch self {
        case .primary: .label
        case .black: .black
        case .white: .white
        case .blue: .systemBlue
        case .purple: .systemPurple
        case .red: .systemRed
        case .green: .systemGreen
        case .orange: .systemOrange
        }
    }
}

struct ExportSettings: Codable, Equatable {
    var size = 512
    var weight: SymbolWeight = .regular
    var format: ExportFormat = .png
    var vectorizesSVG = false
    var background: ExportBackground = .transparent
    var renderingStyle: SymbolRenderingStyle = .hierarchical
    var tint: ExportTint = .primary
    var secondaryTint: ExportTint = .blue

    var usesVectorSVG: Bool {
        format == .svg && vectorizesSVG
    }
}
