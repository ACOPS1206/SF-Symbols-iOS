import SwiftUI

struct SymbolDetailView: View {
    let item: SymbolItem
    let isFavorite: Bool
    @Binding var settings: ExportSettings
    let onToggleFavorite: () -> Void
    let onExport: () -> Void
    let onShare: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    preview
                    settingsForm
                    HStack(spacing: 12) {
                        Button(action: onShare) {
                            Label("공유", systemImage: "square.and.arrow.up")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .adaptiveGlass(cornerRadius: 26, interactive: true)
                        }
                        .buttonStyle(.plain)

                        Button(action: onExport) {
                            Label("저장", systemImage: "arrow.down.doc.fill")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .foregroundStyle(Color(.systemBackground))
                                .background(Color.accentColor, in: Capsule())
                        }
                        .buttonStyle(.plain)
                    }

                    if settings.format == .svg {
                        Label(svgDescription, systemImage: "info.circle")
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

            if settings.format == .svg {
                settingRow("SVG로 변환", systemImage: "point.3.connected.trianglepath.dotted") {
                    Toggle("SVG로 변환", isOn: vectorizesSVGBinding)
                        .labelsHidden()
                }
            }

            if !settings.usesVectorSVG {
                settingRow(settings.format == .svg ? "포함 PNG" : "크기", systemImage: "arrow.up.left.and.arrow.down.right") {
                    Picker(settings.format == .svg ? "포함 PNG" : "크기", selection: $settings.size) {
                        ForEach([128, 256, 512, 1024], id: \.self) { size in
                            Text("\(size) px").tag(size)
                        }
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

            if !settings.usesVectorSVG {
                settingRow("렌더링", systemImage: "circle.lefthalf.filled") {
                    Picker("렌더링", selection: $settings.renderingStyle) {
                        ForEach(SymbolRenderingStyle.allCases) { style in
                            Text(style.rawValue).tag(style)
                        }
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

    private var vectorizesSVGBinding: Binding<Bool> {
        Binding(
            get: { settings.vectorizesSVG },
            set: { enabled in
                settings.vectorizesSVG = enabled
                if enabled {
                    settings.renderingStyle = .monochrome
                }
            }
        )
    }

    private var svgDescription: String {
        if settings.usesVectorSVG {
            return "고해상도 윤곽선을 추적해 단색 SVG 경로로 변환합니다. 결과는 원본 벡터와 다를 수 있습니다."
        }
        return "호환 SVG에는 벡터 경로 대신 선택한 해상도의 PNG가 포함됩니다."
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
