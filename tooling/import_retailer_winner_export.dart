// Converts an authorized lottery-retailer winner export into Lottery Atlas
// activity JSON. This tool never signs in to, scrapes, or guesses data from a
// lottery portal. It only accepts a file the lottery or an authorized user has
// already exported, and requires exact coordinates for every record.
//
// Example:
// dart tooling/import_retailer_winner_export.dart \
//   --input /path/to/pa-retailer-winners.csv \
//   --output data/pennsylvania_retailer_export.initial.json \
//   --state PA \
//   --source-url https://www.palottery.pa.gov/ \
//   --source-label "Pennsylvania Lottery authorized retailer report"
//
// Required CSV columns (case and punctuation do not matter): draw_date,
// game_name, prize_amount, retailer_name, retailer_address, city, county,
// latitude, longitude.
//
// Optional columns: winning_tickets, game_code, source_url, source_label.
import 'dart:convert';
import 'dart:io';

const _requiredColumns = <String>[
  'drawdate',
  'gamename',
  'prizeamount',
  'retailername',
  'retaileraddress',
  'city',
  'county',
  'latitude',
  'longitude',
];

const _aliases = <String, List<String>>{
  'drawdate': <String>['drawdate', 'date', 'winningdate', 'claimdate'],
  'gamename': <String>['gamename', 'game', 'lotterygame'],
  'prizeamount': <String>['prizeamount', 'prize', 'amount', 'winningamount'],
  'retailername': <String>['retailername', 'retailer', 'store', 'businessname'],
  'retaileraddress': <String>['retaileraddress', 'address', 'storeaddress'],
  'city': <String>['city', 'retailercity', 'locationcity'],
  'county': <String>['county', 'retailercounty', 'locationcounty'],
  'latitude': <String>['latitude', 'lat'],
  'longitude': <String>['longitude', 'lon', 'lng'],
  'winningtickets': <String>[
    'winningtickets',
    'tickets',
    'ticketcount',
    'count',
  ],
  'gamecode': <String>['gamecode', 'category', 'gametype'],
  'sourceurl': <String>['sourceurl', 'recordurl', 'url'],
  'sourcelabel': <String>['sourcelabel', 'source'],
};

Never _fail(String message) => throw FormatException(message);

void _usage() {
  stdout.writeln('''
Usage:
  dart tooling/import_retailer_winner_export.dart --input FILE.csv --output FILE.json --state PA --source-url URL --source-label LABEL

The import is intentionally strict: every row must include the required
retailer address and exact latitude/longitude. Rows that cannot be validated
stop the import instead of appearing as a misleading heat-map point.
''');
}

Map<String, String> _arguments(List<String> arguments) {
  final values = <String, String>{};
  for (var index = 0; index < arguments.length; index += 1) {
    final argument = arguments[index];
    if (argument == '--help' || argument == '-h') {
      _usage();
      exit(0);
    }
    if (!argument.startsWith('--')) _fail('Unexpected argument: $argument');
    final key = argument.substring(2);
    if (index + 1 >= arguments.length ||
        arguments[index + 1].startsWith('--')) {
      _fail('Missing value for --$key.');
    }
    values[key] = arguments[index + 1];
    index += 1;
  }
  for (final key in <String>[
    'input',
    'output',
    'state',
    'source-url',
    'source-label',
  ]) {
    if (values[key] == null || values[key]!.isEmpty) {
      _fail('Missing required --$key.');
    }
  }
  if (!RegExp(r'^[A-Za-z]{2}$').hasMatch(values['state']!)) {
    _fail('--state must be a two-letter postal abbreviation.');
  }
  if (!_isUrl(values['source-url']!)) {
    _fail('--source-url must be a complete official source URL.');
  }
  return values;
}

bool _isUrl(String value) {
  final uri = Uri.tryParse(value);
  return uri != null && uri.hasScheme && uri.host.isNotEmpty;
}

