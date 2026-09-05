// Converts an official state-lottery Scratch-Off catalog export into the
// portable catalog-feed format used by Lottery Atlas. It never fetches,
// scrapes, or guesses game details. Use only a CSV downloaded from the state
// lottery's official current-ticket catalog or a validated official report.
//
// Example:
// dart tooling/import_state_scratch_catalog.dart \
//   --input /path/to/arizona-official-scratch-catalog.csv \
//   --output data/arizona_scratch_catalog.json \
//   --state "Arizona" \
//   --source-url https://www.arizonalottery.com/scratchers/
//
// Required CSV columns (case/punctuation insensitive): game number, game
// name, price, top prize. Optional: top prizes remaining, top prize label.

import 'dart:convert';
import 'dart:io';

const _requiredColumns = <String>['id', 'name', 'cost', 'topprize'];

const _aliases = <String, List<String>>{
  'id': <String>['id', 'gamenumber', 'gamenum', 'gamenumberid', 'gameid'],
  'name': <String>['name', 'gamename', 'title'],
  'cost': <String>['cost', 'price', 'ticketprice'],
  'topprize': <String>['topprize', 'topcashprize', 'highestprize'],
  'topprizelabel': <String>['topprizelabel', 'topprizedescription'],
  'topprizesremaining': <String>[
    'topprizesremaining',
    'topprizeremaining',
    'remainingtopprizes',
  ],
};

Never _fail(String message) => throw FormatException(message);

void _usage() {
  stdout.writeln('''
Usage:
  dart tooling/import_state_scratch_catalog.dart --input FILE.csv --output FILE.json --state "State Name" --source-url URL

Each row must come from an official current Scratch-Off catalog. The importer
stops when a required ticket field is missing rather than publishing an
incomplete catalog to the app.
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
  for (final key in <String>['input', 'output', 'state', 'source-url']) {
    if (values[key] == null || values[key]!.trim().isEmpty) {
      _fail('Missing required --$key.');
    }
  }
  final uri = Uri.tryParse(values['source-url']!);
  if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
    _fail('--source-url must be a complete official source URL.');
  }
  return values;
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
  if (quoted) _fail('The CSV has an unclosed quoted value.');
  row.add(cell.toString().trim());
  if (row.any((value) => value.isNotEmpty)) rows.add(row);
  return rows;
}

Map<String, int> _columnMap(List<String> headers) {
  final normalized = headers.map(_normaliseHeader).toList(growable: false);
  final mapping = <String, int>{};
  for (final entry in _aliases.entries) {
    final index = normalized.indexWhere(entry.value.contains);
    if (index >= 0) mapping[entry.key] = index;
  }
  final missing = _requiredColumns
      .where((column) => !mapping.containsKey(column))
      .toList(growable: false);
  if (missing.isNotEmpty) {
    _fail('Missing required CSV columns: ${missing.join(', ')}.');
  }
  return mapping;
}

String _valueAt(List<String> row, Map<String, int> mapping, String field) {
  final index = mapping[field];
  return index == null || index >= row.length ? '' : row[index].trim();
}

int? _wholeDollar(String value) {
  final normalized = value.replaceAll(RegExp(r'[$,\s]'), '');
  return int.tryParse(normalized);
}

Future<void> main(List<String> arguments) async {
  try {
    final options = _arguments(arguments);
    final stateName = options['state']!.trim();
    final rows = _parseCsv(await File(options['input']!).readAsString());
    if (rows.length < 2) {
      _fail('The CSV needs a header row and at least one ticket.');
    }
    final columns = _columnMap(rows.first);
    final games = <Map<String, Object?>>[];
    final errors = <String>[];
    final ids = <String>{};

    for (var index = 1; index < rows.length; index += 1) {
      final row = rows[index];
      final id = _valueAt(row, columns, 'id');
      final name = _valueAt(row, columns, 'name');
      final cost = _wholeDollar(_valueAt(row, columns, 'cost'));
      final topPrize = _wholeDollar(_valueAt(row, columns, 'topprize'));
      final remaining = _wholeDollar(
        _valueAt(row, columns, 'topprizesremaining'),
      );
      final topPrizeLabel = _valueAt(row, columns, 'topprizelabel');
      final rowErrors = <String>[];
      if (id.isEmpty) rowErrors.add('game number is required');
      if (name.isEmpty) rowErrors.add('game name is required');
      if (cost == null || cost <= 0) rowErrors.add('price must be positive');
      if (topPrize == null || topPrize < 0) {
        rowErrors.add('top prize must be a non-negative whole dollar amount');
      }
      if (remaining != null && remaining < 0) {
        rowErrors.add('remaining top prizes cannot be negative');
      }
      if (!ids.add(id)) rowErrors.add('duplicate game number');
      if (rowErrors.isNotEmpty) {
        errors.add('Row ${index + 1}: ${rowErrors.join('; ')}.');
        continue;
      }
      games.add(<String, Object?>{
        'stateName': stateName,
        'id': id,
        'name': name,
        'cost': cost,
        'topPrize': topPrize,
        if (topPrizeLabel.isNotEmpty) 'topPrizeLabel': topPrizeLabel,
        'topPrizesRemaining': ?remaining,
      });
    }
    if (errors.isNotEmpty) _fail(errors.join('\n'));
    if (games.isEmpty) _fail('No valid tickets were found.');

    final output = <String, Object?>{
      'source': 'Official $stateName Lottery Scratch-Off catalog',
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
      'catalogs': <Object?>[
        <String, Object?>{
          'state': stateName,
          'source': options['source-url'],
          'games': games,
        },
      ],
    };
    await File(
      options['output']!,
    ).writeAsString(const JsonEncoder.withIndent('  ').convert(output));
    stdout.writeln(
      'Imported ${games.length} verified $stateName Scratch-Off tickets.',
    );
  } on FormatException catch (error) {
    stderr.writeln('Import stopped: ${error.message}');
    exitCode = 64;
  }
}
