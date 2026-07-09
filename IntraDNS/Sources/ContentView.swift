import SwiftUI

/// Home screen: shows the current DoH server, a connect/disconnect toggle,
/// and lets the user switch servers via ServerListView.
/// Usage: shown as the first tab in RootTabView.
struct ContentView: View {
    @StateObject private var tunnel = TunnelManager.shared
    @State private var selectedServer = AppGroupStore.shared.selectedServer()
    @State private var showServerPicker = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                statusCircle
                Text(statusText)
                    .font(.headline)

                Button {
                    showServerPicker = true
                } label: {
                    HStack {
                        Image(systemName: selectedServer.logoSystemName)
                        Text(selectedServer.name)
                        Image(systemName: "chevron.right")
                    }
                }
                .buttonStyle(.bordered)

                Toggle(isOn: connectBinding) {
                    Text(tunnel.state == .connected ? "Connected" : "Disconnected")
                }
                .toggleStyle(.switch)
                .padding(.horizontal, 40)

                if let error = tunnel.lastError {
                    Text(error).foregroundStyle(.red).font(.caption)
                }
            }
            .padding()
            .navigationTitle("IntraDNS")
            .sheet(isPresented: $showServerPicker) {
                ServerListView(selectedServer: $selectedServer)
            }
        }
    }

    /// Visual indicator of tunnel state. Usage: purely presentational,
    /// recomputed whenever `tunnel.state` changes.
    private var statusCircle: some View {
        Circle()
            .fill(color(for: tunnel.state))
            .frame(width: 80, height: 80)
            .overlay(Image(systemName: "shield.lefthalf.filled").foregroundStyle(.white))
    }

    private var statusText: String {
        switch tunnel.state {
        case .connected: return "Protected via \(selectedServer.name)"
        case .connecting: return "Connecting…"
        case .disconnecting: return "Disconnecting…"
        case .disconnected: return "Not protected"
        case .invalid: return "Configuration error"
        }
    }

    private func color(for state: TunnelConnectionState) -> Color {
        switch state {
        case .connected: return .green
        case .connecting, .disconnecting: return .yellow
        case .disconnected: return .gray
        case .invalid: return .red
        }
    }

    /// Bridges the Toggle's Bool binding to TunnelManager's async
    /// connect()/disconnect() calls. Usage: bound directly to the Toggle
    /// in this view's body.
    private var connectBinding: Binding<Bool> {
        Binding(
            get: { tunnel.state == .connected || tunnel.state == .connecting },
            set: { isOn in
                if isOn {
                    Task { await tunnel.connect(server: selectedServer) }
                } else {
                    tunnel.disconnect()
                }
            }
        )
    }
}
