import Foundation
import UIKit

enum SymbolCatalog {
    /// The complete SF Symbols catalog available on the current OS.
    ///
    /// iOS does not expose a public API that enumerates every SF Symbol name.
    /// CoreGlyphs contains the system's own catalog metadata, so we use it when
    /// available and fall back to the original built-in starter catalog if the
    /// metadata cannot be read.
    static let items: [SymbolItem] = {
        let systemItems = loadSystemCatalog()
        return systemItems.isEmpty ? fallbackItems : systemItems
    }()

    private static func loadSystemCatalog() -> [SymbolItem] {
        // Force UIKit to load the CoreGlyphs bundle before looking it up.
        _ = UIImage(systemName: "tortoise")

        guard let bundle = Bundle(identifier: "com.apple.CoreGlyphs") else {
            return []
        }

        let order: [String] = decodePlist("symbol_order", from: bundle) ?? []
        let categoriesByName: [String: [String]] = decodePlist("symbol_categories", from: bundle) ?? [:]
        let searchTermsByName: [String: [String]] = decodePlist("symbol_search", from: bundle) ?? [:]

        // symbol_order is the primary source. The other two maps make the loader
        // resilient to symbols that are present in CoreGlyphs metadata but not in
        // the ordered list on a particular OS release.
        var candidates: [String] = []
        candidates.reserveCapacity(max(order.count, categoriesByName.count, searchTermsByName.count))

        var seen = Set<String>()
        seen.reserveCapacity(candidates.capacity)

        func appendIfNeeded(_ name: String) {
            guard seen.insert(name).inserted else { return }
            candidates.append(name)
        }

        order.forEach(appendIfNeeded)

        for name in categoriesByName.keys.sorted() {
            appendIfNeeded(name)
        }

        for name in searchTermsByName.keys.sorted() {
            appendIfNeeded(name)
        }

        return candidates.compactMap { name in
            guard UIImage(systemName: name) != nil else { return nil }
            return SymbolItem(
                name: name,
                category: broadCategory(
                    nativeCategories: categoriesByName[name] ?? [],
                    name: name
                )
            )
        }
    }

    private static func decodePlist<T: Decodable>(
        _ name: String,
        from bundle: Bundle
    ) -> T? {
        guard let url = bundle.url(forResource: name, withExtension: "plist"),
              let data = try? Data(contentsOf: url)
        else {
            return nil
        }

        return try? PropertyListDecoder().decode(T.self, from: data)
    }

    /// Maps Apple's more granular CoreGlyphs categories onto the compact
    /// categories already used by SymbolShelf's existing UI.
    private static func broadCategory(
        nativeCategories: [String],
        name: String
    ) -> SymbolCategory {
        let categories = nativeCategories.map {
            $0.lowercased()
                .replacingOccurrences(of: "-", with: "")
                .replacingOccurrences(of: "_", with: "")
                .replacingOccurrences(of: " ", with: "")
        }

        func containsAny(_ needles: [String]) -> Bool {
            categories.contains { category in
                needles.contains { category.contains($0) }
            }
        }

        if containsAny(["communication", "message", "mail", "phone", "sharing"]) {
            return .communication
        }

        if containsAny(["weather"]) {
            return .weather
        }

        if containsAny(["transport", "automotive", "maps", "location"]) {
            return .transport
        }

        if containsAny(["people", "human", "person", "accessibility", "health", "fitness"]) {
            return .people
        }

        if containsAny(["nature", "animals", "plants"]) {
            return .nature
        }

        if containsAny(["commerce", "money", "shopping"]) {
            return .commerce
        }

        if containsAny(["media", "music", "audio", "video", "photos", "camera", "gaming"]) {
            return .media
        }

        if containsAny(["objects", "tools", "devices", "home", "food", "education"]) {
            return .objects
        }

        // Categories such as arrows, math, keyboard, shapes, controls,
        // privacy/security and uncategorized symbols fit best under System.
        return .system
    }