String _normaliseHeader(String value) =>
    value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

List<List<String>> _parseCsv(String text) {
  final rows = <List<String>>[];
  var row = <String>[];
  final cell = StringBuffer();
  var quoted = false;
  for (var index = 0; index < text.length; index += 1) {
    final character = text[index];
    if (character == '"') {
      if (quoted && index + 1 < text.length && text[index + 1] == '"') {
        cell.write('"');
        index += 1;
      } else {
        quoted = !quoted;
      }
    } else if (character == ',' && !quoted) {
      row.add(cell.toString().trim());
      cell.clear();
    } else if ((character == '\n' || character == '\r') && !quoted) {
      if (character == '\r' &&
          index + 1 < text.length &&
          text[index + 1] == '\n') {
        index += 1;
      }
      row.add(cell.toString().trim());
      if (row.any((value) => value.isNotEmpty)) rows.add(row);
      row = <String>[];
      cell.clear();
    } else {
      cell.write(character);
    }
  }
  if (quoted) {
    _fail('The CSV has an unclosed quoted value.');
  }
  row.add(cell.toString().trim());
  if (row.any((value) => value.isNotEmpty)) rows.add(row);
  return rows;
}

Map<String, int> _columnMap(List<String> headers) {
  final normalisedHeaders = headers.map(_normaliseHeader).toList();
  final mapping = <String, int>{};
  for (final entry in _aliases.entries) {
    final index = normalisedHeaders.indexWhere(entry.value.contains);
    if (index >= 0) mapping[entry.key] = index;
  }
  final missing = _requiredColumns
      .where((column) => !mapping.containsKey(column))
      .toList();
  if (missing.isNotEmpty) {
    _fail('The CSV is missing required columns: ${missing.join(', ')}.');
  }
  return mapping;
}

String _valueAt(List<String> row, Map<String, int> mapping, String field) {
  final index = mapping[field];
  return index == null || index >= row.length ? '' : row[index].trim();
}

int? _money(String value) =>
    int.tryParse(value.replaceAll(RegExp(r'[$,\s]'), ''));

int? _tickets(String value) =>
    value.isEmpty ? 1 : int.tryParse(value.replaceAll(RegExp(r'[,\s]'), ''));

String _gameCode(String suppliedCode, String gameName) {
  final text = '$suppliedCode $gameName'.toLowerCase().replaceAll(
    RegExp(r'[^a-z0-9]'),
    '',
  );
  if (text.contains('powerball')) {
    return 'powerball';
  }
  if (text.contains('megamillions')) {
    return 'mega-millions';
  }
  if (text.contains('scratch') || text.contains('instant')) {
    return 'scratch-off';
  }
  return 'state-draw';
}

String _slug(String value) => value
    .toLowerCase()
    .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
    .replaceAll(RegExp(r'(^-|-$)'), '');

