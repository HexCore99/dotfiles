#!/usr/bin/env python3
"""BlueZ operations and pairing agent for the QML Bluetooth overlay.

One JSON command/event per line over private process pipes. Device operations
are asynchronous; PIN requests wait for an explicit response from the overlay.
This agent is registered only for this application, never as the global default.
"""
import json
import os
import re
import sys
from gi.repository import Gio, GLib

AGENT_PATH = '/local/hypr/BluetoothAgent'
DEVICE_PATH = re.compile(r'^/org/bluez/hci\d+/dev_(?:[0-9A-Fa-f]{2}_){5}[0-9A-Fa-f]{2}$')
METHODS = {
    'Release': ('', ''), 'RequestPinCode': ('o', 's'),
    'DisplayPinCode': ('os', ''), 'RequestPasskey': ('o', 'u'),
    'DisplayPasskey': ('ouq', ''), 'RequestConfirmation': ('ou', ''),
    'RequestAuthorization': ('o', ''), 'AuthorizeService': ('os', ''),
    'Cancel': ('', ''),
}
XML = '<node><interface name="org.bluez.Agent1">' + ''.join(
    '<method name="' + name + '">' + ''.join(
        '<arg type="' + t + '" direction="' + direction + '"/>'
        for types, direction in ((inputs, 'in'), (outputs, 'out')) for t in types
    ) + '</method>' for name, (inputs, outputs) in METHODS.items()
) + '</interface></node>'


class Agent:
    def __init__(self):
        self.bus = Gio.bus_get_sync(Gio.BusType.SYSTEM, None)
        self.owner = None
        self.pending = None
        self.active = None
        self.buffer = b''
        interface = Gio.DBusNodeInfo.new_for_xml(XML).interfaces[0]
        self.bus.register_object(AGENT_PATH, interface, self.method, None, None)
        Gio.bus_watch_name_on_connection(self.bus, 'org.bluez', Gio.BusNameWatcherFlags.NONE,
                                        self.appeared, self.vanished)
        GLib.io_add_watch(sys.stdin.fileno(), GLib.IO_IN | GLib.IO_HUP, self.read)

    def emit(self, event, **values):
        print(json.dumps(dict(event=event, **values)), flush=True)

    def appeared(self, connection, name, owner):
        self.owner = owner
        self.bus.call('org.bluez', '/org/bluez', 'org.bluez.AgentManager1',
                      'RegisterAgent', GLib.Variant('(os)', (AGENT_PATH, 'KeyboardDisplay')),
                      None, Gio.DBusCallFlags.NONE, 10000, None, self.registered)

    def registered(self, connection, result):
        try:
            connection.call_finish(result)
            self.emit('ready', ready=True)
        except GLib.Error:
            self.emit('ready', ready=False, error='Could not register the Bluetooth pairing agent.')

    def vanished(self, *_):
        self.owner = None
        self.reject()
        self.emit('ready', ready=False, error='Bluetooth service is unavailable.')

    def reject(self):
        if self.pending:
            invocation, _ = self.pending
            self.pending = None
            invocation.return_dbus_error('org.bluez.Error.Rejected', 'Pairing declined')
        self.emit('prompt-clear')

    def method(self, connection, sender, path, interface, method, params, invocation):
        if sender != self.owner:
            invocation.return_dbus_error('org.bluez.Error.Rejected', 'Not the Bluetooth service')
            return
        args = params.unpack()
        if method in ('Release', 'Cancel'):
            self.reject()
            invocation.return_value(GLib.Variant('()', ()))
            return
        if not self.active or args[0] != self.active['path']:
            invocation.return_dbus_error('org.bluez.Error.Rejected', 'No matching user request')
            return
        if method in ('DisplayPinCode', 'DisplayPasskey'):
            code = args[1] if method == 'DisplayPinCode' else f'{args[1]:06d}'
            self.emit('prompt', kind='display', code=code, path=args[0])
            invocation.return_value(GLib.Variant('()', ()))
        else:
            if self.pending:
                self.reject()
            kind = {'RequestPinCode': 'pin', 'RequestPasskey': 'passkey',
                    'RequestConfirmation': 'confirm'}.get(method, 'authorize')
            self.pending = (invocation, kind)
            self.emit('prompt', kind=kind, path=args[0],
                      code=f'{args[1]:06d}' if kind == 'confirm' else '')

    def reply(self, value, accepted):
        if not self.pending:
            return
        if not accepted:
            self.reject()
            return
        invocation, kind = self.pending
        value = str(value)
        if kind == 'pin':
            if not 1 <= len(value) <= 16:
                raise ValueError('Enter a PIN of 1–16 characters.')
            variant = GLib.Variant('(s)', (value,))
        elif kind == 'passkey':
            if not re.fullmatch(r'[0-9]{1,6}', value):
                raise ValueError('Enter a numeric passkey of up to six digits.')
            variant = GLib.Variant('(u)', (int(value),))
        else:
            variant = GLib.Variant('()', ())
        self.pending = None
        invocation.return_value(variant)
        self.emit('prompt-clear')

    def command(self, packet):
        action = packet.get('action')
        if action == 'reply':
            self.reply(packet.get('value', ''), packet.get('accepted') is True)
            return
        if action == 'cancel':
            self.reject()
            if self.active and self.active['action'] in ('pair', 'connect'):
                self.bus.call('org.bluez', self.active['path'], 'org.bluez.Device1',
                              'CancelPairing' if self.phase == 'Pair' else 'Disconnect', None, None, Gio.DBusCallFlags.NONE,
                              5000, None, None)
            return
        path = packet.get('path', '')
        if action not in ('pair', 'connect', 'disconnect') or not DEVICE_PATH.fullmatch(path):
            raise ValueError('Invalid Bluetooth device operation.')
        if self.active:
            raise ValueError('Another Bluetooth operation is in progress.')
        self.active = {'action': action, 'path': path, 'id': packet.get('id')}
        self.call_device(action.capitalize())

    def call_device(self, method):
        self.phase = method
        self.bus.call('org.bluez', self.active['path'], 'org.bluez.Device1', method,
                      None, None, Gio.DBusCallFlags.NONE, 90000, None,
                      lambda connection, result: self.completed(connection, result, method))

    def completed(self, connection, result, method):
        try:
            connection.call_finish(result)
            if method == 'Pair':
                self.emit('prompt-clear')
                self.call_device('Connect')
                return
            self.emit('result', ok=True, **self.active)
        except GLib.Error as error:
            name = Gio.DBusError.get_remote_error(error) or 'org.bluez.Error.Failed'
            self.emit('result', ok=False, error=name.rsplit('.', 1)[-1], **self.active)
        self.active = None
        self.reject()

    def read(self, fd, condition):
        data = os.read(fd, 65536)
        if not data:
            self.reject()
            loop.quit()
            return GLib.SOURCE_REMOVE
        self.buffer += data
        while b'\n' in self.buffer:
            line, self.buffer = self.buffer.split(b'\n', 1)
            try:
                self.command(json.loads(line))
            except (ValueError, TypeError, GLib.Error):
                # Never echo submitted PINs, passkeys or raw input to the log.
                self.emit('validation', error='Invalid request or pairing code. Check the code and try again.')
        return GLib.SOURCE_CONTINUE


if __name__ == '__main__':
    loop = GLib.MainLoop()
    try:
        agent = Agent()
        loop.run()
    except GLib.Error:
        print(json.dumps({'event': 'ready', 'ready': False,
                          'error': 'Bluetooth service is unavailable.'}), flush=True)
