import Foundation
import NetworkExtension
import Combine

/// Owns the NETunnelProviderManager lifecycle for the main app: installing
/// the VPN configuration, starting/stopping it, and publishing connection
/// state to SwiftUI views (ContentView's connect toggle).
@MainActor
final class TunnelManager: ObservableObject {

    static let shared = TunnelManager()

    @Published var state: TunnelConnectionState = .disconnected
    @Published var lastError: String?

    private var manager: NETunnelProviderManager?

    private init() {
        // Usage: called once via `TunnelManager.shared`. Loads any existing
        // VPN profile so the toggle reflects reality if the app was killed
        // while the tunnel was still running.
        Task { await loadManager() }
    }

    /// Loads (or creates) the single NETunnelProviderManager this app uses.
    /// Called on init and before every connect() call, since iOS can return
    /// a stale manager instance after Settings changes.
    private func loadManager() async {
        do {
            let managers = try await NETunnelProviderManager.loadAllFromPreferences()
            if let existing = managers.first {
                self.manager = existing
                self.state = mapStatus(existing.connection.status)
            } else {
                self.manager = makeManager()
            }
            observeStatus()
        } catch {
            lastError = error.localizedDescription
        }
    }

    /// Builds a fresh NETunnelProviderManager pointing at the PacketTunnel
    /// extension bundle. Called only when no VPN profile exists yet.
    private func makeManager() -> NETunnelProviderManager {
        let manager = NETunnelProviderManager()
        let proto = NETunnelProviderProtocol()
        // Must match the PacketTunnel extension's bundle identifier exactly.
        proto.providerBundleIdentifier = "com.yourdomain.intradns.PacketTunnel"
        proto.serverAddress = "IntraDNS" // cosmetic, shown in iOS VPN settings
        manager.protocolConfiguration = proto
        manager.localizedDescription = "IntraDNS"
        manager.isEnabled = true
        return manager
    }

    /// Called from ContentView's connect toggle when the user turns the
    /// tunnel ON. Saves the profile (prompts the user for VPN permission
    /// the first time) and starts it.
    func connect(server: DoHServer) async {
        AppGroupStore.shared.setSelectedServer(server)
        guard let manager = manager else { return }
        do {
            manager.isEnabled = true
            try await manager.saveToPreferences()
            try await manager.loadFromPreferences()
            try manager.connection.startVPNTunnel()
            state = .connecting
        } catch {
            lastError = error.localizedDescription
            state = .invalid
        }
    }

    /// Called from ContentView's connect toggle when the user turns the
    /// tunnel OFF.
    func disconnect() {
        manager?.connection.stopVPNTunnel()
        state = .disconnecting
    }

    /// Subscribes to NEVPNStatusDidChange so `state` stays live-updated
    /// whenever the extension's actual VPN status changes (e.g. system
    /// killed it, or user disabled VPN from iOS Settings directly).
    private func observeStatus() {
        guard let connection = manager?.connection else { return }
        NotificationCenter.default.addObserver(
            forName: .NEVPNStatusDidChange, object: connection, queue: .main
        ) { [weak self] _ in
            guard let self, let status = self.manager?.connection.status else { return }
            Task { @MainActor in self.state = self.mapStatus(status) }
        }
    }

    /// Translates Apple's NEVPNStatus enum into our simpler
    /// TunnelConnectionState used by the UI.
    private func mapStatus(_ status: NEVPNStatus) -> TunnelConnectionState {
        switch status {
        case .connected: return .connected
        case .connecting, .reasserting: return .connecting
        case .disconnecting: return .disconnecting
        case .disconnected: return .disconnected
        case .invalid: return .invalid
        @unknown default: return .invalid
        }
    }
}
