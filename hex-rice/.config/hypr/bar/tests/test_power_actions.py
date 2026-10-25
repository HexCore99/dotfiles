"""Verify command routing without locking, sleeping, rebooting or powering off."""
import importlib.util
from pathlib import Path
from types import SimpleNamespace
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location('power_actions', Path(__file__).parents[1]/'core/power_actions.py')
power = importlib.util.module_from_spec(spec)
spec.loader.exec_module(power)


class PowerActionsTests(unittest.TestCase):
    def test_system_actions_use_the_correct_systemctl_verb(self):
        for action, verb in [('sleep', 'suspend'), ('restart', 'reboot'), ('poweroff', 'poweroff')]:
            with self.subTest(action=action), patch.object(power.subprocess, 'run') as run:
                power.execute(action)
                self.assertEqual(run.call_args.args[0], ['systemctl', verb])
                self.assertTrue(run.call_args.kwargs['check'])

    def test_lock_starts_existing_locker_config(self):
        with patch.object(power.subprocess, 'run', return_value=SimpleNamespace(returncode=1)), \
             patch.object(power.subprocess, 'Popen') as launch:
            power.execute('lock')
            self.assertEqual(launch.call_args.args[0], ['hyprlock', '-c', str(Path.home()/'.config/hypr/hyprlock.conf')])

    def test_lock_does_not_duplicate_an_existing_locker(self):
        with patch.object(power.subprocess, 'run', return_value=SimpleNamespace(returncode=0)), \
             patch.object(power.subprocess, 'Popen') as launch:
            power.execute('lock')
            launch.assert_not_called()

    def test_unknown_actions_never_spawn_commands(self):
        with patch.object(power.subprocess, 'run') as run, patch.object(power.subprocess, 'Popen') as launch:
            with self.assertRaises(ValueError):
                power.execute('poweroff; arbitrary-command')
            run.assert_not_called()
            launch.assert_not_called()


if __name__ == '__main__':
    unittest.main()
