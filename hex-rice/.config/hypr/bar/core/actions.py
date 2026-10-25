#!/usr/bin/env python3
"""External app actions, kept separate from the visual QML modules.
All commands use argument lists; device names and menu selections are never
executed as shell code. Adjust the application commands in launch() to taste.
"""
from pathlib import Path
import subprocess
import sys


def run(args, **kwargs):
    """Run a short utility and return its text output; do not block indefinitely."""
    return subprocess.run(args, capture_output=True, text=True, timeout=15, **kwargs)


def launch(*args):
    """Open an app independently so closing the menu doesn't close the app."""
    subprocess.Popen(args, stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL,
                     stderr=subprocess.DEVNULL, start_new_session=True)


def menu(lines, prompt):
    """Fuzzel supplies an accessible keyboard-driven menu outside the bar."""
    result = subprocess.run(['fuzzel', '--dmenu', '--prompt', prompt + ' > ',
                             '--width', '48', '--lines', str(min(12, max(3, len(lines)))),
                             '--font', 'monospace:size=11', '--background-color', '090909ff',
                             '--text-color', 'bdbdbdff', '--selection-color', '252525ff',
                             '--selection-text-color', 'eeeeeeff', '--border-color', '343434ff',
                             '--border-radius', '0', '--border-width', '1'],
                            input='\n'.join(lines), capture_output=True, text=True)
    return result.stdout.strip() if result.returncode == 0 else ''


def bluetooth():
    """Open the native overlay; its private BlueZ agent handles pairing prompts."""
    run(['quickshell', '-p', str(Path.home()/'.config/hypr/bar'),
         'ipc', 'call', 'bar', 'bluetoothMenu'])


def power():
    """Open the native Quickshell menu; system actions live in power_actions.py."""
    run(['quickshell', '-p', str(Path.home()/'.config/hypr/bar'),
         'ipc', 'call', 'bar', 'powerMenu'])


def notifications():
    """Toggle the independent Quickshell notification center."""
    run(['quickshell', '-p', str(Path.home()/'.config/hypr/notification-shell.qml'),
         'ipc', 'call', 'notifications', 'toggle'])


def main(action):
    if action == 'launcher': launch('sh', str(Path.home()/'.config/hypr/scripts/launcher'))
    elif action == 'network':
        run(['quickshell', '-p', str(Path.home()/'.config/hypr/bar'), 'ipc', 'call', 'bar', 'wifiMenu'])
    elif action == 'network-advanced': launch('foot', '--title=Network connections', '-e', 'nmtui')
    elif action == 'audio':
        run(['quickshell', '-p', str(Path.home()/'.config/hypr/bar'), 'ipc', 'call', 'bar', 'soundMenu'])
    elif action == 'monitor': launch('foot', '--title=System monitor', '-e', 'btop')
    elif action == 'bluetooth': bluetooth()
    elif action == 'power': power()
    elif action == 'notifications': notifications()
    elif action == 'calendar':
        # Date/time opens the calendar only; the bell opens notifications.
        run(['quickshell', '-p', str(Path.home()/'.config/hypr/notification-shell.qml'),
             'ipc', 'call', 'notifications', 'calendar'])
    elif action == 'battery':
        # UPower provides real battery information without changing power settings.
        output = run(['upower', '--dump']).stdout
        lines = [line.strip() for line in output.splitlines() if any(
            key in line for key in ('state:', 'percentage:', 'time to', 'energy-rate:', 'capacity:', 'model:'))]
        menu(lines or ['No battery information available'], 'Battery')
    else:
        raise SystemExit('Unknown bar action: ' + action)


if __name__ == '__main__':
    try:
        main(sys.argv[1] if len(sys.argv) > 1 else 'launcher')
    except (OSError, subprocess.TimeoutExpired) as error:
        subprocess.run(['notify-send', '-a', 'Bar', 'Could not run action', str(error)], check=False)
        raise SystemExit(1)
