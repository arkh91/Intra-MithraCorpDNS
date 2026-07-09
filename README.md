# IntraDNS-iOS

A native iOS replica of [Intra](https://github.com/arkh91/Intra-GoogleDNS) (Jigsaw's DNS-over-HTTPS
tool). Android's `VpnService` is replaced with Apple's `NetworkExtension` /
`NEPacketTunnelProvider`, which is the closest iOS equivalent: it lets an app
capture all outgoing DNS traffic on the device, re-encode it as DNS-over-HTTPS
(DoH), send it to a chosen resolver (Cloudflare / Google / custom), and log
the results back to the main app.

## Hard requirements (cannot be worked around)

1. **Apple Developer Program membership ($99/yr).** NetworkExtension is a
   restricted entitlement — Apple's servers will refuse to sign a build that
   requests it unless the App ID belongs to a paid account. This applies
   even to Ad-Hoc/TestFlight builds, not just App Store releases.
2. **Xcode to assemble the project the first time.** Recreating a two-target
   Xcode project (app + extension) from raw text files is fragile, so this
   repo ships all Swift/plist/entitlement source, plus exact click-by-click
   steps below (`SETUP.md`) to wire it into a project — but that wiring step
   needs Xcode's project editor once.

## You only have an iPhone — here's the no-Mac path

You don't have to buy a Mac. Use GitHub's free macOS CI runners to do the
Xcode part for you:

1. Push this repo to your own GitHub account (from the GitHub app on your
   phone, or the mobile web UI: New repo → upload these files).
2. Register your Apple Developer account (any browser, including Safari on
   iPhone, works at developer.apple.com).
3. Follow `SETUP.md` once — it's written so a **collaborator with a Mac**
   (freelancer, friend, or a one-time cloud Mac rental like MacStadium/
   MacinCloud, ~$1/hr) can do the initial "create Xcode project, drag in
   these files, add the NetworkExtension capability" step in under 20
   minutes. This only needs to happen ONCE — after that, `.github/workflows/
   build.yml` rebuilds and re-signs automatically on every push.
4. After the one-time setup, install `fastlane match` certificates (steps in
   `SETUP.md`) so CI can sign builds without a human touching a keychain.
5. Every subsequent push triggers GitHub Actions → builds → uploads to
   TestFlight → you install/update entirely from the iPhone's TestFlight app.

## Repo layout

```
IntraDNS-iOS/
├── IntraDNS/                  # Main app target (SwiftUI)
│   ├── Sources/
│   └── Resources/
├── PacketTunnel/               # NetworkExtension target (the actual DNS interception)
│   └── Sources/
├── .github/workflows/build.yml # CI build + TestFlight upload
├── SETUP.md                    # One-time Xcode project wiring steps
└── README.md
```

## Feature parity with the original

| Feature | Status |
|---|---|
| DoH server selection (Cloudflare / Google / custom) | ✅ `ServerListView.swift` |
| Connect/disconnect toggle (VPN-based tunnel) | ✅ `TunnelManager.swift` |
| Live query log with per-query latency | ✅ `QueryLogView.swift` + `AppGroupStore.swift` |
| Geocoded map of resolved IPs | ✅ `MapView.swift` |
| Actual DNS packet interception + DoH rewrite | ✅ `PacketTunnelProvider.swift` + `DoHResolver.swift` |

All functions in the source are commented with what they do and when
they're called, per your preference.
