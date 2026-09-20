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

    static let families: [SymbolFamily] = makeFamilies(from: items)

    private static func loadSystemCatalog() -> [SymbolItem] {
        // Force UIKit to load the CoreGlyphs bundle before looking it up.
        _ = UIImage(systemName: "tortoise")

        guard let bundle = Bundle(identifier: "com.apple.CoreGlyphs") else {
            return []
        }

        let order: [String] = decodePlist("symbol_order", from: bundle) ?? []
        let categoriesByName: [String: [String]] = decodePlist("symbol_categories", from: bundle) ?? [:]
        let searchTermsByName: [String: [String]] = decodePlist("symbol_search", from: bundle) ?? [:]
        let nativeCategories: [CoreGlyphCategory] = decodePlist("categories", from: bundle) ?? []
        let nativeCategoryRanks = Dictionary(
            uniqueKeysWithValues: nativeCategories.enumerated().map { ($0.element.key, $0.offset) }
        )

        // symbol_order is the primary source. The other two maps make the loader
        // resilient to symbols that are present in CoreGlyphs metadata but not in
        // the ordered list on a particular OS release.
        let estimatedCount = max(order.count, max(categoriesByName.count, searchTermsByName.count))
        var candidates: [String] = []
        candidates.reserveCapacity(estimatedCount)

        var seen = Set<String>()
        seen.reserveCapacity(estimatedCount)

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

        let entries: [CatalogEntry] = candidates.enumerated().compactMap { originalIndex, name in
            guard UIImage(systemName: name) != nil else { return nil }

            let categories = categoriesByName[name] ?? []
            let item = SymbolItem(
                name: name,
                category: broadCategory(
                    nativeCategories: categories,
                    name: name
                )
            )

            let nativeRank = categories
                .compactMap { nativeCategoryRanks[$0] }
                .min() ?? Int.max

            return CatalogEntry(
                item: item,
                family: familyKey(for: name),
                nativeCategoryRank: nativeRank,
                originalIndex: originalIndex
            )
        }

        return entries.sorted(by: relatedSymbolSort).map(\.item)
    }

    private struct CoreGlyphCategory: Decodable {
        let key: String
        let icon: String
    }

    private struct CatalogEntry {
        let item: SymbolItem
        let family: String
        let nativeCategoryRank: Int
        let originalIndex: Int
    }

    private static func relatedSymbolSort(_ lhs: CatalogEntry, _ rhs: CatalogEntry) -> Bool {
        let lhsCategoryRank = categoryRank(lhs.item.category)
        let rhsCategoryRank = categoryRank(rhs.item.category)

        if lhsCategoryRank != rhsCategoryRank {
            return lhsCategoryRank < rhsCategoryRank
        }

        let familyComparison = lhs.family.localizedStandardCompare(rhs.family)
        if familyComparison != .orderedSame {
            return familyComparison == .orderedAscending
        }

        if lhs.nativeCategoryRank != rhs.nativeCategoryRank {
            return lhs.nativeCategoryRank < rhs.nativeCategoryRank
        }

        let lhsVariantRank = variantRank(lhs.item.name)
        let rhsVariantRank = variantRank(rhs.item.name)
        if lhsVariantRank != rhsVariantRank {
            return lhsVariantRank < rhsVariantRank
        }

        return lhs.originalIndex < rhs.originalIndex
    }

    private static func categoryRank(_ category: SymbolCategory) -> Int {
        switch category {
        case .communication: 0
        case .objects: 1
        case .media: 2
        case .weather: 3
        case .transport: 4
        case .people: 5
        case .nature: 6
        case .commerce: 7
        case .system: 8
        case .all: 9
        case .favorites: 10
        }
    }

    /// Groups visually/semantically related variants next to each other.
    ///
    /// Examples:
    /// - person, person.fill, person.crop.circle -> "person"
    /// - cloud.rain, cloud.snow, cloud.bolt -> "cloud"
    /// - arrow.up, arrow.down, arrow.clockwise -> "arrow"
    private static func familyKey(for name: String) -> String {
        let lowered = name.lowercased()

        let specialPrefixes: [(String, String)] = [
            ("square.and.arrow.", "share"),
            ("rectangle.and.pencil.and.ellipsis", "edit"),
            ("rectangle.portrait.and.arrow.", "transfer"),
            ("arrowtriangle.", "arrowtriangle"),
            ("chevron.", "chevron"),
            ("figure.", "figure"),
            ("person.", "person"),
            ("person", "person"),
            ("hands.", "hand"),
            ("hand.", "hand"),
            ("cloud.", "cloud"),
            ("cloud", "cloud"),
            ("sun.", "sun"),
            ("moon.", "moon"),
            ("speaker.", "speaker"),
            ("speaker", "speaker"),
            ("waveform.", "waveform"),
            ("music.", "music"),
            ("music", "music"),
            ("video.", "video"),
            ("camera.", "camera"),
            ("photo.", "photo"),
            ("car.", "car"),
            ("bus.", "bus"),
            ("tram.", "tram"),
            ("airplane.", "airplane"),
            ("bicycle.", "bicycle"),
            ("cart.", "cart"),
            ("bag.", "bag"),
            ("creditcard.", "creditcard"),
            ("folder.", "folder"),
            ("doc.", "doc"),
            ("book.", "book"),
            ("lock.", "lock"),
            ("key.", "key"),
            ("bell.", "bell"),
            ("message.", "message"),
            ("bubble.", "bubble"),
            ("phone.", "phone"),
            ("envelope.", "envelope"),
            ("paperplane.", "paperplane"),
            ("arrow.", "arrow")
        ]

        for (prefix, family) in specialPrefixes where lowered.hasPrefix(prefix) {
            return family
        }

        return lowered.split(separator: ".").first.map(String.init) ?? lowered
    }

    /// Generic tokens that describe presentation/containers rather than the
    /// semantic identity of a symbol. A token is only stripped when the inferred
    /// parent actually exists in the catalog, or when multiple siblings provide
    /// evidence that the parent is a real family root.
    private static let structuralVariantTokens: Set<String> = [
        "fill", "slash",
        "circle", "square", "rectangle", "capsule",
        "triangle", "diamond", "hexagon", "octagon", "shield"
    ]

    /// SF Symbols appends locale identifiers such as .bn, .mr, .gu and .rtl to
    /// localized glyph variants. Build the language-code set from Foundation
    /// instead of maintaining a hard-coded list so new locales are picked up.
    private static let localizationSuffixes: Set<String> = {
        var result: Set<String> = ["rtl"]

        for identifier in Locale.availableIdentifiers {
            let normalized = identifier
                .replacingOccurrences(of: "_", with: "-")
                .lowercased()

            guard let first = normalized.split(separator: "-").first else {
                continue
            }

            let languageCode = String(first)
            if (2...3).contains(languageCode.count) {
                result.insert(languageCode)
            }
        }

        return result
    }()

    /// Builds families by inferring a parent/child graph from the symbol names.
    ///
    /// Examples:
    /// character.bubble.fill.bn -> character.bubble.fill -> character.bubble
    /// arrow.up.circle.fill     -> arrow.up.circle -> arrow.up
    /// person.badge.plus        -> person
    ///
    /// Semantic suffixes such as ".rain" are not removed, so cloud.rain does
    /// not collapse into cloud just because the names share a prefix.
    private static func makeFamilies(from items: [SymbolItem]) -> [SymbolFamily] {
        let allNames = Set(items.map { $0.name.lowercased() })
        let descendantCounts = inferredDescendantCounts(for: allNames)

        var orderedKeys: [String] = []
        var groups: [String: [SymbolItem]] = [:]

        for item in items {
            let key = inferredFamilyRoot(
                for: item.name,
                allNames: allNames,
                descendantCounts: descendantCounts
            )

            if groups[key] == nil {
                orderedKeys.append(key)
                groups[key] = []
            }

            groups[key, default: []].append(item)
        }

        return orderedKeys.compactMap { key in
            guard let variants = groups[key], !variants.isEmpty else {
                return nil
            }

            let representative = variants.first(where: { $0.name.lowercased() == key })
                ?? variants.min {
                    let lhsRank = variantRank($0.name)
                    let rhsRank = variantRank($1.name)

                    if lhsRank != rhsRank {
                        return lhsRank < rhsRank
                    }

                    if $0.name.count != $1.name.count {
                        return $0.name.count < $1.name.count
                    }

                    return $0.name < $1.name
                }
                ?? variants[0]

            return SymbolFamily(
                key: key,
                representative: representative,
                variants: variants
            )
        }
    }

    private static func inferredFamilyRoot(
        for name: String,
        allNames: Set<String>,
        descendantCounts: [String: Int]
    ) -> String {
        var current = name.lowercased()
        var visited: Set<String> = []

        while visited.insert(current).inserted {
            guard let parent = inferredParent(
                of: current,
                allNames: allNames,
                descendantCounts: descendantCounts
            ) else {
                break
            }

            current = parent
        }

        return current
    }

    private static func inferredParent(
        of name: String,
        allNames: Set<String>,
        descendantCounts: [String: Int]
    ) -> String? {
        for candidate in immediateParentCandidates(for: name) {
            let parentExists = allNames.contains(candidate)
            let hasSiblingEvidence = (descendantCounts[candidate] ?? 0) >= 2

            if parentExists || hasSiblingEvidence {
                return candidate
            }
        }

        return nil
    }

    /// Candidate order matters: remove a locale/presentation wrapper first, then
    /// a badge branch, then numeric variants. This allows chains such as
    /// character.bubble.fill.bn to converge naturally on character.bubble.
    private static func immediateParentCandidates(for name: String) -> [String] {
        let parts = name.lowercased().split(separator: ".").map(String.init)
        guard parts.count > 1 else {
            return []
        }

        var candidates: [String] = []

        func append(_ parts: ArraySlice<String>) {
            guard !parts.isEmpty else { return }
            let candidate = parts.joined(separator: ".")
            if candidate != name && !candidates.contains(candidate) {
                candidates.append(candidate)
            }
        }

        if let last = parts.last,
           localizationSuffixes.contains(last) {
            append(parts.dropLast())
        }

        if let last = parts.last,
           structuralVariantTokens.contains(last) {
            append(parts.dropLast())
        }

        if let badgeIndex = parts.lastIndex(of: "badge"),
           badgeIndex > 0 {
            append(parts[..<badgeIndex])
        }

        if let last = parts.last,
           Int(last) != nil {
            append(parts.dropLast())
        }

        return candidates
    }

    /// Counts how many distinct real symbols can collapse to each inferred
    /// ancestor. This lets us recognize synthetic roots such as person.crop
    /// even when no literal "person.crop" SF Symbol exists.
    private static func inferredDescendantCounts(
        for allNames: Set<String>
    ) -> [String: Int] {
        var descendants: [String: Set<String>] = [:]

        for originalName in allNames {
            var queue = [originalName]
            var visited: Set<String> = [originalName]

            while !queue.isEmpty {
                let current = queue.removeFirst()

                for candidate in immediateParentCandidates(for: current)
                where visited.insert(candidate).inserted {
                    descendants[candidate, default: []].insert(originalName)
                    queue.append(candidate)
                }
            }
        }

        return descendants.mapValues(\.count)
    }

    private static func variantRank(_ name: String) -> Int {
        let parts = Set(name.lowercased().split(separator: ".").map(String.init))

        var rank = 0
        if parts.contains("fill") { rank += 1 }
        if parts.contains("slash") { rank += 2 }
        if parts.contains("badge") { rank += 4 }
        if parts.contains("circle") { rank += 8 }
        if parts.contains("square") { rank += 16 }
        return rank
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

        // Use the symbol name as a final lightweight hint for entries without
        // useful category metadata.
        let loweredName = name.lowercased()
        if loweredName.contains("cloud") || loweredName.contains("sun.") || loweredName.contains("moon.") {
            return .weather
        }
        if loweredName.contains("car") || loweredName.contains("bus") || loweredName.contains("airplane") {
            return .transport
        }
        if loweredName.contains("person") || loweredName.contains("figure.") || loweredName.contains("hand.") {
            return .people
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
