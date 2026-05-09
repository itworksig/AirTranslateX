import SwiftUI

struct SettingsView: View {
    var body: some View {
        Form {
            Section(AppText.permissions) {
                Text(AppText.permissionsHelp)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 420)
        .padding()
    }
}
