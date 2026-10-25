pragma Singleton
import QtQuick
import Quickshell.Io
QtObject {
    id: theme
    property color background: "#191f23"
    property color card: "#252c30"
    property color hover: "#303b3d"
    property color control: "#364440"
    property color accent: "#9fe3cd"
    property color accentText: "#18352b"
    property color text: "#eff7f3"
    property color muted: "#a0b0a9"
    property color border: "#42564e"
    function refresh() { debounce.restart(); }
    property Timer debounce: Timer { interval: 180; onTriggered: { if (extract.running) restart.restart(); else extract.running = true; } }
    property Timer restart: Timer { interval: 300; onTriggered: theme.refresh() }
    property FileView wallpaper: FileView {
        path: Qt.resolvedUrl("../../wallpaper/state.json").toString().replace("file://", "")
        watchChanges: true
        onFileChanged: theme.refresh()
    }
    property Process extract: Process {
        command: ["python3", "-B", Qt.resolvedUrl("palette.py").toString().replace("file://", "")]
        stdout: StdioCollector { onStreamFinished: {
            try {
                const colors = JSON.parse(text);
                for (const key of ["background", "card", "hover", "control", "accent", "accentText", "text", "muted", "border"])
                    if (/^#[0-9a-f]{6}$/i.test(colors[key] || "")) theme[key] = colors[key];
            } catch(e) { /* Preserve the last usable colors. */ }
        } }
    }
    Component.onCompleted: refresh()
}
