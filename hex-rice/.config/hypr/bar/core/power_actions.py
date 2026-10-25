#!/usr/bin/env python3
"""Execute only the four explicit power-menu actions.
The UI closes before invoking this helper. System operations are argument lists,
not shell expressions, and errors are reported through the notification daemon.
"""
from pathlib import Path
import subprocess
import sys


def execute(action):
    """Lock directly with the existing config; let Hypridle lock before sleep."""
    if action == 'lock':
        # Do not start a second locker when the session is already locked.
        if subprocess.run(['pgrep', '-x', 'hyprlock'], capture_output=True).returncode:
            subprocess.Popen(['hyprlock', '-c', str(Path.home()/'.config/hypr/hyprlock.conf')],
                             stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL,
                             stderr=subprocess.DEVNULL, start_new_session=True)
    elif action in ('sleep', 'restart', 'poweroff'):
        verb = {'sleep': 'suspend', 'restart': 'reboot', 'poweroff': 'poweroff'}[action]
        subprocess.run(['systemctl', verb], check=True, capture_output=True, text=True, timeout=30)
    else:
        raise ValueError('Unsupported power action: ' + action)


if __name__ == '__main__':
    try:
        execute(sys.argv[1] if len(sys.argv) == 2 else '')
    except (ValueError, OSError, subprocess.SubprocessError) as error:
        message = getattr(error, 'stderr', None) or str(error)
        subprocess.run(['notify-send', '-a', 'Power menu', 'Power action failed', message], check=False)
        raise SystemExit(1)
