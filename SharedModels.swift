import Foundation

/// A single DoH resolver the user can pick from the server list.
/// Mirrors the "server" concept in the original Intra app (Cloudflare,
/// Google, or a custom DoH endpoint).
struct DoHServer: Identifiable, Codable, Equatable {
    let id: String          // stable identifier, e.g. "cloudflare"
    let name: String        // display name shown in ServerListView
    let url: URL            // DoH POST endpoint, e.g. https://cloudflare-dns.com/dns-query
    let logoSystemName: String // SF Symbol used as a placeholder icon

    /// Built-in presets shown by default in ServerListView.
    /// Usage: `DoHServer.presets` is read once when the list view appears
    /// to populate the picker; users can also add a custom one.
    static let presets: [DoHServer] = [
        DoHServer(id: "cloudflare", name: "Cloudflare (1.1.1.1)",
                  url: URL(string: "https://cloudflare-dns.com/dns-query")!,
                  logoSystemName: "cloud.fill"),
        DoHServer(id: "google", name: "Google Public DNS",
                  url: URL(string: "https://dns.google/dns-query")!,
                  logoSystemName: "globe"),
        DoHServer(id: "quad9", name: "Quad9",
                  url: URL(string: "https://dns.quad9.net/dns-query")!,
                  logoSystemName: "shield.fill")
    ]
}

/// A single logged DNS query, written by the PacketTunnelProvider extension
/// and read by the main app's QueryLogView / MapView.
struct QueryLogEntry: Identifiable, Codable, Equatable {
    let id: UUID
    let domain: String
    let resolvedIPs: [String]
    let latencyMs: Double
    let timestamp: Date
    let serverID: String
    // Optional geocoded coordinate for the first resolved IP, filled in
    // lazily by MapView's geocoding lookup (kept optional so the extension
    // never has to do network geocoding itself — that stays in the app).
    var latitude: Double?
    var longitude: Double?
}

/// Connection state broadcast from the extension to the app via the shared
/// App Group UserDefaults, since NEVPNStatus alone doesn't carry server info.
enum TunnelConnectionState: String, Codable {
    case disconnected, connecting, connected, disconnecting, invalid
}
