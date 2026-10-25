#!/usr/bin/env python3
"""Watch login1 lock hints and Hyprlock without spawning periodic subprocesses."""
import json
import os
from pathlib import Path
from gi.repository import Gio, GLib

hint = False
previous = None
uid = os.getuid()

def publish():
    global previous
    locker = False
    for p in Path('/proc').iterdir():
        if not p.name.isdecimal():
            continue
        try:
            if p.stat().st_uid == uid and (p / 'comm').read_text().strip() == 'hyprlock':
                locker = True
                break
        except (OSError, ProcessLookupError):
            pass
    value = bool(hint or locker)
    if value != previous:
        print(json.dumps({'locked': value}), flush=True)
        previous = value
    return GLib.SOURCE_CONTINUE

try:
    bus = Gio.bus_get_sync(Gio.BusType.SYSTEM, None)
    reply = bus.call_sync('org.freedesktop.login1', '/org/freedesktop/login1',
        'org.freedesktop.login1.Manager', 'GetSessionByPID', GLib.Variant('(u)', (os.getpid(),)),
        GLib.VariantType('(o)'), Gio.DBusCallFlags.NONE, 3000, None)
    path = reply.unpack()[0]
    proxy = Gio.DBusProxy.new_sync(bus, Gio.DBusProxyFlags.NONE, None,
        'org.freedesktop.login1', path, 'org.freedesktop.login1.Session', None)
    def changed(obj, changes, invalidated):
        global hint
        value = obj.get_cached_property('LockedHint')
        hint = bool(value.unpack()) if value is not None else False
        publish()
    proxy.connect('g-properties-changed', changed)
    changed(proxy, None, None)
except GLib.Error:
    pass  # Hyprlock detection and Wayland's session-lock boundary still apply.
publish()
GLib.timeout_add_seconds(1, publish)
GLib.MainLoop().run()