    private static let fallbackItems: [SymbolItem] = [
        // Communication
        "message", "message.fill", "bubble.left", "bubble.right", "bubble.left.and.bubble.right",
        "phone", "phone.fill", "phone.arrow.up.right", "video", "video.fill", "envelope", "envelope.fill",
        "paperplane", "paperplane.fill", "at", "link", "bell", "bell.fill", "megaphone", "quote.bubble"
    ].map { SymbolItem(name: $0, category: .communication) } + [
        // Objects
        "lightbulb", "lightbulb.fill", "flashlight.on.fill", "key", "key.fill", "lock", "lock.open",
        "folder", "folder.fill", "doc", "doc.fill", "book", "book.fill", "bookmark", "bookmark.fill",
        "calendar", "clock", "alarm", "timer", "camera", "camera.fill", "photo", "pencil", "eraser",
        "scissors", "hammer", "wrench.and.screwdriver", "paintbrush", "briefcase", "backpack"
    ].map { SymbolItem(name: $0, category: .objects) } + [
        // Media
        "play", "play.fill", "pause", "pause.fill", "stop", "stop.fill", "forward", "backward",
        "goforward.10", "gobackward.10", "music.note", "music.note.list", "headphones", "speaker.wave.2",
        "mic", "mic.fill", "waveform", "film", "tv", "airplayvideo", "rectangle.on.rectangle", "record.circle"
    ].map { SymbolItem(name: $0, category: .media) } + [
        // Weather
        "sun.max", "sun.max.fill", "moon", "moon.fill", "cloud", "cloud.fill", "cloud.sun", "cloud.moon",
        "cloud.rain", "cloud.heavyrain", "cloud.snow", "cloud.bolt", "wind", "snowflake", "tornado",
        "thermometer.sun", "thermometer.snowflake", "humidity", "umbrella", "rainbow"
    ].map { SymbolItem(name: $0, category: .weather) } + [
        // Transport
        "car", "car.fill", "bus", "bus.fill", "tram", "airplane", "bicycle", "scooter", "ferry",
        "fuelpump", "parkingsign", "figure.walk", "figure.run", "location", "location.fill", "map", "map.fill",
        "mappin", "signpost.right", "steeringwheel", "road.lanes", "trafficlight"
    ].map { SymbolItem(name: $0, category: .transport) } + [
        // People
        "person", "person.fill", "person.2", "person.2.fill", "person.3", "person.crop.circle",
        "person.crop.square", "person.badge.plus", "person.badge.minus", "figure.stand", "figure.wave",
        "figure.roll", "figure.mind.and.body", "hand.raised", "hand.thumbsup", "hand.thumbsdown", "hands.clap"
    ].map { SymbolItem(name: $0, category: .people) } + [
        // Nature
        "leaf", "leaf.fill", "tree", "tree.fill", "mountain.2", "water.waves", "drop", "drop.fill",
        "flame", "flame.fill", "sparkles", "globe", "pawprint", "pawprint.fill", "fish", "bird", "hare",
        "tortoise", "ladybug", "ant", "fossil.shell", "atom"
    ].map { SymbolItem(name: $0, category: .nature) } + [
        // Commerce
        "cart", "cart.fill", "bag", "bag.fill", "basket", "creditcard", "creditcard.fill", "banknote",
        "dollarsign.circle", "wonsign.circle", "gift", "gift.fill", "shippingbox", "shippingbox.fill",
        "storefront", "tag", "tag.fill", "barcode", "qrcode", "percent", "chart.bar", "chart.pie"
    ].map { SymbolItem(name: $0, category: .commerce) } + [
        // System
        "gearshape", "gearshape.fill", "slider.horizontal.3", "switch.2", "ellipsis", "ellipsis.circle",
        "plus", "plus.circle", "minus", "minus.circle", "xmark", "xmark.circle", "checkmark", "checkmark.circle",
        "chevron.left", "chevron.right", "chevron.up", "chevron.down", "arrow.up", "arrow.down", "arrow.left",
        "arrow.right", "arrow.clockwise", "square.and.arrow.up", "square.and.arrow.down", "trash", "trash.fill",
        "magnifyingglass", "line.3.horizontal", "square.grid.2x2", "list.bullet", "info.circle", "questionmark.circle",
        "exclamationmark.triangle", "eye", "eye.slash", "star", "star.fill", "heart", "heart.fill", "bolt", "bolt.fill"
    ].map { SymbolItem(name: $0, category: .system) }
        .filter { UIImage(systemName: $0.name) != nil }
}
