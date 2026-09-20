import SwiftUI
import UniformTypeIdentifiers
import UIKit

struct ContentView: View {
    private let columns = [GridItem(.adaptive(minimum: 104, maximum: 150), spacing: 12)]

    @State private var currentSection: AppSection = .icons
    @State private var query = ""
    @State private var category: SymbolCategory = .all
    @State private var selection = Set<String>()
    @State private var selectedSymbol: SymbolItem?
    @State private var isSelecting = false
    @State private var showsFill = false
    @State private var showsSlash = false
    @State private var settings = ExportSettings()
    @State private var exportDocument = BinaryDocument()
    @State private var exportType: UTType = .data
    @State private var exportFilename = "Symbols.zip"
    @State private var isExporting = false
    @State private var exportError: String?
    @State private var pendingDownload: DownloadRecord?

    @AppStorage("favoriteSymbols") private var favoriteSymbols = ""
    @AppStorage("appLanguage") private var appLanguage = AppLanguage.korean.rawValue
    @AppStorage("accentChoice") private var accentChoice = AccentChoice.white.rawValue
    @AppStorage("defaultExportSize") private var defaultExportSize = 512
    @AppStorage("defaultExportFormat") private var defaultExportFormat = ExportFormat.png.rawValue
    @AppStorage("defaultExportWeight") private var defaultExportWeight = SymbolWeight.regular.rawValue
    @AppStorage("defaultExportBackground") private var defaultExportBackground = ExportBackground.transparent.rawValue
    @AppStorage("defaultExportTint") private var defaultExportTint = ExportTint.primary.rawValue
    @AppStorage("downloadHistory") private var downloadHistory = Data()

    private var favorites: Set<String> {
        Set(favoriteSymbols.split(separator: ",").map(String.init))
    }

    private var languageBinding: Binding<AppLanguage> {
        Binding(
            get: { AppLanguage(rawValue: appLanguage) ?? .korean },
            set: { appLanguage = $0.rawValue }
        )
    }

    private var accentBinding: Binding<AccentChoice> {
        Binding(
            get: { AccentChoice(rawValue: accentChoice) ?? .white },
            set: { accentChoice = $0.rawValue }
        )
    }

    private var downloadRecords: [DownloadRecord] {
        (try? JSONDecoder().decode([DownloadRecord].self, from: downloadHistory)) ?? []
    }

    private var presentedCatalog: [SymbolItem] {
        var seen = Set<String>()
        return SymbolCatalog.items.compactMap { item in
            let baseName = canonicalName(item.name)
            guard seen.insert(baseName).inserted else { return nil }
            return SymbolItem(name: presentedName(for: baseName), category: item.category)
        }
    }

    var body: some View {
        nativeTabs
            .nativeTabBarBehavior()
            .adaptiveTabAccessory(
                isEnabled: currentSection == .icons || currentSection == .search
            ) {
                if isSelecting {
                    selectionBar
                } else {
                    categoryBar
                }
            }
            .sheet(item: $selectedSymbol) { item in
                SymbolDetailView(
                    item: item,
                    isFavorite: favorites.contains(canonicalName(item.name)),
                    settings: $settings,
                    onToggleFavorite: { toggleFavorite(canonicalName(item.name)) },
                    onExport: { exportSingle(item) }
                )
                .presentationDragIndicator(.visible)
            }
            .fileExporter(
                isPresented: $isExporting,
                document: exportDocument,
                contentType: exportType,
                defaultFilename: exportFilename
            ) { result in
                switch result {
                case .success:
                    if let pendingDownload {
                        addDownloadRecord(pendingDownload)
                    }
                case .failure(let error):
                    exportError = error.localizedDescription
                }
                pendingDownload = nil
            }
            .alert("내보내기 실패", isPresented: Binding(
                get: { exportError != nil },
                set: { if !$0 { exportError = nil } }
            )) {
                Button("확인", role: .cancel) { exportError = nil }
            } message: {
                Text(exportError ?? "알 수 없는 오류가 발생했습니다.")
            }
            .onAppear(perform: loadDefaultSettings)
            .onChange(of: settings) { _, newValue in
                saveDefaultSettings(newValue)
            }
            .onChange(of: currentSection) { _, newValue in
                if newValue != .icons && newValue != .search {
                    isSelecting = false
                    selection.removeAll()
                }
            }
    }

