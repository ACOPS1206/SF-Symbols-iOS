import Foundation

/// Infers browse-sized SF Symbol families from the names available on the
/// current OS. The classifier deliberately separates visual variants from
/// semantic variants before choosing a family root.
enum SymbolFamilyClassifier {
    /// A family should remain small enough to scan in the variant sheet. Roots
    /// with more semantic branches are split at the next meaningful token.
    private static let maximumSemanticBranches = 24

    /// Tokens that change presentation or containment without changing the
    /// subject of the symbol.
    private static let structuralSuffixes: Set<String> = [
        "fill", "slash",
        "circle", "square", "rectangle", "capsule",
        "triangle", "diamond", "hexagon", "octagon", "shield"
    ]

    private static let directVisualSuffixes: Set<String> = ["fill", "slash"]
    private static let connectorTokens: Set<String> = ["and", "or", "to", "with", "of"]

    /// SF Symbols uses language identifiers as suffixes for localized glyphs.
    private static let localizationSuffixes: Set<String> = {
        var result: Set<String> = [
            "ar", "bn", "gu", "he", "hi", "ja", "kn", "ko", "ml", "mni",
            "mr", "or", "pa", "rtl", "sat", "si", "ta", "te", "th", "zh"
        ]

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

    struct Index {
        private let familyByName: [String: String]

        init(names: [String], noFillToFill: [String: String]) {
            let allNames = Set(names.map { $0.lowercased() })
            let fillToNoFill = Dictionary(
                noFillToFill.compactMap { noFill, fill -> (String, String)? in
                    let normalizedNoFill = noFill.lowercased()
                    let normalizedFill = fill.lowercased()
                    guard allNames.contains(normalizedNoFill),
                          allNames.contains(normalizedFill)
                    else {
                        return nil
                    }
                    return (normalizedFill, normalizedNoFill)
                },
                uniquingKeysWith: { first, _ in first }
            )

            let initialBases = Dictionary(
                uniqueKeysWithValues: allNames.map { name in
                    (
                        name,
                        SymbolFamilyClassifier.initialVisualBase(
                            for: name,
                            fillToNoFill: fillToNoFill
                        )
                    )
                }
            )

            let baseNames = Set(initialBases.values)
            let structuralDescendantCounts =
                SymbolFamilyClassifier.structuralDescendantCounts(for: baseNames)

            let structuralBases = Dictionary(
                uniqueKeysWithValues: allNames.map { name in
                    let initialBase = initialBases[name] ?? name
                    return (
                        name,
                        SymbolFamilyClassifier.structuralRoot(
                            for: initialBase,
                            allNames: baseNames,
                            descendantCounts: structuralDescendantCounts
                        )
                    )
                }
            )

            let ordinalCounts = SymbolFamilyClassifier.ordinalStemCounts(
                for: Set(structuralBases.values)
            )
            let semanticBases = Dictionary(
                uniqueKeysWithValues: allNames.map { name in
                    let structuralBase = structuralBases[name] ?? name
                    let semanticBase = SymbolFamilyClassifier.ordinalStem(
                        for: structuralBase,
                        counts: ordinalCounts
                    ) ?? structuralBase
                    return (name, semanticBase)
                }
            )

            let uniqueSemanticBases = Set(semanticBases.values)
            let prefixCounts = SymbolFamilyClassifier.prefixDescendantCounts(
                for: uniqueSemanticBases
            )

            familyByName = Dictionary(
                uniqueKeysWithValues: allNames.map { name in
                    let semanticBase = semanticBases[name] ?? name
                    let root = SymbolFamilyClassifier.browseRoot(
                        for: semanticBase,
                        allNames: allNames,
                        prefixCounts: prefixCounts
                    )
                    return (name, root)
                }
            )
        }

        func familyKey(for name: String) -> String {
            let normalized = name.lowercased()
            return familyByName[normalized] ?? normalized
        }
    }

    private static func initialVisualBase(
        for name: String,
        fillToNoFill: [String: String]
    ) -> String {
        var current = name.lowercased()
        var visited: Set<String> = []

        while visited.insert(current).inserted {
            var parts = current.split(separator: ".").map(String.init)

            if let last = parts.last,
               localizationSuffixes.contains(last),
               parts.count > 1 {
                parts.removeLast()
                current = parts.joined(separator: ".")
                continue
            }

            if let noFill = fillToNoFill[current] {
                current = noFill
                continue
            }

            if let last = parts.last,
               directVisualSuffixes.contains(last),
               parts.count > 1 {
                parts.removeLast()
                current = parts.joined(separator: ".")
                continue
            }

            break
        }

        return current
    }

    private static func structuralRoot(
        for name: String,
        allNames: Set<String>,
        descendantCounts: [String: Int]
    ) -> String {
        var current = name
        var visited: Set<String> = []

        while visited.insert(current).inserted,
              let parent = structuralParent(of: current) {
            let parentExists = allNames.contains(parent)
            let hasSiblingEvidence = (descendantCounts[parent] ?? 0) >= 2

            guard parentExists || hasSiblingEvidence else {
                break
            }

            current = parent
        }

        return current
    }

    private static func structuralParent(of name: String) -> String? {
        var parts = name.split(separator: ".").map(String.init)
        guard parts.count > 1,
              let last = parts.last,
              structuralSuffixes.contains(last)
        else {
            return nil
        }

        parts.removeLast()
        return parts.joined(separator: ".")
    }

    private static func structuralDescendantCounts(
        for names: Set<String>
    ) -> [String: Int] {
        var descendants: [String: Set<String>] = [:]

        for originalName in names {
            var current = originalName
            var visited: Set<String> = []

            while visited.insert(current).inserted,
                  let parent = structuralParent(of: current) {
                descendants[parent, default: []].insert(originalName)
                current = parent
            }
        }

        return descendants.mapValues(\.count)
    }

    /// Handles families whose changing value is the leading token, including
    /// 1.calendar ... 31.calendar and 1.magnifyingglass ... 9.magnifyingglass.
    private static func ordinalStemCounts(
        for names: Set<String>
    ) -> [String: Int] {
        var valuesByStem: [String: Set<Int>] = [:]

        for name in names {
            let parts = name.split(separator: ".").map(String.init)
            guard parts.count > 1,
                  let value = Int(parts[0])
            else {
                continue
            }

            let stem = parts.dropFirst().joined(separator: ".")
            valuesByStem[stem, default: []].insert(value)
        }

        return valuesByStem.mapValues(\.count)
    }

    private static func ordinalStem(
        for name: String,
        counts: [String: Int]
    ) -> String? {
        let parts = name.split(separator: ".").map(String.init)
        guard parts.count > 1,
              Int(parts[0]) != nil
        else {
            return nil
        }

        let stem = parts.dropFirst().joined(separator: ".")
        return (counts[stem] ?? 0) >= 2 ? stem : nil
    }

    private static func prefixDescendantCounts(
        for names: Set<String>
    ) -> [String: Int] {
        var descendants: [String: Set<String>] = [:]

        for name in names {
            let parts = name.split(separator: ".").map(String.init)

            for depth in 1...parts.count {
                let prefix = parts.prefix(depth).joined(separator: ".")
                descendants[prefix, default: []].insert(name)
            }
        }

        return descendants.mapValues(\.count)
    }

    /// Chooses the shallowest useful prefix whose semantic fan-out remains
    /// browseable. Very broad roots therefore split themselves without a list
    /// of special cases for names such as arrow or person.
    private static func browseRoot(
        for name: String,
        allNames: Set<String>,
        prefixCounts: [String: Int]
    ) -> String {
        let parts = name.split(separator: ".").map(String.init)
        guard parts.count > 1 else { return name }

        for depth in 1..<parts.count {
            let prefixParts = parts.prefix(depth)
            guard let last = prefixParts.last,
                  !connectorTokens.contains(last)
            else {
                continue
            }

            let prefix = prefixParts.joined(separator: ".")
            let branchCount = prefixCounts[prefix] ?? 0
            let isConcreteSingleTokenRoot = depth > 1 || allNames.contains(prefix)

            if isConcreteSingleTokenRoot,
               (2...maximumSemanticBranches).contains(branchCount) {
                return prefix
            }
        }

        return name
    }
}
