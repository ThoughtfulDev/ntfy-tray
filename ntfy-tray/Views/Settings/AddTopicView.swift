import SwiftUI

struct AddTopicView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var iconIdentifier = TopicIconIdentifier.defaultValue
    @State private var errorMessage: String?
    @State private var isIconPickerPresented = false

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Add Topic")
                .font(.title2)
                .bold()
            TextField("Topic name", text: $name)
            HStack {
                TopicIconView(identifier: iconIdentifier)
                    .accessibilityHidden(true)
                Button("Choose Icon…") {
                    isIconPickerPresented = true
                }
            }
            if let errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
            }
            HStack {
                Spacer()
                Button("Cancel", role: .cancel, action: dismiss.callAsFunction)
                Button("Add", action: addTopic)
                    .buttonStyle(.borderedProminent)
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(24)
        .frame(width: 360)
        .sheet(isPresented: $isIconPickerPresented) {
            FontAwesomeIconPicker(iconIdentifier: $iconIdentifier)
        }
    }

    private func addTopic() {
        do {
            try appModel.addTopic(named: name, symbolName: iconIdentifier)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
