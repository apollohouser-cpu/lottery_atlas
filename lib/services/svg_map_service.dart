import 'package:flutter/services.dart';
import 'package:xml/xml.dart';

class SvgMapService {
  Future<List<Map<String, String>>> loadStates() async {
    final svgString = await rootBundle.loadString('assets/maps/us.svg');

    final document = XmlDocument.parse(svgString);

    final paths = document.findAllElements('path');

    List<Map<String, String>> states = [];

    for (final path in paths) {
      final id = path.getAttribute('id');
      final name = path.getAttribute('data-name');

      if (id != null && name != null) {
        states.add({'id': id, 'name': name});
      }
    }

    return states;
  }
}
