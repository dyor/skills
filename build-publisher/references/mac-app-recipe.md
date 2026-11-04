# Recipe: a plain-Swift-package Mac app (no Xcode project)

Operator, Runner and Publisher are all built this way. It needs only the Xcode command-line
tools (`xcode-select --install`), not the full Xcode app, and nothing to maintain except
Swift files and one build script. Follow this recipe for each of the three apps.

## 1. Layout

```
<AppName>/
  Package.swift
  build.sh            # builds <AppName>.app next to itself and installs it
  rebuild.sh          # quit the running app, rebuild, reopen
  config.json         # (Runner, Publisher) the list of apps; optional for Operator
  scripts/            # (Runner, Publisher) shell/ruby the app runs; copied into the bundle
  Sources/<AppName>/  # main.swift, AppDelegate.swift, ContentView.swift, ...
  <AppName>.icns      # optional; see "Icon"
  .gitignore          # .build/  <AppName>.app/  .swiftpm/  .DS_Store
```

`Package.swift`:

```swift
// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "AppName",
    platforms: [.macOS(.v13)],
    targets: [.executableTarget(name: "AppName", path: "Sources/AppName")]
)
```

Runner uses Swift Charts (`import Charts`) for its build-time chart; that ships with macOS 13+
and needs no package dependency.

## 2. Start up with AppKit, not SwiftUI's `@main`

SwiftUI's `App` lifecycle plus `MenuBarExtra` can leave the app running with no window.
Bootstrap AppKit yourself and host SwiftUI inside an `NSWindow`:

```swift
// main.swift
import AppKit
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.regular)
app.run()
```

```swift
// AppDelegate.swift (shape)
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var window: NSWindow!
    func applicationDidFinishLaunching(_ note: Notification) {
        window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 820, height: 600),
                          styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
                          backing: .buffered, defer: false)
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.contentView = NSHostingView(rootView: ContentView(model: model))
        window.center(); window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    // URL scheme links arrive here (see below).
    func application(_ application: NSApplication, open urls: [URL]) { /* ... */ }
}
```

Give the app a main menu (Quit, and an Edit menu with Copy / Select All so ⌘C works in log
views). An `NSApplication` with no `mainMenu` has no ⌘Q.

A `--list` style flag in `main.swift` that prints what the window would show and exits is
worth adding to every app. It lets you (and an agent) verify discovery logic headlessly,
without screenshots.

## 3. `build.sh`

```zsh
#!/bin/zsh
set -euo pipefail
cd "$(dirname "$0")"

swift build -c release

APP="AppName.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp .build/release/AppName "$APP/Contents/MacOS/AppName"
[ -f AppName.icns ] && cp AppName.icns "$APP/Contents/Resources/AppName.icns"
# Runner/Publisher only: the scripts the app runs
[ -d scripts ] && { mkdir -p "$APP/Contents/Resources/scripts"
  cp scripts/* "$APP/Contents/Resources/scripts/"; chmod +x "$APP/Contents/Resources/scripts/"*; }

cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key><string>AppName</string>
  <key>CFBundleDisplayName</key><string>AppName</string>
  <key>CFBundleIdentifier</key><string>com.YOURNAME.appname</string>
  <key>CFBundleExecutable</key><string>AppName</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>1.0</string>
  <key>CFBundleVersion</key><string>1</string>
  <key>LSMinimumSystemVersion</key><string>13.0</string>
  <key>CFBundleIconFile</key><string>AppName</string>
  <key>NSHighResolutionCapable</key><true/>
  <!-- Needed because the app drives Terminal with AppleScript. -->
  <key>NSAppleEventsUsageDescription</key>
  <string>AppName opens Terminal to run project commands.</string>
  <!-- appname://... links, so the three apps can open each other. -->
  <key>CFBundleURLTypes</key>
  <array><dict>
    <key>CFBundleURLName</key><string>com.YOURNAME.appname</string>
    <key>CFBundleURLSchemes</key><array><string>appname</string></array>
  </dict></array>
</dict>
</plist>
PLIST

# Ad-hoc signature so macOS runs it locally without Gatekeeper complaints.
codesign --force --deep --sign - "$APP" >/dev/null 2>&1 || true
echo "Built $(pwd)/$APP"
```

