import SwiftUI

struct SymbolFamilyPickerView: View {
    let family: SymbolFamily
    let favorites: Set<String>
    @Binding var selection: Set<String>
    let isSelecting: Bool
    let onChoose: (SymbolItem) -> Void

    @Environment(\.dismiss) private var dismiss

    private let columns = [
        GridItem(.adaptive(minimum: 104, maximum: 150), spacing: 12)
    ]

    private var selectedCount: Int {
        family.variants.reduce(into: 0) { count, item in
            if selection.contains(item.name) {
                count += 1
            }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AmbientBackground()

                ScrollView {
                    VStack(spacing: 18) {
                        header

                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(family.variants) { item in
                                variantCell(item)
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle(family.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("완료") { dismiss() }
                }
            }
        }
    }

    private var header: some View {
        HStack(spacing: 16) {
            Image(systemName: family.representative.name)
                .font(.system(size: 42, weight: .regular))
                .symbolRenderingMode(.hierarchical)
                .frame(width: 72, height: 72)
                .adaptiveGlass(cornerRadius: 22)

            VStack(alignment: .leading, spacing: 5) {
                Text(family.key)
                    .font(.headline.monospaced())
                    .lineLimit(2)

                Text("\(family.variants.count)개의 개별 심볼")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if isSelecting && selectedCount > 0 {
                    Text("\(selectedCount)개 선택됨")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
    }

    private func variantCell(_ item: SymbolItem) -> some View {
        let isSelected = selection.contains(item.name)
        let isFavorite = favorites.contains(item.name)

        return Button {
            if isSelecting {
                withAnimation(.snappy) {
                    if isSelected {
                        selection.remove(item.name)
                    } else {
                        selection.insert(item.name)
                    }
                }
            } else {
                onChoose(item)
            }
        } label: {
            VStack(spacing: 12) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: item.name)
                        .font(.system(size: 36, weight: .regular))
                        .symbolRenderingMode(.hierarchical)
                        .frame(maxWidth: .infinity, minHeight: 54)

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title3)
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(Color(.systemBackground), Color.accentColor)
                    } else if isFavorite {
                        Image(systemName: "heart.fill")
                            .font(.caption)
                            .foregroundStyle(.pink)
                    }
                }

                Text(item.name)
                    .font(.caption.monospaced())
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }
            .padding(12)
            .frame(minHeight: 120)
            .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .adaptiveGlass(cornerRadius: 20, interactive: true)
            .overlay {
                if isSelected {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.accentColor, lineWidth: 2)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(item.title)
        .accessibilityHint(isSelecting ? "선택 상태를 전환합니다" : "개별 심볼 상세 보기를 엽니다")
    }
}
