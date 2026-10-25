#!/usr/bin/env python3
"""Small pactl adapter. JSON protocol, bounded subprocesses, no shell commands."""
import json
import subprocess
import sys
import time


def pactl(*args):
    result = subprocess.run(['pactl', *map(str, args)], capture_output=True, text=True, timeout=5)
    if result.returncode:
        raise RuntimeError(result.stderr.strip() or 'Audio server is unavailable')
    return result.stdout.strip()


def listing(kind):
    return json.loads(pactl('-f', 'json', 'list', kind))


def choices(values):
    if isinstance(values, dict):
        values = [dict(value, name=key) for key, value in values.items()]
    return [dict(name=v['name'], label=v.get('description', v['name']),
                 available=v.get('available', True) not in (False, 'no') and v.get('availability') != 'not available') for v in values]


def node(item, kind, default):
    props = item.get('properties', {})
    volumes = list(item.get('volume', {}).values())
    ports = choices(item.get('ports', []))
    return dict(id=str(item['index']), name=item.get('name', str(item['index'])), kind=kind,
                title=props.get('application.name') or props.get('device.profile.description') or item.get('description') or 'Audio stream',
                detail=props.get('media.name') or item.get('description', ''),
                volume=round(sum(v['value'] for v in volumes) / len(volumes) / 65536 * 100) if volumes else 0,
                hasVolume=bool(volumes), muted=item.get('mute', False),
                default=item.get('name') == default, ports=ports,
                port=item.get('active_port', ''), route=str(item.get('sink', item.get('source', ''))),
                available=not ports or any(p['available'] for p in ports))


def snapshot():
    def default(kind):
        try:
            return pactl('get-default-' + kind)
        except RuntimeError:
            return ''  # Off profiles can leave no default node; cards still work.
    sink, source = default('sink'), default('source')
    result = {}
    for key, kind, default in [('outputs', 'sinks', sink), ('inputs', 'sources', source),
                               ('playback', 'sink-inputs', ''), ('recording', 'source-outputs', '')]:
        result[key] = [node(i, kind.rstrip('s'), default) for i in listing(kind)
                       if not (key == 'inputs' and i.get('name', '').endswith('.monitor'))]
        result[key].sort(key=lambda n: (not n['default'], not n['available'], n['id']))
    result['cards'] = [dict(id=str(c['index']), name=c['name'], kind='card',
                          title=c.get('properties', {}).get('device.description', c['name']),
                          profile=c['active_profile'], profiles=choices(c['profiles'])) for c in listing('cards')]
    return result


def action(request):
    op, kind, target = request['op'], request['kind'], str(request['id'])
    if kind not in ('sink', 'source', 'sink-input', 'source-output', 'card'):
        raise ValueError('Unsupported audio object')
    if not target.isdecimal():
        raise ValueError('Invalid audio object ID')
    value = request.get('value')
    if op == 'volume' and kind != 'card':
        pactl('set-' + kind + '-volume', target, str(max(0, min(100, int(value)))) + '%')
    elif op == 'mute' and kind != 'card':
        pactl('set-' + kind + '-mute', target, '1' if value else '0')
    elif op == 'default' and kind in ('sink', 'source'):
        devices = listing('sinks' if kind == 'sink' else 'sources')
        device = next((d for d in devices if str(d['index']) == target), None)
        if device is None:
            raise ValueError('This audio device is no longer available. Refresh and try again.')
        ports = choices(device.get('ports', []))
        if ports and not any(p['available'] for p in ports):
            label = device.get('properties', {}).get('device.profile.description') or device.get('description', 'This device')
            raise ValueError(label + ' is not connected. Connect a display or audio device to that port, then try again.')
        pactl('set-default-' + kind, target)
        # A successful pactl exit does not guarantee WirePlumber selected it.
        for _ in range(6):
            if pactl('get-default-' + kind) == device['name']:
                return
            time.sleep(0.1)
        raise RuntimeError('The audio server did not activate this device. Check its connection and hardware profile.')
    elif op == 'port' and kind in ('sink', 'source'):
        pactl('set-' + kind + '-port', target, value)
    elif op == 'route' and kind in ('sink-input', 'source-output') and str(value).isdecimal():
        pactl('move-' + kind, target, value)
    elif op == 'profile' and kind == 'card':
        pactl('set-card-profile', target, value)
    else:
        raise ValueError('Unsupported audio action')


if __name__ == '__main__':
    try:
        if len(sys.argv) > 1:
            action(json.loads(sys.argv[1]))
            print(json.dumps({'ok': True}))
        else:
            print(json.dumps(snapshot()))
    except (OSError, ValueError, KeyError, RuntimeError, subprocess.TimeoutExpired) as error:
        print(json.dumps({'error': str(error)}))
        sys.exit(1)
