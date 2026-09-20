import SwiftUI

struct SettingsView: View {
    @Binding var language: AppLanguage
    @Binding var accent: AccentChoice
    @Binding var exportSettings: ExportSettings

    private let repositoryURL = URL(string: "https://github.com/ACOPS1206/SF-Symbols-iOS")!

    var body: some View {
        Form {
            Section("일반") {
                Picker("언어", selection: $language) {
                    ForEach(AppLanguage.allCases) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(.navigationLink)

                Picker("강조 색", selection: $accent) {
                    ForEach(AccentChoice.allCases) { option in
                        Label {
                            Text(option.title)
                        } icon: {
                            Circle()
                                .fill(option.color)
                                .frame(width: 18, height: 18)
                                .overlay { Circle().stroke(.primary.opacity(0.2)) }
                        }
                        .tag(option)
                    }
                }
                .pickerStyle(.navigationLink)
            }

            Section("기본 다운로드 옵션") {
                Picker("형식", selection: $exportSettings.format) {
                    ForEach(ExportFormat.allCases) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(.navigationLink)

                Picker("크기", selection: $exportSettings.size) {
                    ForEach([128, 256, 512, 1024], id: \.self) { size in
                        Text("\(size) px").tag(size)
                    }
                }
                .pickerStyle(.navigationLink)

                Picker("굵기", selection: $exportSettings.weight) {
                    ForEach(SymbolWeight.allCases) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(.navigationLink)

                Picker("아이콘 색", selection: $exportSettings.tint) {
                    ForEach(ExportTint.allCases) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(.navigationLink)

                Picker("배경", selection: $exportSettings.background) {
                    ForEach(ExportBackground.allCases) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(.navigationLink)
            }

            Section {
                Link(destination: repositoryURL) {
                    Label("GitHub", systemImage: "chevron.left.forwardslash.chevron.right")
                }
            } header: {
                Text("프로젝트")
            } footer: {
                Text("ACOPS1206/SF-Symbols-iOS")
            }
        }
        .navigationTitle("설정")
        .navigationBarTitleDisplayMode(.large)
    }
}
