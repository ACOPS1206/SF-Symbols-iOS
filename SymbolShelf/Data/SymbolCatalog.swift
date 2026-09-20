import UIKit

enum SymbolCatalog {
    static let items: [SymbolItem] = rawItems
        .filter { UIImage(systemName: $0.name) != nil }

    private static let rawItems: [SymbolItem] = [
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
}
