// Imports the South Carolina Education Lottery's official daily Winners Report.
// The report names the game, prize, retailer, address, city, and county for
// claimed prizes of $500 and above. A record becomes a heat-map point only
// after its official retailer address receives an exact U.S. Census geocode.
import 'dart:convert';
import 'dart:io';

const _reportUrl = 'https://www.sceducationlottery.com/Games/WinnersReport';
const _censusBatchUrl =
    'https://geocoding.geo.census.gov/geocoder/locations/addressbatch';
const _sourceLabel = 'Official South Carolina Education Lottery Winners Report';
const _maxCensusBatchSize = 9000;

Never _fail(String message) => throw FormatException(message);

Map<String, String> _arguments(List<String> arguments) {
  final values = <String, String>{};
  for (var index = 0; index < arguments.length; index += 1) {
    final argument = arguments[index];
    if (argument == '--help' || argument == '-h') {
      stdout.writeln(
        'Usage: dart run tooling/import_south_carolina_winners_report.dart '
        '--output FILE.json',
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
  if ((values['output'] ?? '').trim().isEmpty) {
    _fail('Missing required --output.');
  }
  return values;
}

String _stripHtml(String value) => htmlUnescape(
  value
      .replaceAll(RegExp(r'<[^>]+>', multiLine: true), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim(),
);

String htmlUnescape(String value) => value
    .replaceAll('&amp;', '&')
    .replaceAll('&nbsp;', ' ')
    .replaceAll('&#39;', "'")
    .replaceAll('&quot;', '"')
    .replaceAll('&lt;', '<')
    .replaceAll('&gt;', '>');

String _keyPart(String value) => value
    .toLowerCase()
    .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

String _locationKey(String address, String city) =>
    '${_keyPart(address)}|${_keyPart(city)}|sc';

String _csv(String value) => '"${value.replaceAll('"', '""')}"';

List<List<String>> _csvRows(String value) {
  final rows = <List<String>>[];
  var row = <String>[];
  var field = StringBuffer();
  var quoted = false;
  for (var index = 0; index < value.length; index += 1) {
    final char = value[index];
    if (char == '"') {
      if (quoted && index + 1 < value.length && value[index + 1] == '"') {
        field.write('"');
        index += 1;
      } else {
        quoted = !quoted;
      }
    } else if (char == ',' && !quoted) {
      row.add(field.toString());
      field = StringBuffer();
    } else if ((char == '\n' || char == '\r') && !quoted) {
      if (char == '\r' &&
          index + 1 < value.length &&
          value[index + 1] == '\n') {
        index += 1;
      }
      row.add(field.toString());
      field = StringBuffer();
      if (row.any((item) => item.isNotEmpty)) rows.add(row);
      row = <String>[];
    } else {
      field.write(char);
    }
  }
  if (field.isNotEmpty || row.isNotEmpty) {
    row.add(field.toString());
    if (row.any((item) => item.isNotEmpty)) rows.add(row);
  }
  return rows;
}

DateTime _claimDate(String value) {
  final match = RegExp(r'^(\d{2})/(\d{2})/(\d{4})$').firstMatch(value);
  if (match == null) _fail('Unexpected SC claim date: $value');
  return DateTime.utc(
    int.parse(match.group(3)!),
    int.parse(match.group(1)!),
    int.parse(match.group(2)!),
    12,
  );
}

num _amount(String value) {
  final amount = num.tryParse(value.replaceAll(RegExp(r'[^0-9.]'), ''));
  if (amount == null) _fail('Unexpected SC prize amount: $value');
  return amount;
}

String _gameType(String gameName) {
  final normalized = _keyPart(gameName);
  if (normalized == 'powerball') return 'powerball';
  if (normalized == 'mega millions') return 'mega-millions';
  if (<String>{
    'pick 3',
    'pick 4',
    'palmetto cash 5',
    'cash pop',
  }.contains(normalized)) {
    return 'state-draw';
  }
  return 'scratch-off';
}

class _Claim {
  const _Claim({
    required this.date,
    required this.prize,
    required this.gameName,
    required this.county,
    required this.retailerName,
    required this.address,
    required this.city,
    required this.winningTickets,
  });

  final DateTime date;
  final num prize;
  final String gameName;
  final String county;
  final String retailerName;
  final String address;
  final String city;
  final int winningTickets;

  String get locationKey => _locationKey(address, city);
  String get groupKey => <String>[
    date.toIso8601String(),
    prize.toString(),
    _keyPart(gameName),
    _keyPart(county),
    _keyPart(retailerName),
    _keyPart(address),
    _keyPart(city),
  ].join('|');
}

List<_Claim> _parseClaims(String page) {
  final body = RegExp(
    r'<tbody>(.*?)</tbody>',
    caseSensitive: false,
    dotAll: true,
  ).firstMatch(page)?.group(1);
  if (body == null) _fail('The SC Winners Report table was not found.');
  final grouped = <String, _Claim>{};
  final rows = RegExp(
    r'<tr\b[^>]*>(.*?)</tr>',
    caseSensitive: false,
    dotAll: true,
  ).allMatches(body);
  for (final row in rows) {
    final cells =
        RegExp(r'<td\b[^>]*>(.*?)</td>', caseSensitive: false, dotAll: true)
            .allMatches(row.group(1)!)
            .map((match) => _stripHtml(match.group(1)!))
            .toList(growable: false);
    if (cells.length != 7 || cells.any((cell) => cell.isEmpty)) continue;
    final claim = _Claim(
      date: _claimDate(cells[0]),
      prize: _amount(cells[1]),
      gameName: cells[2],
      county: cells[3]
          .split(RegExp(r'\s+'))
          .map(
            (word) => word.isEmpty
                ? word
                : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
          )
          .join(' '),
      retailerName: cells[4],
      address: cells[5],
      city: cells[6],
      winningTickets: 1,
    );
    final existing = grouped[claim.groupKey];
    grouped[claim.groupKey] = existing == null
        ? claim
        : _Claim(
            date: claim.date,
            prize: claim.prize,
            gameName: claim.gameName,
            county: claim.county,
            retailerName: claim.retailerName,
            address: claim.address,
            city: claim.city,
            winningTickets: existing.winningTickets + 1,
          );
  }
  if (grouped.isEmpty) {
    _fail('The SC Winners Report did not contain usable claims.');
  }
  final claims = grouped.values.toList()
    ..sort((left, right) => left.groupKey.compareTo(right.groupKey));
  return claims;
}

Map<String, Map<String, double>> _cachedCoordinates(
  Map<String, dynamic>? root,
) {
  final cache = <String, Map<String, double>>{};
  final rawCache = root?['geocodeCache'];
  if (rawCache is Map) {
    rawCache.forEach((key, value) {
      if (value is! Map) return;
      final latitude = (value['latitude'] as num?)?.toDouble();
      final longitude = (value['longitude'] as num?)?.toDouble();
      if (latitude != null && longitude != null) {
        cache[key.toString()] = <String, double>{
          'latitude': latitude,
          'longitude': longitude,
        };
      }
    });
  }
  return cache;
}

Future<Map<String, Map<String, double>>> _geocodeBatch(
  List<_Claim> claims,
) async {
  final byLocation = <String, _Claim>{
    for (final claim in claims) claim.locationKey: claim,
  };
  final results = <String, Map<String, double>>{};
  final locations = byLocation.entries.toList()
    ..sort((left, right) => left.key.compareTo(right.key));
  for (
    var offset = 0;
    offset < locations.length;
    offset += _maxCensusBatchSize
  ) {
    final batch = locations.sublist(
      offset,
      (offset + _maxCensusBatchSize).clamp(0, locations.length),
    );
    final csv = StringBuffer();
    for (var index = 0; index < batch.length; index += 1) {
      final claim = batch[index].value;
      csv.writeln(
        <String>[
          _csv(index.toString()),
          _csv(claim.address),
          _csv(claim.city),
          _csv('SC'),
          _csv(''),
        ].join(','),
      );
    }
    final boundary =
        '----LotteryAtlasCensus${DateTime.now().microsecondsSinceEpoch}';
    final client = HttpClient();
    try {
      final request = await client.postUrl(Uri.parse(_censusBatchUrl));
      request.headers.contentType = ContentType(
        'multipart',
        'form-data',
        parameters: <String, String>{'boundary': boundary},
      );
      void field(String name, String value) {
        request.write('--$boundary\r\n');
        request.write('Content-Disposition: form-data; name="$name"\r\n\r\n');
        request.write('$value\r\n');
      }

      field('benchmark', 'Public_AR_Current');
      request.write('--$boundary\r\n');
      request.write(
        'Content-Disposition: form-data; name="addressFile"; filename="sc-winners.csv"\r\n',
      );
      request.write('Content-Type: text/csv\r\n\r\n');
      request.write(csv.toString());
      request.write('\r\n--$boundary--\r\n');
      final response = await request.close();
      final responseBody = await utf8.decoder.bind(response).join();
      if (response.statusCode != HttpStatus.ok) {
        _fail('Census batch geocoder returned HTTP ${response.statusCode}.');
      }
      for (final row in _csvRows(responseBody)) {
        if (row.length < 6 || row[2] != 'Match' || row[5].isEmpty) continue;
        final rowIndex = int.tryParse(row[0]);
        final pair = row[5].split(',');
        if (rowIndex == null ||
            rowIndex < 0 ||
            rowIndex >= batch.length ||
            pair.length != 2) {
          continue;
        }
        final longitude = double.tryParse(pair[0]);
        final latitude = double.tryParse(pair[1]);
        if (latitude == null || longitude == null) continue;
        results[batch[rowIndex].key] = <String, double>{
          'latitude': latitude,
          'longitude': longitude,
        };
      }
    } finally {
      client.close(force: true);
    }
  }
  return results;
}

Future<String> _fetchReport() async {
  final client = HttpClient();
  try {
    final request = await client.getUrl(Uri.parse(_reportUrl));
    request.headers.set(
      HttpHeaders.userAgentHeader,
      'LotteryAtlasOfficialDataBot/1.0',
    );
    final response = await request.close();
    final body = await utf8.decoder.bind(response).join();
    if (response.statusCode != HttpStatus.ok) {
      _fail('SC Winners Report returned HTTP ${response.statusCode}.');
    }
    return body;
  } finally {
    client.close(force: true);
  }
}

Future<Map<String, dynamic>?> _readExisting(File file) async {
  if (!await file.exists()) return null;
  final decoded = jsonDecode(await file.readAsString());
  return decoded is Map ? Map<String, dynamic>.from(decoded) : null;
}

Future<void> main(List<String> arguments) async {
  try {
    final options = _arguments(arguments);
    final output = File(options['output']!);
    final existing = await _readExisting(output);
    final report = await _fetchReport();
    final claims = _parseClaims(report);
    final coordinates = _cachedCoordinates(existing);
    final unknown = claims
        .where((claim) => !coordinates.containsKey(claim.locationKey))
        .toList();
    if (unknown.isNotEmpty) coordinates.addAll(await _geocodeBatch(unknown));
    final dateText = RegExp(
      r'Last Update on\s*<strong[^>]*>\s*(\d{2}/\d{2}/\d{4})',
      caseSensitive: false,
    ).firstMatch(report)?.group(1);
    final sourceDate = dateText == null ? null : _claimDate(dateText);
    final activities = <Map<String, Object>>[];
    var skipped = 0;
    for (var index = 0; index < claims.length; index += 1) {
      final claim = claims[index];
      final coordinate = coordinates[claim.locationKey];
      if (coordinate == null) {
        skipped += claim.winningTickets;
        continue;
      }
      activities.add(<String, Object>{
        'id':
            'sc-winners-${claim.date.toIso8601String().substring(0, 10)}-${index + 1}',
        'latitude': coordinate['latitude']!,
        'longitude': coordinate['longitude']!,
        'city': claim.city,
        'county': claim.county,
        'state': 'SC',
        'game': _gameType(claim.gameName),
        'gameName': claim.gameName,
        'retailerName': claim.retailerName,
        'retailerAddress': claim.address,
        'drawDate': claim.date.toIso8601String(),
        'winningTickets': claim.winningTickets,
        'prizeAmount': claim.prize,
        'sourceUrl': _reportUrl,
        'sourceLabel': _sourceLabel,
      });
    }
    if (activities.isEmpty) _fail('No SC claims could be exactly geocoded.');
    final sortedCoordinates = coordinates.keys.toList()..sort();
    final geocodeCache = <String, Object>{
      for (final key in sortedCoordinates) key: coordinates[key]!,
    };
    final rendered = <String, Object>{
      'source': _sourceLabel,
      'updatedAt': (sourceDate ?? DateTime.now().toUtc()).toIso8601String(),
      if (sourceDate != null) 'sourceLastUpdated': sourceDate.toIso8601String(),
      'coverage':
          'Current claimed SC Lottery prizes of \$500 and above from the official Winners Report. '
          '${activities.length} mapped claim groups are included; $skipped claims were excluded because their official retailer address did not receive an exact U.S. Census geocode.',
      'geocodeCache': geocodeCache,
      'activities': activities,
    };
    const encoder = JsonEncoder.withIndent('  ');
    final next = '${encoder.convert(rendered)}\n';
    final current = await output.exists() ? await output.readAsString() : null;
    if (current != next) {
      await output.parent.create(recursive: true);
      await output.writeAsString(next);
    }
    stdout.writeln(
      'Imported ${activities.length} SC claim groups from ${claims.length} report groups; '
      '${coordinates.length} retailer locations have exact Census coordinates; $skipped claims were skipped.',
    );
  } on FormatException catch (error) {
    stderr.writeln('SC Winners Report import stopped: ${error.message}');
    exitCode = 1;
  } on SocketException catch (error) {
    stderr.writeln('SC Winners Report import stopped: ${error.message}');
    exitCode = 1;
  } on HttpException catch (error) {
    stderr.writeln('SC Winners Report import stopped: ${error.message}');
    exitCode = 1;
  }
}
