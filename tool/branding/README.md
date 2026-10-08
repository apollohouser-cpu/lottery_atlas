# Mobile compass exports

`export_mobile_icons.py` reuses the existing header's `Icons.explore_rounded`
(U+F724) from Flutter's MaterialIcons font and Lottery Atlas blue gradient.
It draws the glyph directly; it does not modify or reuse the Flutter template
launcher image. Requires Python with Pillow and a Flutter SDK containing the
MaterialIcons font. Run from any directory:

    python export_mobile_icons.py /path/to/flutter

Exports all declared iOS icon slots as opaque RGB PNGs, five Android legacy
sizes and transparent adaptive foregrounds on a 108dp canvas. The adaptive
background is defined separately in Android colors.xml. Native launcher mask,
splash and installed app verification remain required after a mobile build.

Material icon artwork: Google Material Icons, supplied by Flutter's
MaterialIcons-Regular.otf; accompanying upstream license is retained in
MaterialIcons_LICENSE.txt (Creative Commons Attribution 4.0). Modifications:
white glyph rendered at platform-specific sizes, centered and composited over
Lottery Atlas colors. No font file is copied into this directory.
