import Foundation

enum DownloadError: LocalizedError {
    case invalidURL
    case httpStatus(Int)
    case writeFailed

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "The download URL is invalid."
        case .httpStatus(let code): return "Download failed with HTTP status \(code)."
        case .writeFailed: return "Could not write the downloaded file."
        }
    }
}

final class DownloadService {
    static let shared = DownloadService()

    private init() {}

    func download(
        from urlString: String,
        to destination: URL,
        progressHandler: @escaping @MainActor (Double) -> Void
    ) async throws {
        guard let url = URL(string: urlString) else { throw DownloadError.invalidURL }
        try? FileManager.default.removeItem(at: destination)
        try FileManager.default.createDirectory(
            at: destination.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        let (bytes, response) = try await URLSession.shared.bytes(from: url)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw DownloadError.httpStatus(http.statusCode)
        }
        let total = (response as? HTTPURLResponse)?.expectedContentLength ?? -1

        guard FileManager.default.createFile(atPath: destination.path, contents: nil) else {
            throw DownloadError.writeFailed
        }
        let handle = try FileHandle(forWritingTo: destination)
        defer { try? handle.close() }

        var received: Int64 = 0
        var buffer = Data()
        buffer.reserveCapacity(256 * 1024)
        var lastFraction = -1.0

        for try await byte in bytes {
            buffer.append(byte)
            received += 1
            if buffer.count >= 256 * 1024 {
                try handle.write(contentsOf: buffer)
                buffer.removeAll(keepingCapacity: true)
            }
            let fraction = total > 0 ? Double(received) / Double(total) : 0
            if fraction - lastFraction >= 0.005 {
                lastFraction = fraction
                let progress = fraction
                await MainActor.run { progressHandler(progress) }
            }
        }
        if !buffer.isEmpty {
            try handle.write(contentsOf: buffer)
        }
        try handle.close()
        await MainActor.run { progressHandler(1) }
    }
}
