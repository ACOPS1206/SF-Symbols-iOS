import SwiftUI

struct SymbolDetailView: View {
    let item: SymbolItem
    let isFavorite: Bool
    @Binding var settings: ExportSettings
    let onToggleFavorite: () -> Void
    let onExport: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    preview
                    settingsForm
                    Button(action: onExport) {
                        Label("\(settings.format.rawValue)로 저장", systemImage: "arrow.down.doc.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .foregroundStyle(Color(.systemBackground))
                            .background(Color.accentColor, in: Capsule())
                    }
                    .buttonStyle(.plain)

                    if settings.format == .svg {
                        Label("SVG에는 원본 벡터 경로 대신 PNG 이미지가 포함됩니다.", systemImage: "info.circle")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding()
            }
            .background(AmbientBackground())
            .navigationTitle(item.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: onToggleFavorite) {
                        Image(systemName: isFavorite ? "heart.fill" : "heart")
                            .foregroundStyle(isFavorite ? .pink : .primary)
                    }
                    .accessibilityLabel(isFavorite ? "즐겨찾기에서 제거" : "즐겨찾기에 추가")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("완료") { dismiss() }
                }
            }
        }
    }

    private var preview: some View {
        ZStack {
            previewBackground
            Image(systemName: item.name)
                .font(.system(size: 104, weight: settings.weight.fontWeight))
                .symbolRenderingStyle(settings)
                .contentTransition(.symbolEffect(.replace))
        }
        .frame(maxWidth: .infinity)
        .frame(height: 240)
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        .adaptiveGlass(cornerRadius: 32)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(item.title) 미리보기")
    }

    @ViewBuilder
    private var previewBackground: some View {
        switch settings.background {
        case .transparent:
            Color.clear
        case .white:
            Color.white
        case .black:
            Color.black
        }
    }

    private var settingsForm: some View {
        VStack(spacing: 0) {
            settingRow("형식", systemImage: "doc") {
                Picker("형식", selection: $settings.format) {
                    ForEach(ExportFormat.allCases) { format in
                        Text(format.rawValue).tag(format)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 180)
            }

            Divider().padding(.leading, 44)

            settingRow("크기", systemImage: "arrow.up.left.and.arrow.down.right") {
                Picker("크기", selection: $settings.size) {
                    ForEach([128, 256, 512, 1024], id: \.self) { size in
                        Text("\(size) px").tag(size)
                    }
                }
            }

            Divider().padding(.leading, 44)

            settingRow("굵기", systemImage: "bold") {
                Picker("굵기", selection: $settings.weight) {
                    ForEach(SymbolWeight.allCases) { weight in
                        Text(weight.rawValue).tag(weight)
                    }
                }
            }

            Divider().padding(.leading, 44)

            settingRow("렌더링", systemImage: "circle.lefthalf.filled") {
                Picker("렌더링", selection: $settings.renderingStyle) {
                    ForEach(SymbolRenderingStyle.allCases) { style in
                        Text(style.rawValue).tag(style)
                    }
                }
            }

            if settings.renderingStyle != .multicolor {
                Divider().padding(.leading, 44)

                settingRow(settings.renderingStyle == .palette ? "주 색상" : "색상", systemImage: "paintpalette") {
                    Picker("색상", selection: $settings.tint) {
                        ForEach(ExportTint.allCases) { tint in
                            Text(tint.rawValue).tag(tint)
                        }
                    }
                }
            }

            if settings.renderingStyle == .palette {
                Divider().padding(.leading, 44)

                settingRow("보조 색상", systemImage: "paintpalette.fill") {
                    Picker("보조 색상", selection: $settings.secondaryTint) {
                        ForEach(ExportTint.allCases) { tint in
                            Text(tint.rawValue).tag(tint)
                        }
                    }
                }
            }

            Divider().padding(.leading, 44)

            settingRow("배경", systemImage: "square.on.square") {
                Picker("배경", selection: $settings.background) {
                    ForEach(ExportBackground.allCases) { background in
                        Text(background.rawValue).tag(background)
                    }
                }
            }
        }
        .padding(.horizontal, 14)
        .adaptiveGlass(cornerRadius: 24)
    }

    private func settingRow<Control: View>(
        _ title: String,
        systemImage: String,
        @ViewBuilder control: () -> Control
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .foregroundStyle(.secondary)
                .frame(width: 24)
            Text(title)
            Spacer()
            control()
        }
        .frame(minHeight: 54)
    }
}
