import SwiftUI

/// A command's title with its icon, shared by the menu bar and Settings.
struct CommandLabel: View {
    let title: LocalizedStringKey
    let icon: CommandIcon?

    var body: some View {
        switch icon {
        case .symbol(let name):
            Label(title, systemImage: name)
        case .image(let image):
            Label { Text(title) } icon: { Image(nsImage: image) }
        case nil:
            Text(title)
        }
    }
}