Operator additionally copies the bundle into `/Applications` so Spotlight finds it. The
bundle is ad-hoc signed and **not notarized**: it runs on the Mac that built it. To share the
app with another Mac, they build it from the same skill.

Scripts are copied into the bundle at build time. Edit the copy in the project folder and
rebuild; never edit the one inside the `.app`. At run time the app looks for
`Bundle.main.resourceURL/scripts` first and falls back to `<folder next to the .app>/scripts`.

## 4. `rebuild.sh`

An app cannot replace its own running bundle, so a **Rebuild & Relaunch** button runs this
in Terminal:

```zsh
#!/bin/zsh
set -euo pipefail
cd "$(dirname "$0")"
/usr/bin/osascript -e 'tell application id "com.YOURNAME.appname" to quit' 2>/dev/null || true
for _ in {1..120}; do /usr/bin/pgrep -x AppName >/dev/null || break; sleep 0.25; done
if /usr/bin/pgrep -x AppName >/dev/null; then echo "AppName is still running." >&2; exit 1; fi
./build.sh
/usr/bin/open "$PWD/AppName.app"
```

The button runs it through AppleScript (`tell application "Terminal" to do script "cd '<dir>' && ./rebuild.sh"`).
The quit step uses the bundle id, not the name, so it works however the app is renamed.

## 5. Driving Terminal and other apps

All three apps shell out in the same ways. Build one small `Launcher` helper:

- **Terminal command**: `osascript -e 'tell application "Terminal" to activate' -e 'do script "<cmd>"'`.
  Escape backslashes and double quotes for AppleScript, and single-quote every path for the
  shell (`'` becomes `'\''`). Use this whenever the user should *see* the output, such as
  git push, merge, pull, `npm run dev`. It also makes a failed merge or an auth prompt visible.
- **Open a folder in Finder**: `NSWorkspace.shared.open(URL(fileURLWithPath: path))`.
- **Terminal at a folder**: `/usr/bin/open -a Terminal <path>`.
- **Another app, with a link**: build a `URLComponents` with `scheme`, `host`, `queryItems`
  and call `NSWorkspace.shared.open(url)`. If the target `.app` exists at a known path, pass it
  to `open(_:withApplicationAt:configuration:)` so the link goes to *that* build even when
  LaunchServices knows an older copy.
- **Background process with streamed output** (Runner, Publisher): see their skills. Run via
  `/bin/zsh -lc` so Homebrew, rbenv, JAVA_HOME and the Android SDK match Terminal.

Child processes need a pipe for stdout and stderr, `standardInput = FileHandle.nullDevice`
(a tool that tries to prompt then fails fast instead of hanging forever), and
`readabilityHandler` to append output to the model on the main queue.

## 6. Icon (optional)

Without an `.icns` the app uses a generic icon, which is fine. To make one: draw a 512x512
PNG with a small Swift/AppKit script (rounded-rect gradient plus the app's name), then

```zsh
mkdir AppIcon.iconset
for s in 16 32 128 256 512; do
  sips -z $s $s icon_512.png --out AppIcon.iconset/icon_${s}x${s}.png >/dev/null
  sips -z $((s*2)) $((s*2)) icon_512.png --out AppIcon.iconset/icon_${s}x${s}@2x.png >/dev/null
done
iconutil -c icns AppIcon.iconset -o AppName.icns
```

## 7. URL schemes between the apps

| Scheme | Handled by | Meaning |
|---|---|---|
| `operator://ship?path=<repo folder>` | Operator | Open that project's GitHub review (Push / Merge → main / Pull) |
| `runner://open?app=<packageName>` | Runner | Select that app (and rescan devices) |
| `publisher://open?package=<packageName or bundleId>` | Publisher | Select that app |

A link can arrive before the window exists (cold launch). Store the selection in the model so
it sticks, and show the window afterwards.

## 8. Verifying a build without a human

- `swift build -c release` must be clean.
- `./build.sh && open AppName.app`, then confirm the process is alive (`pgrep -x AppName`).
- Use the `--list` / `--devices` flag to verify discovery logic headlessly.
- Optional: an env var such as `APPNAME_SNAPSHOT=/tmp/x.png` that renders the window's own
  content view with `bitmapImageRepForCachingDisplay` + `cacheDisplay` to a PNG after a few
  seconds, then quits. It draws the app's own views, so it needs no Screen Recording
  permission and lets an agent look at the UI.
