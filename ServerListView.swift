import SwiftUI

/// Lets the user pick a DoH server from presets or add a custom endpoint.
/// Usage: presented as a sheet from ContentView when the user taps the
/// current-server row.
struct ServerListView: View {
    @Binding var selectedServer: DoHServer
    @Environment(\.dismiss) private var dismiss

    @State private var customServers: [DoHServer] = []
    @State private var showAddCustom = false
    @State private var customName = ""
    @State private var customURL = ""

    var body: some View {
        NavigationStack {
            List {
                Section("Built-in") {
                    ForEach(DoHServer.presets) { server in
                        row(for: server)
                    }
                }
                if !customServers.isEmpty {
                    Section("Custom") {
                        ForEach(customServers) { server in
                            row(for: server)
                        }
                    }
                }
            }
            .navigationTitle("DoH Server")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add Custom") { showAddCustom = true }
                }
            }
            .sheet(isPresented: $showAddCustom) {
                addCustomSheet
            }
        }
    }

    /// One tappable row per server. Usage: called for every preset and
    /// custom server in the List above.
    private func row(for server: DoHServer) -> some View {
        Button {
            select(server)
        } label: {
            HStack {
                Image(systemName: server.logoSystemName)
                VStack(alignment: .leading) {
                    Text(server.name)
                    Text(server.url.absoluteString)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if server.id == selectedServer.id {
                    Image(systemName: "checkmark").foregroundStyle(.blue)
                }
            }
        }
        .buttonStyle(.plain)
    }

    /// Persists the choice and closes the sheet. Usage: called when the
    /// user taps any server row.
    private func select(_ server: DoHServer) {
        selectedServer = server
        AppGroupStore.shared.setSelectedServer(server)
        dismiss()
    }

    private var addCustomSheet: some View {
        NavigationStack {
            Form {
                TextField("Name", text: $customName)
                TextField("https://example.com/dns-query", text: $customURL)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
            }
            .navigationTitle("Custom Server")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveCustom() }
                        .disabled(customName.isEmpty || URL(string: customURL) == nil)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showAddCustom = false }
                }
            }
        }
    }

    /// Validates and appends a user-entered custom DoH endpoint. Usage:
    /// called when the user taps "Save" in the addCustomSheet form.
    private func saveCustom() {
        guard let url = URL(string: customURL) else { return }
        let server = DoHServer(id: UUID().uuidString, name: customName,
                                url: url, logoSystemName: "network")
        customServers.append(server)
        showAddCustom = false
    }
}
