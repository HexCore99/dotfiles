// Track the current default PipeWire output, even when the output changes.
// PwObjectTracker subscribes to its audio state; there is no volume polling.
pragma Singleton
import QtQuick
import Quickshell.Services.Pipewire
QtObject {
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var audio: sink ? sink.audio : null
    readonly property int percent: audio ? Math.round(audio.volume * 100) : 0
    readonly property bool muted: audio ? audio.muted : false
    function toggleMute(): void { if (audio) audio.muted = !audio.muted; }
    // Absolute slider setting. Keep the output at 0–100%; moving it unmutes.
    function setPercent(value: real): void {
        if (!audio || !Number.isFinite(value)) return;
        audio.volume = Math.max(0, Math.min(100, value)) / 100;
        if (value > 0) audio.muted = false;
    }
    function adjust(up: bool): void { if (audio) audio.volume = Math.max(0, Math.min(1, audio.volume + (up ? 0.05 : -0.05))); }
    property PwObjectTracker tracker: PwObjectTracker { objects: sink ? [sink] : [] }
}
