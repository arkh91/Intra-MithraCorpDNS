import Foundation

/// Shared storage between the main app and the PacketTunnel extension.
/// Both targets must have the SAME App Group capability enabled
/// (see SETUP.md step 3) pointing at `groupID` below.
final class AppGroupStore {

    /// Replace this with your own App Group ID from SETUP.md step 3.
    static let groupID = "group.com.yourdomain.intradns"

    static let shared = AppGroupStore()

    private let defaults: UserDefaults?
    private let logsKey = "queryLogs"
    private let selectedServerKey = "selectedServerID"
    private let maxStoredLogs = 500

    private init() {
        // Usage: called once via `AppGroupStore.shared`. Falls back to nil
        // (no-op storage) if the App Group isn't configured yet, so the app
        // doesn't crash during early development before SETUP.md is done.
        self.defaults = UserDefaults(suiteName: Self.groupID)
    }

    /// Called by PacketTunnelProvider every time a DNS query is resolved,
    /// to append a new entry the main app can display live.
    func appendLog(_ entry: QueryLogEntry) {
        var logs = fetchLogs()
        logs.append(entry)
        if logs.count > maxStoredLogs {
            logs.removeFirst(logs.count - maxStoredLogs)
        }
        if let data = try? JSONEncoder().encode(logs) {
            defaults?.set(data, forKey: logsKey)
        }
    }

    /// Called by QueryLogView / MapView on appear and via polling to read
    /// the latest logs written by the extension.
    func fetchLogs() -> [QueryLogEntry] {
        guard let data = defaults?.data(forKey: logsKey),
              let logs = try? JSONDecoder().decode([QueryLogEntry].self, from: data) else {
            return []
        }
        return logs
    }

    /// Called by ServerListView when the user taps a different DoH server,
    /// so PacketTunnelProvider can read it back on the next connection.
    func setSelectedServer(_ server: DoHServer) {
        if let data = try? JSONEncoder().encode(server) {
            defaults?.set(data, forKey: selectedServerKey)
        }
    }

    /// Called by PacketTunnelProvider at startup to know which DoH endpoint
    /// to forward queries to.
    func selectedServer() -> DoHServer {
        guard let data = defaults?.data(forKey: selectedServerKey),
              let server = try? JSONDecoder().decode(DoHServer.self, from: data) else {
            return DoHServer.presets[0]
        }
        return server
    }

    /// Called by both app and extension to clear logs, e.g. a "Clear" button
    /// in QueryLogView.
    func clearLogs() {
        defaults?.removeObject(forKey: logsKey)
    }
}
