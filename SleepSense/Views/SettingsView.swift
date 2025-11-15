import SwiftUI
import HealthKit

struct SettingsView: View {
    @State private var healthKitAvailable: Bool = HKHealthStore.isHealthDataAvailable()
    @State private var syncOnLaunch: Bool = true
    @State private var highContrastMode: Bool = false

    var body: some View {
        Form {
            Section(header: Text("HealthKit")) {
                HStack {
                    Text("Health data available")
                    Spacer()
                    Image(systemName: healthKitAvailable ? "checkmark.seal.fill" : "xmark.seal")
                        .foregroundColor(healthKitAvailable ? .green : .red)
                }

                Button("Review Permissions") {
                    // Triggering the authorization flow again if needed.
                    HealthStore.shared.requestAuthorization(completion: { _, _ in })
                }
            }

            Section(header: Text("Sync")) {
                Toggle("Sync on Launch", isOn: $syncOnLaunch)
            }

            Section(header: Text("Appearance")) {
                Toggle("High contrast mode", isOn: $highContrastMode)
            }
        }
        .navigationTitle("Settings")
    }
}
