import SwiftUI

/// App entry point. Usage: iOS calls this automatically at launch; sets up
/// the root TabView (Connect / Log / Map) as the window's root view.
@main
struct IntraDNSApp: App {
    var body: some Scene {
        WindowGroup {
            RootTabView()
        }
    }
}

/// Root tab container. Usage: instantiated once by IntraDNSApp's WindowGroup;
/// switches between the three main screens.
struct RootTabView: View {
    var body: some View {
        TabView {
            ContentView()
                .tabItem { Label("Connect", systemImage: "power") }
            QueryLogView()
                .tabItem { Label("Log", systemImage: "list.bullet") }
            MapView()
                .tabItem { Label("Map", systemImage: "map") }
        }
    }
}
