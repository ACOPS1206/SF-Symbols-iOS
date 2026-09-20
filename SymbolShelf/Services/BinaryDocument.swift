import SwiftUI
import UniformTypeIdentifiers

struct BinaryDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.data, .png, .svg, .zip] }

    var data: Data

    init(data: Data = Data()) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

extension UTType {
    static var symbolSVG: UTType {
        UTType(filenameExtension: "svg") ?? .xml
    }
}
