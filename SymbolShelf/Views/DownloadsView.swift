import SwiftUI

struct DownloadsView: View {
    let records: [DownloadRecord]
    let symbolCount: Int
    let onDownloadAll: () -> Void
    let onClearHistory: () -> Void

    var body: some View {
        LazyVStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text("다운로드")
                    .font(.largeTitle.bold())
                Text("내보낸 파일 기록과 전체 아이콘 묶음을 관리합니다.")
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 4)

            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("전체 아이콘")
                            .font(.headline)
                        Text("앱에 포함된 \(symbolCount)개 아이콘")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "square.stack.3d.up.fill")
                        .font(.title2)
                }
                Button(action: onDownloadAll) {
                    Label("전체 아이콘 ZIP 저장", systemImage: "arrow.down.doc.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .foregroundStyle(.black)
                        .background(Color.accentColor, in: Capsule())
                }
                .buttonStyle(.plain)
            }
            .padding(18)
            .adaptiveGlass(cornerRadius: 26)

            HStack {
                Text("최근 다운로드")
                    .font(.title3.bold())
                Spacer()
                if !records.isEmpty {
                    Button("기록 지우기", role: .destructive, action: onClearHistory)
                        .font(.subheadline)
                }
            }

            if records.isEmpty {
                ContentUnavailableView(
                    "다운로드 기록 없음",
                    systemImage: "arrow.down.circle",
                    description: Text("아이콘을 저장하면 여기에 기록됩니다.")
                )
                .frame(maxWidth: .infinity, minHeight: 260)
                .adaptiveGlass(cornerRadius: 26)
            } else {
                VStack(spacing: 0) {
                    ForEach(records) { record in
                        HStack(spacing: 12) {
                            Image(systemName: record.itemCount > 1 ? "archivebox.fill" : "photo.fill")
                                .font(.title3)
                                .frame(width: 34, height: 34)
                                .background(.primary.opacity(0.08), in: Circle())
                            VStack(alignment: .leading, spacing: 3) {
                                Text(record.name)
                                    .font(.subheadline.weight(.semibold))
                                    .lineLimit(1)
                                Text("\(record.itemCount)개 · \(record.format) · \(record.date.formatted(date: .abbreviated, time: .shortened))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Color.accentColor)
                        }
                        .padding(.horizontal, 14)
                        .frame(minHeight: 64)
                        if record.id != records.last?.id {
                            Divider().padding(.leading, 60)
                        }
                    }
                }
                .adaptiveGlass(cornerRadius: 24)
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 120)
    }
}
