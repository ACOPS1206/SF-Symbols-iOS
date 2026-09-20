import Foundation

enum ZipArchiveWriter {
    struct Entry {
        let path: String
        let data: Data
    }

    static func archive(entries: [Entry]) -> Data {
        var output = Data()
        var centralDirectory = Data()

        for entry in entries {
            let name = Data(entry.path.utf8)
            let crc = CRC32.checksum(entry.data)
            let localOffset = UInt32(output.count)
            let size = UInt32(entry.data.count)

            output.appendLE(UInt32(0x04034b50))
            output.appendLE(UInt16(20))
            output.appendLE(UInt16(0x0800))
            output.appendLE(UInt16(0))
            output.appendLE(UInt16(0))
            output.appendLE(UInt16(0))
            output.appendLE(crc)
            output.appendLE(size)
            output.appendLE(size)
            output.appendLE(UInt16(name.count))
            output.appendLE(UInt16(0))
            output.append(name)
            output.append(entry.data)

            centralDirectory.appendLE(UInt32(0x02014b50))
            centralDirectory.appendLE(UInt16(20))
            centralDirectory.appendLE(UInt16(20))
            centralDirectory.appendLE(UInt16(0x0800))
            centralDirectory.appendLE(UInt16(0))
            centralDirectory.appendLE(UInt16(0))
            centralDirectory.appendLE(UInt16(0))
            centralDirectory.appendLE(crc)
            centralDirectory.appendLE(size)
            centralDirectory.appendLE(size)
            centralDirectory.appendLE(UInt16(name.count))
            centralDirectory.appendLE(UInt16(0))
            centralDirectory.appendLE(UInt16(0))
            centralDirectory.appendLE(UInt16(0))
            centralDirectory.appendLE(UInt16(0))
            centralDirectory.appendLE(UInt32(0))
            centralDirectory.appendLE(localOffset)
            centralDirectory.append(name)
        }

        let directoryOffset = UInt32(output.count)
        output.append(centralDirectory)
        output.appendLE(UInt32(0x06054b50))
        output.appendLE(UInt16(0))
        output.appendLE(UInt16(0))
        output.appendLE(UInt16(entries.count))
        output.appendLE(UInt16(entries.count))
        output.appendLE(UInt32(centralDirectory.count))
        output.appendLE(directoryOffset)
        output.appendLE(UInt16(0))
        return output
    }
}

private enum CRC32 {
    static func checksum(_ data: Data) -> UInt32 {
        var crc = UInt32.max
        for byte in data {
            var value = (crc ^ UInt32(byte)) & 0xff
            for _ in 0..<8 {
                value = (value & 1) == 1 ? (value >> 1) ^ 0xedb88320 : value >> 1
            }
            crc = (crc >> 8) ^ value
        }
        return crc ^ UInt32.max
    }
}

private extension Data {
    mutating func appendLE<T: FixedWidthInteger>(_ value: T) {
        var littleEndian = value.littleEndian
        Swift.withUnsafeBytes(of: &littleEndian) { append(contentsOf: $0) }
    }
}
