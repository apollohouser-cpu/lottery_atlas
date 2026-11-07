"""Compatibility entry point for the audited Play 5 schedule."""
from tooling.delaware_play_chart_rules import parse as parse_chart


def parse(chart_bytes, *, chart_url):
    return parse_chart(chart_bytes, chart_url=chart_url, digits=5)
