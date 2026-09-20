import SwiftUI
import UIKit

struct SharePayload: Identifiable {
    let id = UUID()
    let fileURL: URL
    let record: DownloadRecord
}

struct ShareSheet: UIViewControllerRepresentable {
    let payload: SharePayload
    let onComplete: (Bool) -> Void

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: [payload.fileURL],
            applicationActivities: nil
        )
        controller.completionWithItemsHandler = { _, completed, _, _ in
            onComplete(completed)
        }
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
