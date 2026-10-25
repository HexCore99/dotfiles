"""Protocol tests: routing, safe arguments, volume bounds, and absent defaults."""
import unittest
from unittest.mock import patch
import backend

class AudioTests(unittest.TestCase):
    @patch('backend.pactl')
    def test_volume_and_routing(self, call):
        backend.action(dict(op='volume', kind='sink', id='57', value=135))
        call.assert_called_with('set-sink-volume', '57', '100%')
        backend.action(dict(op='volume', kind='source', id='59', value=-10))
        call.assert_called_with('set-source-volume', '59', '0%')
        backend.action(dict(op='route', kind='sink-input', id='91', value='57'))
        call.assert_called_with('move-sink-input', '91', '57')
        backend.action(dict(op='profile', kind='card', id='45', value='HiFi (Speaker, Mic1)'))
        call.assert_called_with('set-card-profile', '45', 'HiFi (Speaker, Mic1)')

    @patch('backend.pactl')
    def test_reject_invalid_actions(self, call):
        for args in [dict(op='volume', kind='sink', id='; echo bad', value=50),
                     dict(op='route', kind='card', id='45', value='57')]:
            with self.assertRaises(ValueError): backend.action(args)
        call.assert_not_called()

    @patch('backend.listing')
    @patch('backend.pactl', side_effect=RuntimeError('No default'))
    def test_off_profile_keeps_cards(self, call, listing):
        listing.side_effect = lambda kind: [dict(index=45, name='card', active_profile='off', profiles={'off': {'description': 'Off'}})] if kind == 'cards' else []
        self.assertEqual(backend.snapshot()['cards'][0]['profile'], 'off')

    @patch('backend.listing', return_value=[dict(index=54, name='hdmi', ports=[dict(name='hdmi', availability='not available')])])
    @patch('backend.pactl')
    def test_disconnected_selection_explains_failure(self, call, listing):
        with self.assertRaisesRegex(ValueError, 'not connected'):
            backend.action(dict(op='default', kind='sink', id='54'))
        call.assert_not_called()

    @patch('backend.listing', return_value=[dict(index=54, name='hdmi', ports=[])])
    @patch('backend.pactl', side_effect=['', 'hdmi'])
    def test_connected_selection_verified(self, call, listing):
        backend.action(dict(op='default', kind='sink', id='54'))
        self.assertEqual(call.call_args_list[0].args, ('set-default-sink', '54'))
        self.assertEqual(call.call_args_list[1].args, ('get-default-sink',))

    @patch('backend.time.sleep')
    @patch('backend.listing', return_value=[dict(index=54, name='hdmi', ports=[])])
    @patch('backend.pactl', return_value='speaker')
    def test_server_refusal_is_not_silent(self, call, listing, sleep):
        with self.assertRaisesRegex(RuntimeError, 'did not activate'):
            backend.action(dict(op='default', kind='sink', id='54'))

    def test_unplugged_ports(self):
        item = backend.node(dict(index=3, name='hdmi', ports=[dict(name='hdmi', availability='not available')]), 'sink', '')
        self.assertFalse(item['available'])
        self.assertEqual(item['volume'], 0)
        self.assertFalse(item['hasVolume'])

if __name__ == '__main__': unittest.main()
