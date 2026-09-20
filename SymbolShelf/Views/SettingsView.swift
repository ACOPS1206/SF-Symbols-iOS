import SwiftUI

struct SettingsView: View {
    @Binding var language: AppLanguage
    @Binding var accent: AccentChoice
    @Binding var exportSettings: ExportSettings

    private let repositoryURL = URL(string: "https://github.com/ACOPS1206/SF-Symbols-iOS")!

    var body: some View {
        LazyVStack(alignment: .leading, spacing: 20) {
            pageTitle
            settingsSection("일반") {
                settingRow("언어", systemImage: "globe") {
                    Picker("언어", selection: $language) {
                        ForEach(AppLanguage.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                }

                Divider().padding(.leading, 44)

                VStack(alignment: .leading, spacing: 12) {
                    Label("강조 색", systemImage: "paintpalette")
                    HStack(spacing: 12) {
                        ForEach(AccentChoice.allCases) { option in
                            Button {
                                accent = option
                            } label: {
                                Circle()
                                    .fill(option.color)
                                    .frame(width: 30, height: 30)
                                    .overlay {
                                        if accent == option {
                                            Image(systemName: "checkmark")
                                                .font(.caption.bold())
                                                .foregroundStyle(option == .white ? Color.black : Color.white)
                                        }
                                    }
                                    .overlay {
                                        Circle().stroke(.primary.opacity(0.25), lineWidth: 1)
                                    }
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(option.rawValue)
                            .accessibilityAddTraits(accent == option ? .isSelected : [])
                        }
                    }
                }
                .padding(.vertical, 12)
            }

            settingsSection("기본 다운로드 옵션") {
                settingRow("형식", systemImage: "doc") {
                    Picker("형식", selection: $exportSettings.format) {
                        ForEach(ExportFormat.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                }
                Divider().padding(.leading, 44)
                settingRow("크기", systemImage: "arrow.up.left.and.arrow.down.right") {
                    Picker("크기", selection: $exportSettings.size) {
                        ForEach([128, 256, 512, 1024], id: \.self) { size in
                            Text("\(size) px").tag(size)
                        }
                    }
                }
                Divider().padding(.leading, 44)
                settingRow("굵기", systemImage: "bold") {
                    Picker("굵기", selection: $exportSettings.weight) {
                        ForEach(SymbolWeight.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                }
                Divider().padding(.leading, 44)
                settingRow("아이콘 색", systemImage: "paintbrush") {
                    Picker("아이콘 색", selection: $exportSettings.tint) {
                        ForEach(ExportTint.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                }
                Divider().padding(.leading, 44)
                settingRow("배경", systemImage: "square.on.square") {
                    Picker("배경", selection: $exportSettings.background) {
                        ForEach(ExportBackground.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                }
            }

            settingsSection("프로젝트") {
                Link(destination: repositoryURL) {
                    HStack(spacing: 12) {
                        Image(systemName: "chevron.left.forwardslash.chevron.right")
                            .frame(width: 24)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("GitHub")
                            Text("ACOPS1206/SF-Symbols-iOS")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .foregroundStyle(.secondary)
                    }
                    .frame(minHeight: 54)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 120)
    }

    private var pageTitle: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("설정")
                .font(.largeTitle.bold())
            Text("화면과 다운로드 기본값을 관리합니다.")
                .foregroundStyle(.secondary)
        }
        .padding(.top, 4)
    }

    private func settingsSection<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.leading, 8)
            VStack(spacing: 0) { content() }
                .padding(.horizontal, 14)
                .adaptiveGlass(cornerRadius: 24)
        }
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
