import Foundation

@main
enum SymbolFamilyClassifierSmokeTests {
    static func main() {
        var names = [
            "phone", "phone.fill", "phone.pause", "phone.pause.fill",
            "calendar", "calendar.badge.plus", "1.calendar", "2.calendar", "31.calendar",
            "character.bubble", "character.bubble.fill", "character.bubble.bn",
            "character.bubble.fill.bn",
            "arrow", "arrow.up", "arrow.up.fill", "arrow.up.circle.fill", "arrow.down",
            "person", "person.badge.plus", "person.badge.plus.fill", "person.badge.minus"
        ]

        // A realistic catalog has very broad arrow/person roots. Add enough
        // semantic branches to ensure the fan-out limiter splits them.
        names += (0..<30).map { "arrow.testbranch\($0)" }
        names += (0..<30).map { "person.testbranch\($0)" }

        let index = SymbolFamilyClassifier.Index(
            names: names,
            noFillToFill: [
                "phone": "phone.fill",
                "phone.pause": "phone.pause.fill",
                "character.bubble": "character.bubble.fill"
            ]
        )

        expect(index, "phone.pause.fill", family: "phone")
        expect(index, "1.calendar", family: "calendar")
        expect(index, "31.calendar", family: "calendar")
        expect(index, "character.bubble.fill.bn", family: "character.bubble")
        expect(index, "arrow.up.circle.fill", family: "arrow.up")
        expect(index, "arrow.down", family: "arrow.down")
        expect(index, "person.badge.plus.fill", family: "person.badge")
    }

    private static func expect(
        _ index: SymbolFamilyClassifier.Index,
        _ name: String,
        family expected: String
    ) {
        let actual = index.familyKey(for: name)
        precondition(
            actual == expected,
            "Expected \(name) -> \(expected), got \(actual)"
        )
    }
}
