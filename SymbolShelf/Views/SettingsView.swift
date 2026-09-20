import SwiftUI

struct SettingsView: View {
    @Binding var language: AppLanguage
    @Binding var accent: AccentChoice
    @Binding var exportSettings: ExportSettings
    @Binding var automaticallyGroupsSymbols: Bool

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

            Section {
                Toggle(isOn: $automaticallyGroupsSymbols) {
                    HStack(spacing: 7) {
                        Text("아이콘 자동 분류")

                        Text("[메타]")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("아이콘")
            } footer: {
                Text("비슷한 심볼을 부모 아이콘 아래에 자동으로 묶습니다. 끄면 모든 심볼을 개별 아이콘으로 표시합니다.")
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

                Picker("렌더링", selection: $exportSettings.renderingStyle) {
                    ForEach(SymbolRenderingStyle.allCases) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(.navigationLink)

                if exportSettings.renderingStyle != .multicolor {
                    Picker(exportSettings.renderingStyle == .palette ? "주 색상" : "아이콘 색", selection: $exportSettings.tint) {
                        ForEach(ExportTint.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .pickerStyle(.navigationLink)
                }

                if exportSettings.renderingStyle == .palette {
                    Picker("보조 색상", selection: $exportSettings.secondaryTint) {
                        ForEach(ExportTint.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .pickerStyle(.navigationLink)
                }

                Picker("배경", selection: $exportSettings.background) {
                    ForEach(ExportBackground.allCases) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(.navigationLink)
            }

            Section {
                Text("멀티컬러를 지원하지 않는 심볼은 시스템 기본 표현으로 표시됩니다.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } header: {
                Text("렌더링 안내")
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
