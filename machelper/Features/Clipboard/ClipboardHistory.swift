import Foundation

nonisolated struct ClipboardItem: Codable, Hashable, Identifiable, Sendable {
    let id: UUID
    let text: String
    let copiedAt: Date

    init(text: String, copiedAt: Date = .now) {
        self.id = UUID()
        self.text = text
        self.copiedAt = copiedAt
    }
}

/// Newest-first list of copied text. Pure value logic: dedupe, ordering and size limit.
nonisolated struct ClipboardHistory: Codable, Equatable, Sendable {
    private(set) var items: [ClipboardItem] = []

    /// Adds `text` to the top. A repeated text moves to the top instead of duplicating.
    mutating func record(_ text: String, limit: Int, at date: Date = .now) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        items.removeAll { $0.text == text }
        items.insert(ClipboardItem(text: text, copiedAt: date), at: 0)
        if items.count > limit {
            items.removeLast(items.count - max(limit, 0))
        }
    }

    mutating func remove(_ id: ClipboardItem.ID) {
        items.removeAll { $0.id == id }
    }

    mutating func clear() {
        items.removeAll()
    }

    func search(_ query: String) -> [ClipboardItem] {
        let query = query.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return items }
        return items.filter { $0.text.localizedCaseInsensitiveContains(query) }
    }
}
