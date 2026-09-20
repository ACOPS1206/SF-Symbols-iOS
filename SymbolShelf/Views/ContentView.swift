import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    private let columns = [GridItem(.adaptive(minimum: 104, maximum: 150), spacing: 12)]

    @State private var query = ""
    @State private var category: SymbolCategory = .all
    @State private var selection = Set<String>()
    @State private var selectedSymbol: SymbolItem?
    @State private var isSelecting = false
    @State private var settings = ExportSettings()
    @State private var exportDocument = BinaryDocument()
    @State private var exportType: UTType = .data
    @State private var exportFilename = "Symbols.zip"
    @State private var isExporting = false
    @State private var exportError: String?
    @AppStorage("favoriteSymbols") private var favoriteSymbols = ""

    private var favorites: Set<String> {
        Set(favoriteSymbols.split(separator: ",").map(String.init))
    }

    private var filteredItems: [SymbolItem] {
        SymbolCatalog.items.filter { item in
            let categoryMatches: Bool
            switch category {
            case .all: categoryMatches = true
            case .favorites: categoryMatches = favorites.contains(item.name)
            default: categoryMatches = item.category == category
            }
            let queryMatches = query.isEmpty || item.name.localizedCaseInsensitiveContains(query) || item.title.localizedCaseInsensitiveContains(query)
            return categoryMatches && queryMatches
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AmbientBackground()
                ScrollView {
                    VStack(spacing: 16) {
                        categoryStrip
                        if filteredItems.isEmpty {
                            ContentUnavailableView(
                                "심볼을 찾을 수 없음",
                                systemImage: "magnifyingglass",
                                description: Text("다른 검색어나 카테고리를 사용해 보세요.")
                            )
                            .frame(minHeight: 420)
                        } else {
                            LazyVGrid(columns: columns, spacing: 12) {
                                ForEach(filteredItems) { item in
                                    symbolCell(item)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom, isSelecting ? 100 : 20)
                        }
                    }
                }
            }
            .navigationTitle("SF Symbols")
            .searchable(text: $query, prompt: "이름으로 검색")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(isSelecting ? "완료" : "선택") {
                        withAnimation(.snappy) {
                            isSelecting.toggle()
                            if !isSelecting { selection.removeAll() }
                        }
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                if isSelecting {
                    selectionBar
                        .padding(.horizontal)
                        .padding(.bottom, 6)
                }
            }
            .sheet(item: $selectedSymbol) { item in
                SymbolDetailView(
                    item: item,
                    isFavorite: favorites.contains(item.name),
                    settings: $settings,
                    onToggleFavorite: { toggleFavorite(item.name) },
                    onExport: { exportSingle(item) }
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
            .fileExporter(
                isPresented: $isExporting,
                document: exportDocument,
                contentType: exportType,
                defaultFilename: exportFilename
            ) { result in
                if case .failure(let error) = result {
                    exportError = error.localizedDescription
                }
            }
            .alert("내보내기 실패", isPresented: Binding(
                get: { exportError != nil },
                set: { if !$0 { exportError = nil } }
            )) {
                Button("확인", role: .cancel) { exportError = nil }
            } message: {
                Text(exportError ?? "알 수 없는 오류가 발생했습니다.")
            }
        }
    }

    private var categoryStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(SymbolCategory.allCases) { option in
                    Button {
                        withAnimation(.snappy) { category = option }
                    } label: {
                        Label(option.rawValue, systemImage: option.icon)
                            .font(.subheadline.weight(.semibold))
                            .padding(.horizontal, 14)
                            .frame(height: 40)
                            .foregroundStyle(category == option ? .white : .primary)
                            .background(category == option ? Color.accentColor : .clear, in: Capsule())
                            .adaptiveGlass(cornerRadius: 20, interactive: true)
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(category == option ? .isSelected : [])
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 4)
        }
    }

    private func symbolCell(_ item: SymbolItem) -> some View {
        Button {
            if isSelecting {
                toggleSelection(item.name)
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

                    if selection.contains(item.name) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title3)
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.white, Color.accentColor)
                    } else if favorites.contains(item.name) {
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
                if selection.contains(item.name) {
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
                    .font(.title3)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("내보내기 설정")

            Button {
                exportSelection()
            } label: {
                Label("ZIP 저장", systemImage: "arrow.down.doc.fill")
                    .font(.headline)
                    .padding(.horizontal, 16)
                    .frame(height: 46)
                    .foregroundStyle(.white)
                    .background(Color.accentColor, in: Capsule())
            }
            .disabled(selection.isEmpty)
        }
        .padding(12)
        .adaptiveGlass(cornerRadius: 26)
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
            let items = SymbolCatalog.items.filter { selection.contains($0.name) }
            exportDocument = BinaryDocument(data: try SymbolExporter.zipData(for: items, settings: settings))
            exportType = .zip
            exportFilename = "SF-Symbols-\(items.count).zip"
            isExporting = true
        } catch {
            exportError = error.localizedDescription
        }
    }
}
