import SwiftUI
import UniformTypeIdentifiers
import UIKit

struct ContentView: View {
    private let columns = [GridItem(.adaptive(minimum: 104, maximum: 150), spacing: 12)]

    @State private var query = ""
    @State private var category: SymbolCategory = .all
    @State private var selection = Set<String>()
    @State private var selectedSymbol: SymbolItem?
    @State private var isSelecting = false
    @State private var isSearchPresented = false
    @State private var showsFill = false
    @State private var showsSlash = false
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

    private var presentedCatalog: [SymbolItem] {
        var seen = Set<String>()
        return SymbolCatalog.items.compactMap { item in
            let baseName = canonicalName(item.name)
            guard seen.insert(baseName).inserted else { return nil }
            return SymbolItem(name: presentedName(for: baseName), category: item.category)
        }
    }

    private var filteredItems: [SymbolItem] {
        presentedCatalog.filter { item in
            let baseName = canonicalName(item.name)
            let categoryMatches: Bool
            switch category {
            case .all: categoryMatches = true
            case .favorites: categoryMatches = favorites.contains(baseName)
            default: categoryMatches = item.category == category
            }
            let queryMatches = query.isEmpty
                || item.name.localizedCaseInsensitiveContains(query)
                || baseName.localizedCaseInsensitiveContains(query)
                || item.title.localizedCaseInsensitiveContains(query)
            return categoryMatches && queryMatches
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AmbientBackground()
                ScrollView {
                    VStack(spacing: 16) {
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
            .toolbar(.hidden, for: .navigationBar)
            .safeAreaInset(edge: .top, spacing: 6) {
                HStack {
                    topMenuButton
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 4)
            }
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 10) {
                    if isSelecting {
                        selectionBar
                    }
                    bottomControls
                }
                .padding(.horizontal)
                .padding(.bottom, 6)
            }
            .sheet(item: $selectedSymbol) { item in
                SymbolDetailView(
                    item: item,
                    isFavorite: favorites.contains(canonicalName(item.name)),
                    settings: $settings,
                    onToggleFavorite: { toggleFavorite(canonicalName(item.name)) },
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

    private var topMenuButton: some View {
        Menu {
            Toggle(isOn: $showsFill) {
                Label("Fill 보기", systemImage: "circle.fill")
            }
            Toggle(isOn: $showsSlash) {
                Label("Slash 보기", systemImage: "circle.slash")
            }
            Divider()
            Button {
                withAnimation(.snappy) {
                    isSelecting.toggle()
                    if !isSelecting { selection.removeAll() }
                }
            } label: {
                Label(isSelecting ? "선택 완료" : "여러 개 선택", systemImage: isSelecting ? "checkmark" : "checkmark.circle")
            }
            Button {
                withAnimation(.snappy) {
                    showsFill = false
                    showsSlash = false
                    category = .all
                    query = ""
                }
            } label: {
                Label("필터 초기화", systemImage: "arrow.counterclockwise")
            }
        } label: {
            Image(systemName: "line.3.horizontal")
                .font(.system(size: 22, weight: .semibold))
                .frame(width: 58, height: 58)
                .adaptiveGlass(cornerRadius: 29, interactive: true)
        }
        .accessibilityLabel("보기 메뉴")
    }

    private var bottomControls: some View {
        VStack(spacing: 10) {
            if isSearchPresented {
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("심볼 이름 검색", text: $query)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    if !query.isEmpty {
                        Button {
                            query = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                        .accessibilityLabel("검색어 지우기")
                    }
                }
                .padding(.horizontal, 16)
                .frame(height: 52)
                .adaptiveGlass(cornerRadius: 26, interactive: true)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            HStack(spacing: 10) {
                categoryBar

                Button {
                    withAnimation(.snappy) { isSearchPresented.toggle() }
                } label: {
                    Image(systemName: isSearchPresented ? "xmark" : "magnifyingglass")
                        .font(.system(size: 23, weight: .semibold))
                        .frame(width: 66, height: 66)
                        .adaptiveGlass(cornerRadius: 33, interactive: true)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isSearchPresented ? "검색 닫기" : "검색 열기")
            }
        }
    }

    private var categoryBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                ForEach(SymbolCategory.allCases) { option in
                    Button {
                        withAnimation(.snappy) { category = option }
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: option.icon)
                                .font(.system(size: 20, weight: .semibold))
                            Text(option.rawValue)
                                .font(.caption2.weight(.semibold))
                                .lineLimit(1)
                        }
                        .frame(minWidth: 68, minHeight: 58)
                        .foregroundStyle(category == option ? Color.accentColor : Color.primary)
                        .background(
                            category == option ? Color.primary.opacity(0.1) : Color.clear,
                            in: RoundedRectangle(cornerRadius: 22, style: .continuous)
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(category == option ? .isSelected : [])
                }
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 66)
        .adaptiveGlass(cornerRadius: 33, interactive: true)
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
                            .foregroundStyle(.white, Color.accentColor)
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
            let items = presentedCatalog.filter { selection.contains(canonicalName($0.name)) }
            exportDocument = BinaryDocument(data: try SymbolExporter.zipData(for: items, settings: settings))
            exportType = .zip
            exportFilename = "SF-Symbols-\(items.count).zip"
            isExporting = true
        } catch {
            exportError = error.localizedDescription
        }
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
            candidates = [
                "\(baseName).slash.fill",
                "\(baseName).fill.slash",
                "\(baseName).slash",
                "\(baseName).fill",
                baseName
            ]
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
