import Foundation
import Observation

/// Observable owner of the clipboard history, persisted as JSON in Application Support.
///
/// Mutations happen on the main actor; encoding and disk writes run on a background queue.
@Observable
final class ClipboardStore {
    private(set) var history: ClipboardHistory

    @ObservationIgnored private let fileURL: URL
    @ObservationIgnored private let writer = DispatchQueue(label: "machelper.clipboard-store", qos: .utility)

    init(fileURL: URL) {
        self.fileURL = fileURL
        self.history = Self.load(from: fileURL)
    }

    func record(_ text: String, limit: Int) {
        mutate { $0.record(text, limit: limit) }
    }

    func remove(_ id: ClipboardItem.ID) {
        mutate { $0.remove(id) }
    }

    func clear() {
        mutate { $0.clear() }
    }

    // MARK: - Persistence

    private func mutate(_ change: (inout ClipboardHistory) -> Void) {
        var updated = history
        change(&updated)
        guard updated != history else { return }
        history = updated
        save(updated)
    }

    private func save(_ snapshot: ClipboardHistory) {
        let url = fileURL
        writer.async {
            do {
                try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
                try JSONEncoder().encode(snapshot).write(to: url, options: [.atomic, .completeFileProtection])
            } catch {
                NSLog("machelper: failed to save clipboard history: \(error)")
            }
        }
    }

    private static func load(from url: URL) -> ClipboardHistory {
        guard let data = try? Data(contentsOf: url),
              let history = try? JSONDecoder().decode(ClipboardHistory.self, from: data) else { return ClipboardHistory() }
        return history
    }

}
