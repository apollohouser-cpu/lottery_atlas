enum MapDetailMode { simple, standard, detailed }

extension MapDetailModeLabel on MapDetailMode {
  String get label {
    switch (this) {
      case MapDetailMode.simple:
        return 'Simple';
      case MapDetailMode.standard:
        return 'Standard';
      case MapDetailMode.detailed:
        return 'Detailed';
    }
  }

  String get description {
    switch (this) {
      case MapDetailMode.simple:
        return 'Fastest view with minimal map data.';
      case MapDetailMode.standard:
        return 'Street map with normal detail.';
      case MapDetailMode.detailed:
        return 'Satellite-style imagery and richer overlays.';
    }
  }
}
