// Builds the public activity feed from reviewed, official-source snapshots.
//
// This is deliberately a validator and publisher, not a scraper. A lottery
// source adapter must write a reviewed snapshot before this tool will publish
// it. Invalid, incomplete, or location-less records fail the run instead of
// becoming misleading heat-map points.
//
// Example:
// dart run tooling/publish_activity_feed.dart \
//   --sources tooling/approved_activity_sources.json \
//   --output docs/activity.json
import 'dart:convert';
import 'dart:io';

Never _fail(String message) => throw FormatException(message);

Map<String, String> _arguments(List<String> arguments) {
  final values = <String, String>{};
  for (var index = 0; index < arguments.length; index += 1) {
    final argument = arguments[index];
    if (argument == '--help' || argument == '-h') {
      stdout.writeln(
        'Usage: dart run tooling/publish_activity_feed.dart '
        '--sources FILE.json --output FILE.json',
      );
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
  for (final key in <String>['sources', 'output']) {
    if (values[key] == null || values[key]!.trim().isEmpty) {
      _fail('Missing required --$key.');
    }
  }
  return values;
}

DateTime _date(Object? value, String field, String context) {
  final parsed = DateTime.tryParse(value?.toString() ?? '');
  if (parsed == null) _fail('$context has an invalid $field value.');
  return parsed.toUtc();
}

String _text(Map<String, dynamic> record, String field, String context) {
  final value = record[field]?.toString().trim() ?? '';
  if (value.isEmpty) _fail('$context is missing $field.');
  return value;
}

num _number(Map<String, dynamic> record, String field, String context) {
  final value = record[field];
  final number = value is num ? value : num.tryParse(value?.toString() ?? '');
  if (number == null) _fail('$context has an invalid $field.');
  return number;
}

void _validateRecord(Map<String, dynamic> record, String context) {
  final id = _text(record, 'id', context);
  if (!RegExp(r'^[A-Za-z0-9][A-Za-z0-9._-]*$').hasMatch(id)) {
    _fail('$context has an unsafe id: $id.');
  }
  _text(record, 'city', context);
  _text(record, 'county', context);
  _text(record, 'gameName', context);
  _text(record, 'retailerName', context);
  _text(record, 'retailerAddress', context);
  _text(record, 'sourceLabel', context);
  final state = _text(record, 'state', context).toUpperCase();
  if (!RegExp(r'^[A-Z]{2}$').hasMatch(state)) {
    _fail('$context has an invalid state code.');
  }
  final game = _text(record, 'game', context).toLowerCase();
  if (!const <String>{
    'powerball',
    'mega-millions',
    'scratch-off',
    'state-draw',
  }.contains(game)) {
    _fail('$context has an unknown game code: $game.');
  }
  final latitude = _number(record, 'latitude', context).toDouble();
  final longitude = _number(record, 'longitude', context).toDouble();
  if (latitude < -90 || latitude > 90 || longitude < -180 || longitude > 180) {
    _fail('$context has coordinates outside the valid world range.');
  }
  if (_number(record, 'winningTickets', context) <= 0) {
    _fail('$context must have at least one winning ticket.');
  }
  if (_number(record, 'prizeAmount', context) < 0) {
    _fail('$context has a negative prize amount.');
  }
  _date(record['drawDate'], 'drawDate', context);
  final sourceUrl = Uri.tryParse(_text(record, 'sourceUrl', context));
  if (sourceUrl == null || !sourceUrl.hasScheme || sourceUrl.host.isEmpty) {
    _fail('$context has an invalid sourceUrl.');
  }
}

Future<void> main(List<String> arguments) async {
  try {
    final options = _arguments(arguments);
    final sourceList = jsonDecode(
      await File(options['sources']!).readAsString(),
    );
    if (sourceList is! Map || sourceList['feeds'] is! List) {
      _fail('The approved source list needs a feeds array.');
    }

    final sourceFiles = List<Object?>.from(sourceList['feeds'] as List)
        .map((value) => value.toString().trim())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
    if (sourceFiles.isEmpty) _fail('The approved source list is empty.');

    final records = <String, Map<String, dynamic>>{};
    final feedDates = <DateTime>[];
    final sourceDates = <DateTime>[];
    final stateCodes = <String>{};

    for (final sourcePath in sourceFiles) {
      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) {
        _fail('Approved source file not found: $sourcePath');
      }
      final decoded = jsonDecode(await sourceFile.readAsString());
      if (decoded is! Map) _fail('$sourcePath is not a JSON object.');
      final root = Map<String, dynamic>.from(decoded);
      _text(root, 'source', sourcePath);
      feedDates.add(_date(root['updatedAt'], 'updatedAt', sourcePath));
      final rawSourceDate = root['sourceLastUpdated']?.toString().trim() ?? '';
      if (rawSourceDate.isNotEmpty) {
        sourceDates.add(_date(rawSourceDate, 'sourceLastUpdated', sourcePath));
      }

      final groups = <Object?>[
        root['activities'],
        root['historicalActivities'],
      ];
      var count = 0;
      for (final group in groups) {
        if (group == null) continue;
        if (group is! List) _fail('$sourcePath has a non-list activity group.');
        for (final item in group) {
          if (item is! Map) _fail('$sourcePath contains a non-object record.');
          final record = Map<String, dynamic>.from(item);
          final context = '$sourcePath record ${record['id'] ?? '<unknown>'}';
          _validateRecord(record, context);
          final id = record['id']!.toString();
          final existing = records[id];
          if (existing != null && jsonEncode(existing) != jsonEncode(record)) {
            _fail(
              'Conflicting activity id $id appears in more than one source.',
            );
          }
          records[id] = record;
          stateCodes.add(record['state']!.toString().toUpperCase());
          count += 1;
        }
      }
      if (count == 0) _fail('$sourcePath has no activity records.');
    }

    final activities = records.values.toList()
      ..sort((left, right) {
        final stateOrder = left['state'].toString().compareTo(
          right['state'].toString(),
        );
        if (stateOrder != 0) return stateOrder;
        final dateOrder = left['drawDate'].toString().compareTo(
          right['drawDate'].toString(),
        );
        if (dateOrder != 0) return dateOrder;
        return left['id'].toString().compareTo(right['id'].toString());
      });
    feedDates.sort();
    sourceDates.sort();

    final published = <String, Object>{
      'source': 'Lottery Atlas verified official activity feed',
      // This is the newest source snapshot timestamp, not the workflow run
      // time, so the app never claims a stale source was freshly updated.
      'updatedAt': feedDates.last.toIso8601String(),
      if (sourceDates.isNotEmpty)
        'sourceLastUpdated': sourceDates.last.toIso8601String(),
      'coverage':
          'Merged verified official state snapshots for ${stateCodes.length} states. '
          'Every published heat-map record identifies a named retailer or official '
          'winning location, has supplied coordinates, and links to an official source. '
          'Coverage varies by state and game.',
      'activities': activities,
    };

    final outputFile = File(options['output']!);
    await outputFile.parent.create(recursive: true);
    const encoder = JsonEncoder.withIndent('  ');
    final rendered = '${encoder.convert(published)}\n';
    final current = await outputFile.exists()
        ? await outputFile.readAsString()
        : null;
    if (current != rendered) await outputFile.writeAsString(rendered);
    stdout.writeln(
      'Validated ${activities.length} verified heat-map records across '
      '${stateCodes.length} states and wrote ${outputFile.path}.',
    );
  } on FormatException catch (error) {
    stderr.writeln('Activity publication stopped: ${error.message}');
    exitCode = 1;
  } on FileSystemException catch (error) {
    stderr.writeln('Activity publication stopped: ${error.message}');
    exitCode = 1;
  } on JsonUnsupportedObjectError catch (error) {
    stderr.writeln('Activity publication stopped: ${error.cause}');
    exitCode = 1;
  }
}
