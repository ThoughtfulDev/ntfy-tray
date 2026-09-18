import SwiftUI

struct FontAwesomeIconPicker: View {
    @Binding var iconIdentifier: String
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var scope = "All"

    private let columns = [GridItem(.adaptive(minimum: 92), spacing: 12)]

    var body: some View {
        NavigationStack {
            ScrollView {
                if matchingIcons.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                        .padding(.top, 48)
                } else {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(matchingIcons) { icon in
                            FontAwesomeIconPickerItem(
                                icon: icon,
                                isSelected: icon.identifier == iconIdentifier
                            ) {
                                iconIdentifier = icon.identifier
                                dismiss()
                            }
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Choose Icon")
            .searchable(text: $searchText, prompt: "Search Font Awesome Free")
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Picker("Icon family", selection: $scope) {
                        Text("All").tag("All")
                        Text("Classic").tag("Classic")
                        Text("Brands").tag("Brands")
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 260)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: dismiss.callAsFunction)
                }
            }
        }
        .frame(minWidth: 560, minHeight: 520)
    }

    private var matchingIcons: [FontAwesomeFreeIcon] {
        FontAwesomeFreeIconCatalog.icons.filter { icon in
            matchesScope(icon) && matchesSearch(icon)
        }
    }

    private func matchesScope(_ icon: FontAwesomeFreeIcon) -> Bool {
        switch scope {
        case "Brands": icon.style == "brands"
        case "Classic": icon.style != "brands"
        default: true
        }
    }

    private func matchesSearch(_ icon: FontAwesomeFreeIcon) -> Bool {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return true }
        return icon.name.localizedCaseInsensitiveContains(query)
            || icon.label.localizedCaseInsensitiveContains(query)
            || icon.searchTerms.contains { $0.localizedCaseInsensitiveContains(query) }
    }
}
