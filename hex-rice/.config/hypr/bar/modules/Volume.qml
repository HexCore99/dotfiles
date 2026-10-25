// Live PipeWire volume: left-click opens the animated sound panel, right-click mutes.
// Scrolling changes volume by five percent and caps it at 100 percent.
import QtQuick
import "../core"
import "../components"
import "../services"
BarButton {
    icon: AudioService.muted ? "volume-x" : "volume-2"
    text: AudioService.muted ? "mute" : AudioService.percent + "%"
    hint: "Audio settings · right-click to mute; scroll to adjust"
    onClicked: SoundState.toggle()
    onRightClicked: AudioService.toggleMute()
    onScrolled: up => AudioService.adjust(up)
}
