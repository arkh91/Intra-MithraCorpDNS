import SwiftUI

/// Shows a live-updating list of DNS queries resolved by the tunnel,
/// with per-query latency, mirroring Intra's activity log.
/// Usage: shown as the second tab in RootTabView.
struct QueryLogView: View {
    @State private var logs: [QueryLogEntry] = []
    // Polls the shared App Group store since the extension process and the
    // app process can't share in-memory state directly.
    private let timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationStack {
            List(logs.reversed()) { entry in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(entry.domain).font(.headline)
                        Spacer()
                        Text(String(format: "%.0f ms", entry.latencyMs))
                            .font(.caption)
                            .foregroundStyle(latencyColor(entry.latencyMs))
                    }
                    Text(entry.resolvedIPs.joined(separator: ", "))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Query Log")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Clear") {
                        AppGroupStore.shared.clearLogs()
                        logs = []
                    }
                }
            }
            .onAppear { refresh() }
            .onReceive(timer) { _ in refresh() }
        }
    }

    /// Pulls the latest logs from the shared store. Usage: called on
    /// appear and once per second via the timer publisher above.
    private func refresh() {
        logs = AppGroupStore.shared.fetchLogs()
    }

    /// Color-codes latency the way the original app's log view does
    /// (green = fast, yellow = medium, red = slow). Usage: called per row
    /// in the List above.
    private func latencyColor(_ ms: Double) -> Color {
        switch ms {
        case ..<50: return .green
        case 50..<150: return .yellow
        default: return .red
        }
    }
}
