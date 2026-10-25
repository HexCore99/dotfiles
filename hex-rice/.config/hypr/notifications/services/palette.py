#!/usr/bin/env python3
"""Extract a restrained, readable dark palette from the active wallpaper."""
import colorsys
import json
from pathlib import Path
from PIL import Image, ImageOps


def palette(path):
    with Image.open(path) as source:
        image = ImageOps.exif_transpose(source).convert('RGB')
        image.thumbnail((96, 96))
        buckets = [0.0] * 36
        for r, g, b in (image.get_flattened_data() if hasattr(image, "get_flattened_data") else image.getdata()):
            h, s, v = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
            if .15 < v < .96:
                buckets[int(h * 36) % 36] += s * s * v
        hue = (max(range(36), key=buckets.__getitem__) + .5) / 36 if max(buckets) else .42
    def color(saturation, lightness):
        rgb = colorsys.hls_to_rgb(hue, lightness, saturation)
        return '#' + ''.join(f'{round(c * 255):02x}' for c in rgb)
    return dict(background=color(.16, .095), card=color(.13, .145), hover=color(.17, .19),
                control=color(.14, .22), accent=color(.65, .75), accentText=color(.3, .12),
                text=color(.18, .94), muted=color(.12, .66), border=color(.17, .27))

if __name__ == '__main__':
    try:
        state = Path(__file__).resolve().parents[2] / 'wallpaper/state.json'
        print(json.dumps(palette(json.loads(state.read_text())['path'])))
    except (OSError, ValueError, KeyError):
        print('{}')  # Keep the last usable palette on missing or invalid wallpaper.
