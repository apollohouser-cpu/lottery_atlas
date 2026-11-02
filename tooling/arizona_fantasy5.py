"""Fantasy 5 evidence parser entry point."""
from tooling.arizona_daily_lotto import parse_capture as _parse

SOURCE = 'https://www.arizonalottery.com/draw-games/fantasy-5/'


def parse_capture(capture):
    return _parse(capture, 'fantasy-5')
