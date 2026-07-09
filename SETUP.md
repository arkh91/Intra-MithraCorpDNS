# One-time project setup (needs Xcode once)

Whoever does this (you on a rented cloud Mac, or a collaborator) should run
through these steps once. After this, CI handles every future build.

## 1. Create the Xcode project

1. Xcode → File → New → Project → **App** → name it `IntraDNS`,
   interface: SwiftUI, language: Swift.
2. Delete the default `ContentView.swift`/`IntraDNSApp.swift` Xcode
   generated, and drag in everything from `IntraDNS/Sources` and
   `IntraDNS/Resources` in this repo instead.

## 2. Add the Network Extension target

1. File → New → Target → **Network Extension** → choose **Packet Tunnel**
   → name it `PacketTunnel`.
2. Delete the stub `PacketTunnelProvider.swift` Xcode generates, drag in the
   files from `PacketTunnel/Sources` in this repo instead.

## 3. App Groups (lets the extension write query logs the app can read)

1. Select the `IntraDNS` app target → Signing & Capabilities → `+
   Capability` → **App Groups** → add `group.com.yourdomain.intradns`.
2. Repeat for the `PacketTunnel` target, same group ID.
3. Open `AppGroupStore.swift` and `PacketTunnelProvider.swift`, replace the
   placeholder `"group.com.yourdomain.intradns"` string with your actual
   group ID in both places. If editing on a remote/cloud Mac over SSH:
   ```
   vi IntraDNS/Sources/AppGroupStore.swift
   vi PacketTunnel/Sources/PacketTunnelProvider.swift
   ```
   then `:%s/com.yourdomain.intradns/com.<yourteam>.intradns/g` in each,
   `:wq` to save.

## 4. Network Extension entitlement

1. Select `PacketTunnel` target → Signing & Capabilities → `+ Capability`
   → **Network Extensions** → check **Packet Tunnel**.
2. This requires your paid Apple Developer Team to be selected under
   Signing for both targets.

## 5. Bundle IDs

- App: `com.yourdomain.intradns`
- Extension: `com.yourdomain.intradns.PacketTunnel` (must be the app's
  bundle ID + a suffix, Xcode enforces this automatically)

## 6. Fastlane match (lets CI sign builds without you)

On the machine doing this one-time setup:
```bash
gem install fastlane bundler --user-install
fastlane match init          # creates a private repo to store certs
fastlane match appstore      # generates + stores distribution cert
fastlane match development   # generates + stores dev cert
```
Then add these as GitHub repo secrets (Settings → Secrets → Actions):
- `MATCH_GIT_URL`, `MATCH_PASSWORD`, `FASTLANE_APPLE_ID`,
  `APP_STORE_CONNECT_API_KEY` (see `.github/workflows/build.yml` for exact
  names it expects).

## 7. Commit and push

```bash
git add .
git commit -m "Initial Xcode project wiring"
git push
```

From here on, `.github/workflows/build.yml` builds, signs, and uploads to
TestFlight automatically on every push to `main`. You manage the app
entirely from TestFlight on your iPhone from this point forward.
