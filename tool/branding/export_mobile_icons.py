"""Export existing Lottery Atlas compass branding. Requires Pillow and Flutter SDK.
Usage: python export_mobile_icons.py /path/to/flutter
No new design, downloaded assets, or app builds are involved.
"""
import argparse
import json
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]
BLUE = (20, 120, 255)
DEEP = (7, 58, 138)


def compass(font_path, size, fraction, background=True):
    image = Image.new('RGBA', (size, size))
    if background:
        pixels = image.load()
        for y in range(size):
            for x in range(size):
                t = (x + y) / (2 * (size - 1))
                pixels[x, y] = tuple(round(a + (b-a)*t) for a, b in zip(BLUE, DEEP)) + (255,)
    font = ImageFont.truetype(str(font_path), round(size * fraction))
    draw = ImageDraw.Draw(image)
    glyph = chr(0xf724)  # Flutter Icons.explore_rounded, same as in-app header.
    left, top, right, bottom = draw.textbbox((0, 0), glyph, font=font)
    draw.text(((size-right+left)/2-left, (size-bottom+top)/2-top), glyph, font=font, fill='white')
    return image


def export(sdk):
    font = sdk / 'bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf'
    assert font.is_file(), 'Flutter Material icon font is required'
    master = compass(font, 1024, .68)
    icons = ROOT / 'ios/Runner/Assets.xcassets/AppIcon.appiconset'
    for item in json.loads((icons/'Contents.json').read_text())['images']:
        size = round(float(item['size'].split('x')[0]) * float(item['scale'][:-1]))
        master.resize((size, size), Image.Resampling.LANCZOS).convert('RGB').save(icons/item['filename'])
    res = ROOT / 'android/app/src/main/res'
    # Legacy launcher artwork is opaque; launcher supplies its own mask where supported.
    for density, scale in [('mdpi',1), ('hdpi',1.5), ('xhdpi',2), ('xxhdpi',3), ('xxxhdpi',4)]:
        folder = res / ('mipmap-' + density)
        master.resize((round(48*scale),)*2, Image.Resampling.LANCZOS).convert('RGB').save(folder/'ic_launcher.png')
        # Centered foreground within the adaptive icon safe area (108dp canvas).
        foreground = compass(font, 432, .50, background=False)
        foreground.resize((round(108*scale),)*2, Image.Resampling.LANCZOS).save(folder/'ic_launcher_foreground.png')
    launch = ROOT / 'ios/Runner/Assets.xcassets/LaunchImage.imageset'
    for scale in (1, 2, 3):
        suffix = '' if scale == 1 else f'@{scale}x'
        compass(font, 360, .68, background=False).resize((120*scale,)*2, Image.Resampling.LANCZOS).save(launch/f'LaunchImage{suffix}.png')
    print('Exported launcher icons and three iOS launch images.')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('flutter_sdk', type=Path)
    export(parser.parse_args().flutter_sdk)