Future<void> main(List<String> arguments) async {
  try {
    final options = _arguments(arguments);
    final state = options['state']!.toUpperCase();
    final rows = _parseCsv(await File(options['input']!).readAsString());
    if (rows.length < 2) {
      _fail('The CSV must contain a header row and at least one data row.');
    }

    final mapping = _columnMap(rows.first);
    final activities = <Map<String, Object?>>[];
    final errors = <String>[];
    final ids = <String>{};

    for (var index = 1; index < rows.length; index += 1) {
      final row = rows[index];
      final rowNumber = index + 1;
      final rowErrors = <String>[];
      final drawDate = _valueAt(row, mapping, 'drawdate');
      final gameName = _valueAt(row, mapping, 'gamename');
      final prizeAmount = _money(_valueAt(row, mapping, 'prizeamount'));
      final retailerName = _valueAt(row, mapping, 'retailername');
      final retailerAddress = _valueAt(row, mapping, 'retaileraddress');
      final city = _valueAt(row, mapping, 'city');
      final rawCounty = _valueAt(row, mapping, 'county');
      final latitude = double.tryParse(_valueAt(row, mapping, 'latitude'));
      final longitude = double.tryParse(_valueAt(row, mapping, 'longitude'));
      final winningTickets = _tickets(_valueAt(row, mapping, 'winningtickets'));
      final parsedDate = DateTime.tryParse(drawDate);

      if (parsedDate == null) rowErrors.add('draw_date is not a valid date');
      if (gameName.isEmpty) rowErrors.add('game_name is required');
      if (prizeAmount == null || prizeAmount < 0) {
        rowErrors.add(
          'prize_amount must be a whole non-negative dollar amount',
        );
      }
      if (<String>[
        retailerName,
        retailerAddress,
        city,
        rawCounty,
      ].any((value) => value.isEmpty)) {
        rowErrors.add(
          'retailer_name, retailer_address, city, and county are all required',
        );
      }
      if (latitude == null ||
          latitude < -90 ||
          latitude > 90 ||
          longitude == null ||
          longitude < -180 ||
          longitude > 180) {
        rowErrors.add('latitude and longitude must be valid exact coordinates');
      }
      if (winningTickets == null || winningTickets < 0) {
        rowErrors.add('winning_tickets must be a whole non-negative number');
      }
      if (rowErrors.isNotEmpty) {
        errors.add('Row $rowNumber: ${rowErrors.join('; ')}.');
        continue;
      }

      final sourceUrl = _valueAt(row, mapping, 'sourceurl').isEmpty
          ? options['source-url']!
          : _valueAt(row, mapping, 'sourceurl');
      if (!_isUrl(sourceUrl)) {
        errors.add('Row $rowNumber: source_url must be a complete URL.');
        continue;
      }
      final id =
          '${state.toLowerCase()}-${_slug(drawDate.substring(0, 10))}-${_slug(gameName)}-${_slug(retailerName)}-$index';
      if (!ids.add(id)) {
        errors.add('Row $rowNumber: duplicates another imported record.');
        continue;
      }
      final county = rawCounty.toLowerCase().endsWith('county')
          ? rawCounty
          : '$rawCounty County';
      activities.add(<String, Object?>{
        'id': id,
        'latitude': latitude,
        'longitude': longitude,
        'city': city,
        'county': county,
        'state': state,
        'game': _gameCode(_valueAt(row, mapping, 'gamecode'), gameName),
        'gameName': gameName,
        'drawDate': parsedDate!.toUtc().toIso8601String(),
        'winningTickets': winningTickets,
        'prizeAmount': prizeAmount,
        'retailerName': retailerName,
        'retailerAddress': retailerAddress,
        'sourceUrl': sourceUrl,
        'sourceLabel': _valueAt(row, mapping, 'sourcelabel').isEmpty
            ? options['source-label']
            : _valueAt(row, mapping, 'sourcelabel'),
        'isHistorical': true,
      });
    }

    if (errors.isNotEmpty) {
      stderr.writeln(
        'Import stopped. ${errors.length} issue(s) need correction:\n${errors.join('\n')}',
      );
      exitCode = 1;
      return;
    }

    activities.sort(
      (left, right) =>
          (left['drawDate']! as String).compareTo(right['drawDate']! as String),
    );
    final output = <String, Object?>{
      'source': options['source-label'],
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
      'coverage':
          'Authorized $state lottery retailer-winner export. ${activities.length} location-complete records were validated before import.',
      'activities': activities,
    };
    await File(
      options['output']!,
    ).writeAsString('${const JsonEncoder.withIndent('  ').convert(output)}\n');
    stdout.writeln(
      'Validated and wrote ${activities.length} $state retailer-winner records to ${options['output']}.',
    );
  } on FormatException catch (error) {
    stderr.writeln('Import stopped: ${error.message}');
    exitCode = 1;
  } on FileSystemException catch (error) {
    stderr.writeln('Import stopped: ${error.message}');
    exitCode = 1;
  }
}
