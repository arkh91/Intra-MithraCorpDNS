import SwiftUI
import MapKit

/// Shows resolved DNS query IPs plotted on a map, geocoded via a public
/// IP-geolocation API (this lookup deliberately happens in the app, not the
/// extension, to keep the tunnel process lightweight and avoid extra
/// per-packet network calls from PacketTunnelProvider).
/// Usage: shown as the third tab in RootTabView.
struct MapView: View {
    @State private var camera: MapCameraPosition = .automatic
    @State private var points: [GeoPoint] = []
    private let timer = Timer.publish(every: 3.0, on: .main, in: .common).autoconnect()

    var body: some View {
        Map(position: $camera) {
            ForEach(points) { point in
                Marker(point.domain, coordinate: point.coordinate)
            }
        }
        .onAppear { Task { await refresh() } }
        .onReceive(timer) { _ in Task { await refresh() } }
        .navigationTitle("Map")
    }

    /// Fetches new log entries and geocodes any that don't have
    /// coordinates yet. Usage: called on appear and every 3 seconds.
    private func refresh() async {
        let logs = AppGroupStore.shared.fetchLogs()
        var newPoints: [GeoPoint] = []
        for entry in logs.suffix(50) {
            guard let ip = entry.resolvedIPs.first else { continue }
            if let existing = points.first(where: { $0.domain == entry.domain }) {
                newPoints.append(existing)
                continue
            }
            if let coord = await geocode(ip: ip) {
                newPoints.append(GeoPoint(domain: entry.domain, coordinate: coord))
            }
        }
        points = newPoints
    }

    /// Looks up a rough lat/long for an IP using ip-api.com's free tier.
    /// Usage: called once per unresolved IP from refresh() above.
    /// NOTE: swap for a paid/rate-limit-safe provider (ipinfo.io, MaxMind)
    /// before shipping to production — the free tier here is for
    /// development only and rate-limits aggressively.
    private func geocode(ip: String) async -> CLLocationCoordinate2D? {
        guard let url = URL(string: "http://ip-api.com/json/\(ip)") else { return nil }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let result = try JSONDecoder().decode(IPAPIResponse.self, from: data)
            return CLLocationCoordinate2D(latitude: result.lat, longitude: result.lon)
        } catch {
            return nil
        }
    }
}

/// One plotted point on the map. Usage: built by MapView.refresh(), consumed
/// by the Map's ForEach above.
private struct GeoPoint: Identifiable {
    var id: String { domain }
    let domain: String
    let coordinate: CLLocationCoordinate2D
}

/// Minimal decode target for ip-api.com's JSON response. Usage: decoded
/// inside MapView.geocode(ip:).
private struct IPAPIResponse: Decodable {
    let lat: Double
    let lon: Double
}
