"""Exercise agent callbacks against fake D-Bus invocations; never touch BlueZ."""
import importlib.util
from pathlib import Path
import unittest
from unittest.mock import Mock
from gi.repository import GLib

spec = importlib.util.spec_from_file_location('bluetooth_agent', Path(__file__).parents[1] / 'services/bluetooth-agent.py')
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
PATH = '/org/bluez/hci0/dev_00_11_22_33_44_55'


class AgentTests(unittest.TestCase):
    def setUp(self):
        self.agent = module.Agent.__new__(module.Agent)
        self.agent.owner = ':bluez-test'
        self.agent.active = {'id': 7, 'action': 'pair', 'path': PATH}
        self.agent.pending = None
        self.agent.bus = Mock()
        self.agent.emit = Mock()

    def request(self, method, signature, values, sender=':bluez-test'):
        invocation = Mock()
        self.agent.method(None, sender, module.AGENT_PATH, 'org.bluez.Agent1',
                          method, GLib.Variant(signature, values), invocation)
        return invocation

    def test_numeric_comparison_waits_for_explicit_confirmation(self):
        request = self.request('RequestConfirmation', '(ou)', (PATH, 42))
        request.return_value.assert_not_called()
        self.agent.emit.assert_called_with('prompt', kind='confirm', path=PATH, code='000042')
        self.agent.reply('', True)
        self.assertEqual(request.return_value.call_args.args[0].unpack(), ())
        self.assertIsNone(self.agent.pending)

    def test_pin_and_passkey_return_the_correct_dbus_types(self):
        for method, value, expected, signature in [('RequestPinCode', '1234', ('1234',), '(s)'),
                                                  ('RequestPasskey', '000042', (42,), '(u)')]:
            with self.subTest(method=method):
                request = self.request(method, '(o)', (PATH,))
                self.agent.reply(value, True)
                result = request.return_value.call_args.args[0]
                self.assertEqual(result.get_type_string(), signature)
                self.assertEqual(result.unpack(), expected)

    def test_invalid_passkey_does_not_consume_pending_prompt(self):
        request = self.request('RequestPasskey', '(o)', (PATH,))
        for value in ['1234567', '-1', '12x', '']:
            with self.assertRaises(ValueError):
                self.agent.reply(value, True)
        request.return_value.assert_not_called()
        self.assertIsNotNone(self.agent.pending)

    def test_rejection_and_cancel_release_pending_requests(self):
        request = self.request('RequestAuthorization', '(o)', (PATH,))
        self.agent.reply('', False)
        request.return_dbus_error.assert_called_once()
        self.assertIsNone(self.agent.pending)
        pending = self.request('RequestPinCode', '(o)', (PATH,))
        self.request('Cancel', '()', ())
        pending.return_dbus_error.assert_called_once()
        self.assertIsNone(self.agent.pending)

    def test_unrelated_sender_or_device_cannot_trigger_prompt(self):
        request = self.request('RequestPinCode', '(o)', (PATH,), sender=':unrelated')
        request.return_dbus_error.assert_called_once()
        request = self.request('RequestPinCode', '(o)', (PATH.replace('hci0', 'hci1'),))
        request.return_dbus_error.assert_called_once()
        self.agent.emit.assert_not_called()

    def test_display_passkey_preserves_leading_zeroes(self):
        self.request('DisplayPasskey', '(ouq)', (PATH, 42, 0))
        self.agent.emit.assert_called_with('prompt', kind='display', code='000042', path=PATH)

    def test_successful_pairing_connects_then_reports_result(self):
        connection = Mock()
        self.agent.call_device = Mock()
        self.agent.completed(connection, Mock(), 'Pair')
        self.agent.call_device.assert_called_once_with('Connect')
        self.assertIsNotNone(self.agent.active)
        self.agent.completed(connection, Mock(), 'Connect')
        self.agent.emit.assert_any_call('result', ok=True, id=7, action='pair', path=PATH)
        self.assertIsNone(self.agent.active)

    def test_only_allowlisted_operations_and_device_paths_are_accepted(self):
        self.agent.active = None
        for command in [{'action': 'exec', 'path': PATH}, {'action': 'pair', 'path': '/org/bluez'}]:
            with self.assertRaises(ValueError):
                self.agent.command(command)
        self.agent.bus.call.assert_not_called()