    private var nativeTabs: some View {
        TabView(selection: $currentSection) {
            Tab("아이콘", systemImage: "square.grid.2x2", value: AppSection.icons) {
                iconBrowser(searchEnabled: false)
            }

            Tab("설정", systemImage: "gearshape", value: AppSection.settings) {
                NavigationStack {
                    SettingsView(
                        language: languageBinding,
                        accent: accentBinding,
                        exportSettings: $settings
                    )
                }
            }

            Tab("다운로드", systemImage: "arrow.down.circle", value: AppSection.downloads) {
                NavigationStack {
                    DownloadsView(
                        records: downloadRecords,
                        symbolCount: presentedCatalog.count,
                        onDownloadAll: exportAll,
                        onClearHistory: { downloadHistory = Data() }
                    )
                }
            }

            Tab(value: AppSection.search, role: .search) {
                iconBrowser(searchEnabled: true)
            }
        }
    }

    @ViewBuilder
    private func iconBrowser(searchEnabled: Bool) -> some View {
        if searchEnabled {
            iconNavigation(searchEnabled: true)
                .searchable(
                    text: $query,
                    placement: .automatic,
                    prompt: "심볼 이름 검색"
                )
        } else {
            iconNavigation(searchEnabled: false)
        }
    }

    private func iconNavigation(searchEnabled: Bool) -> some View {
        NavigationStack {
            ZStack {
                AmbientBackground()
                ScrollView {
                    iconGrid(searchEnabled: searchEnabled)
                        .padding(.bottom, 20)
                }
            }
            .navigationTitle(searchEnabled ? "검색" : "아이콘")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(isSelecting ? "완료" : "선택") {
                        withAnimation(.snappy) {
                            isSelecting.toggle()
                            if !isSelecting { selection.removeAll() }
                        }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    filterMenu
                }
            }
        }
    }

    @ViewBuilder
    private var categoryBar: some View {
        if #available(iOS 26.0, *) {
            liquidGlassCategoryBar
        } else {
            segmentedCategoryBar
        }
    }

    @available(iOS 26.0, *)
    private var liquidGlassCategoryBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(SymbolCategory.allCases) { option in
                    categoryButton(option)
                }
            }
        }
        .contentMargins(.horizontal, 12, for: .scrollContent)
        .contentMargins(.vertical, 6, for: .scrollContent)
        .frame(minHeight: 54)
        .accessibilityLabel("카테고리")
    }

    @available(iOS 26.0, *)
    @ViewBuilder
    private func categoryButton(_ option: SymbolCategory) -> some View {
        if category == option {
            Button {
                selectCategory(option)
            } label: {
                categoryLabel(option)
            }
            .buttonStyle(.glassProminent)
        } else {
            Button {
                selectCategory(option)
            } label: {
                categoryLabel(option)
            }
            .buttonStyle(.plain)
        }
    }

    private func categoryLabel(_ option: SymbolCategory) -> some View {
        Label(option.rawValue, systemImage: option.icon)
            .font(.subheadline.weight(.semibold))
            .lineLimit(1)
            .padding(.horizontal, 8)
            .frame(minHeight: 36)
            .contentShape(Capsule())
    }

    private var segmentedCategoryBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            Picker("카테고리", selection: $category) {
                ForEach(SymbolCategory.allCases) { option in
                    Label(option.rawValue, systemImage: option.icon)
                        .labelStyle(.titleAndIcon)
                        .tag(option)
                }
            }
            .pickerStyle(.segmented)
            .controlSize(.large)
            .frame(width: CGFloat(SymbolCategory.allCases.count) * 116)
        }
        .contentMargins(.horizontal, 16, for: .scrollContent)
        .padding(.vertical, 4)
        .frame(minHeight: 52)
        .accessibilityLabel("카테고리")
    }

    private func selectCategory(_ option: SymbolCategory) {
        withAnimation(.snappy) {
            category = option
        }
    }

    @ViewBuilder
    private func iconGrid(searchEnabled: Bool) -> some View {
        let items = filteredItems(searchEnabled: searchEnabled)
        if items.isEmpty {
            ContentUnavailableView.search(text: query)
                .frame(minHeight: 420)
        } else {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(items) { item in
                    symbolCell(item)
                }
            }
            .padding(.horizontal)
        }
    }

    private var filterMenu: some View {
        Menu {
            Toggle(isOn: $showsFill) {
                Label("Fill 보기", systemImage: "circle.fill")
            }
            Toggle(isOn: $showsSlash) {
                Label("Slash 보기", systemImage: "circle.slash")
            }
            Divider()
            Button {
                showsFill = false
                showsSlash = false
                category = .all
                query = ""
            } label: {
                Label("필터 초기화", systemImage: "arrow.counterclockwise")
            }
        } label: {
            Image(systemName: "line.3.horizontal")
        }
        .accessibilityLabel("보기 메뉴")
    }

    private func filteredItems(searchEnabled: Bool) -> [SymbolItem] {
        presentedCatalog.filter { item in
            let baseName = canonicalName(item.name)
            let categoryMatches: Bool
            switch category {
            case .all: categoryMatches = true
            case .favorites: categoryMatches = favorites.contains(baseName)
            default: categoryMatches = item.category == category
            }

            guard searchEnabled else { return categoryMatches }
            let queryMatches = query.isEmpty
                || item.name.localizedCaseInsensitiveContains(query)
                || baseName.localizedCaseInsensitiveContains(query)
                || item.title.localizedCaseInsensitiveContains(query)
                || item.category.rawValue.localizedCaseInsensitiveContains(query)
            return categoryMatches && queryMatches
        }
    }

    private func symbolCell(_ item: SymbolItem) -> some View {
        let selectionKey = canonicalName(item.name)
        return Button {
            if isSelecting {
                toggleSelection(selectionKey)
            } else {
                selectedSymbol = item
            }
        } label: {
            VStack(spacing: 12) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: item.name)
                        .font(.system(size: 36, weight: .regular))
                        .symbolRenderingMode(.hierarchical)
                        .frame(maxWidth: .infinity, minHeight: 54)

                    if selection.contains(selectionKey) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title3)
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(Color(.systemBackground), Color.accentColor)
                    } else if favorites.contains(selectionKey) {
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
                if selection.contains(selectionKey) {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.accentColor, lineWidth: 2)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(item.title)
        .accessibilityHint(isSelecting ? "선택 상태를 전환합니다" : "상세 보기와 내보내기 설정을 엽니다")
    }

    private var selectionBar: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(selection.count)개 선택")
                    .font(.headline)
                Text(settings.format == .svg ? "호환 SVG · ZIP" : "PNG · ZIP")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Menu {
                Picker("형식", selection: $settings.format) {
                    ForEach(ExportFormat.allCases) { format in
                        Text(format.rawValue).tag(format)
                    }
                }
                Picker("크기", selection: $settings.size) {
                    ForEach([128, 256, 512, 1024], id: \.self) { size in
                        Text("\(size) px").tag(size)
                    }
                }
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("내보내기 설정")

            Button {
                exportSelection()
            } label: {
                Label("ZIP 저장", systemImage: "arrow.down.doc.fill")
                    .font(.headline)
                    .padding(.horizontal, 16)
                    .frame(height: 44)
                    .foregroundStyle(Color(.systemBackground))
                    .background(Color.accentColor, in: Capsule())
            }
            .buttonStyle(.plain)
            .disabled(selection.isEmpty)
        }
        .padding(.horizontal, 14)
        .frame(minHeight: 58)
    }

    private func toggleSelection(_ name: String) {
        if selection.contains(name) { selection.remove(name) } else { selection.insert(name) }
    }

    private func toggleFavorite(_ name: String) {
        var updated = favorites
        if updated.contains(name) { updated.remove(name) } else { updated.insert(name) }
        favoriteSymbols = updated.sorted().joined(separator: ",")
    }

    private func exportSingle(_ item: SymbolItem) {
        do {
            exportDocument = BinaryDocument(data: try SymbolExporter.data(for: item, settings: settings))
            exportType = settings.format == .png ? .png : .symbolSVG
            exportFilename = SymbolExporter.filename(for: item, settings: settings)
            pendingDownload = DownloadRecord(name: exportFilename, format: settings.format.rawValue, itemCount: 1)
            selectedSymbol = nil
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(250))
                isExporting = true
            }
        } catch {
            exportError = error.localizedDescription
        }
    }

    private func exportSelection() {
        do {
            let items = presentedCatalog.filter { selection.contains(canonicalName($0.name)) }
            exportDocument = BinaryDocument(data: try SymbolExporter.zipData(for: items, settings: settings))
            exportType = .zip
            exportFilename = "SF-Symbols-\(items.count).zip"
            pendingDownload = DownloadRecord(name: exportFilename, format: "ZIP · \(settings.format.rawValue)", itemCount: items.count)
            isExporting = true
        } catch {
            exportError = error.localizedDescription
        }
    }

    private func exportAll() {
        do {
            let items = presentedCatalog
            exportDocument = BinaryDocument(data: try SymbolExporter.zipData(for: items, settings: settings))
            exportType = .zip
            exportFilename = "SF-Symbols-All-\(items.count).zip"
            pendingDownload = DownloadRecord(name: exportFilename, format: "ZIP · \(settings.format.rawValue)", itemCount: items.count)
            isExporting = true
        } catch {
            exportError = error.localizedDescription
        }
    }

    private func addDownloadRecord(_ record: DownloadRecord) {
        var updated = downloadRecords
        updated.insert(record, at: 0)
        downloadHistory = (try? JSONEncoder().encode(Array(updated.prefix(50)))) ?? Data()
    }

    private func loadDefaultSettings() {
        settings = ExportSettings(
            size: defaultExportSize,
            weight: SymbolWeight(rawValue: defaultExportWeight) ?? .regular,
            format: ExportFormat(rawValue: defaultExportFormat) ?? .png,
            background: ExportBackground(rawValue: defaultExportBackground) ?? .transparent,
            tint: ExportTint(rawValue: defaultExportTint) ?? .primary
        )
    }

    private func saveDefaultSettings(_ value: ExportSettings) {
        defaultExportSize = value.size
        defaultExportWeight = value.weight.rawValue
        defaultExportFormat = value.format.rawValue
        defaultExportBackground = value.background.rawValue
        defaultExportTint = value.tint.rawValue
    }

    private func canonicalName(_ name: String) -> String {
        var parts = name.split(separator: ".").map(String.init)
        while let last = parts.last, last == "fill" || last == "slash" {
            parts.removeLast()
        }
        return parts.joined(separator: ".")
    }

    private func presentedName(for baseName: String) -> String {
        let candidates: [String]
        switch (showsSlash, showsFill) {
        case (true, true):
            candidates = ["\(baseName).slash.fill", "\(baseName).fill.slash", "\(baseName).slash", "\(baseName).fill", baseName]
        case (true, false):
            candidates = ["\(baseName).slash", baseName]
        case (false, true):
            candidates = ["\(baseName).fill", baseName]
        case (false, false):
            candidates = [baseName]
        }
        return candidates.first { UIImage(systemName: $0) != nil } ?? baseName
    }
}
