# Sound Studio

Click the bar volume button or press **Ctrl+Alt+V** to toggle the animated
Quickshell panel. Escape or a click outside closes it. Right-clicking the bar
volume button still toggles mute; scrolling still adjusts volume.

- **Output:** volume, mute, default output and ports when a device offers several.
- **Input:** microphone volume, mute, default input and ports.
- **Apps:** playback and recording streams, individual volume/mute and routing.
  Apps appear while they have an audio stream. Choosing a default device affects
  policy for new streams; use each app's routing selector to move existing audio.
- **Cards:** hardware profiles, including HiFi, Pro Audio and Off when advertised
  by the audio server. Unavailable profiles and port choices are disabled.
  Click an available device card or Use device to select it. Disconnected
  devices remain visible as dimmed, disabled cards with inactive controls.
  The default highlight always reflects the audio server.
  Turning a card off removes its devices; the card remains here to re-enable it.

The panel uses `python3` and `pactl` with PipeWire's PulseAudio service. Snapshots
refresh every 1.5 seconds only while open; writes are serialized and rapid slider
changes are coalesced. Volume is capped at 100%. No shell evaluation is used for
profile names or other server-provided strings. Errors appear inside the panel.

Appearance and animations: `../popups/SoundMenu.qml` and the components here.
Backend: `backend.py`; state and process orchestration: `../services/SoundService.qml`.
The existing `AudioService.qml` continues to provide live master volume.

Commands:

```sh
~/.config/hypr/scripts/barctl sound
~/.config/hypr/scripts/barctl sound-status
qs -p ~/.config/hypr/bar ipc call sound page cards
python3 -B -m unittest discover -s ~/.config/hypr/bar/audio -p 'test_*.py'
```

The `sound page` command accepts `output`, `input`, `apps`, or `cards`.

Volume changes and mute toggles also show a passive animated indicator below
the centered notification/clock card. It follows the default output in real time,
including changes from media keys, bar scrolling, and Sound Studio. It fades
after 1.5 seconds of inactivity and never takes focus or intercepts clicks.
Adjust `volumeOsdWidth` and `volumeOsdTimeout` in `../Settings.qml`; layout and
animations live in `../popups/VolumeOsd.qml`.
