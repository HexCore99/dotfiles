// Backend adapter: QML never constructs shell commands or handles image files.
// Catalog scans, cached thumbnails and Hyprpaper changes run off the UI thread.
pragma Singleton
import QtQuick
import Quickshell.Io
import ".."
QtObject {
    id: root
    property var items: []
    // Append-only model preserves scroll and focused tiles as batches arrive.
    property ListModel model: ListModel {}
    property string activePath: ""
    property string folder: Settings.wallpaperFolder
    property string error: ""
    property int skipped: 0
    property int processed: 0
    property int total: 0
    property bool watching: false
    readonly property bool loading: scanner.running
    readonly property bool applying: setter.running
    readonly property string helper: decodeURIComponent(Qt.resolvedUrl("wallpaper_backend.py").toString().replace("file://", ""))
    function command(action): list<string> {
        return ["python3", "-B", helper, action, "--folder", Settings.wallpaperFolder,
            "--monitor", HyprlandService.screen ? HyprlandService.screen.name : Settings.monitor,
            "--fit", Settings.wallpaperFit];
    }
    function refresh(): void {
        if (loading || applying) return;
        error = "";
        scanner.command = command("list").concat(["--width", String(Settings.wallpaperThumbnailWidth),
            "--height", String(Settings.wallpaperThumbnailHeight), "--stream"]);
        scanner.running = true;
    }
    function apply(path): void {
        if (applying || !items.some(item => item.path === path)) return;
        error = "";
        setter.command = command("apply").concat(["--path", path]);
        setter.running = true;
    }
    function receive(line, catalog): void {
        try {
            const data = JSON.parse(line);
            if (!data.ok) { error = data.error || "Wallpaper operation failed."; return; }
            if (catalog && data.event === "start") {
                items = []; model.clear(); skipped = 0; processed = 0;
                folder = data.folder; total = data.total;
            } else if (catalog && data.event === "batch") {
                data.items.forEach(item => model.append(item));
                items = items.concat(data.items);
                processed = data.processed; skipped = data.skipped;
            } else {
                // A scan begun before applying must not clear the new selection.
                if (!catalog || !applying) activePath = data.active || "";
                if (catalog) { folder = data.folder; skipped = data.skipped; }
            }
        } catch (e) { error = "Could not read the wallpaper helper response."; }
    }
    property Process scanner: Process {
        stdout: SplitParser { onRead: line => root.receive(line, true) }
        onExited: code => { if (code !== 0 && !root.error) root.error = "Could not scan wallpapers. Check Python Pillow is installed."; }
    }
    property Process setter: Process {
        stdout: SplitParser { onRead: line => root.receive(line, false) }
        onExited: code => { if (code !== 0 && !root.error) root.error = "Could not apply this wallpaper."; }
    }
    property Process query: Process {
        command: root.command("status")
        stdout: SplitParser { onRead: line => { if (!root.applying && !root.loading) root.receive(line, false); } }
    }
    // Detect changes made outside this panel while it is visible, without rescanning.
    property Timer poll: Timer {
        interval: 3000; repeat: true; running: root.watching
        onTriggered: { if (!root.loading && !root.applying && !query.running) query.running = true; }
    }
}
