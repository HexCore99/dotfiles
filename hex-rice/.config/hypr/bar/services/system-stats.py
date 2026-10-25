#!/usr/bin/env python3
"""One small sampler: CPU deltas and MemAvailable, without shell commands."""
import json
import time
from pathlib import Path

def cpu_times():
    values = list(map(int, Path('/proc/stat').read_text().splitlines()[0].split()[1:9]))
    return sum(values), values[3] + values[4]

previous_total, previous_idle = cpu_times()
while True:
    time.sleep(2)
    total, idle = cpu_times()
    elapsed = total - previous_total
    cpu = round(100 * (1 - (idle - previous_idle) / elapsed)) if elapsed else 0
    previous_total, previous_idle = total, idle
    memory = {}
    for line in Path('/proc/meminfo').read_text().splitlines():
        key, value = line.split(':', 1)
        memory[key] = int(value.split()[0])
    used = round(100 * (1 - memory['MemAvailable'] / memory['MemTotal']))
    print(json.dumps({'cpu': max(0, min(100, cpu)), 'memory': used}), flush=True)
