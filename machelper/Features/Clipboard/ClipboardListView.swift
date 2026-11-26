import SwiftUI

/// Searchable clipboard history. Keyboard-first: type to filter, ↑↓ to move, ↩ to paste, esc to close.
struct ClipboardListView: View {
    let store: ClipboardStore
    let onPick: (ClipboardItem) -> Void
    let onDismiss: () -> Void

    @State private var query = ""
    @State private var selection: ClipboardItem.ID?
    @FocusState private var isSearchFocused: Bool

    private var results: [ClipboardItem] {
        store.history.search(query)
    }

    var body: some View {
        VStack(spacing: 0) {
            TextField("Search clipboard", text: $query)
                .textFieldStyle(.plain)
                .font(.title3)
                .padding(12)
                .focused($isSearchFocused)
                .onSubmit(pickSelection)

            Divider()

            if results.isEmpty {
                ContentUnavailableView("No Items", systemImage: "doc.on.clipboard")
                    .frame(maxHeight: .infinity)
            } else {
                ScrollViewReader { proxy in
                    List(results, selection: $selection) { item in
                        ClipboardRow(item: item)
                            .tag(item.id)
                            .id(item.id)
                            .onTapGesture(count: 2) { onPick(item) }
                    }
                    .listStyle(.plain)
                    .onChange(of: selection) { _, id in
                        if let id { proxy.scrollTo(id) }
                    }
                }
            }
        }
        .frame(width: 520, height: 420)
        .onAppear(perform: reset)
        .onChange(of: query) { selection = results.first?.id }
        .onKeyPress(.upArrow) { moveSelection(by: -1) }
        .onKeyPress(.downArrow) { moveSelection(by: 1) }
        .onKeyPress(.escape) {
            onDismiss()
            return .handled
        }
    }

    private func reset() {
        query = ""
        selection = results.first?.id
        isSearchFocused = true
    }

    private func pickSelection() {
        guard let item = results.first(where: { $0.id == selection }) ?? results.first else { return }
        onPick(item)
    }

    private func moveSelection(by offset: Int) -> KeyPress.Result {
        guard !results.isEmpty else { return .ignored }
        let current = results.firstIndex { $0.id == selection } ?? 0
        let next = min(max(current + offset, 0), results.count - 1)
        selection = results[next].id
        return .handled
    }
}

private struct ClipboardRow: View {
    let item: ClipboardItem

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(item.text.trimmingCharacters(in: .whitespacesAndNewlines))
                .lineLimit(2)
                .truncationMode(.tail)
            Text(item.copiedAt, style: .relative)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }
}
