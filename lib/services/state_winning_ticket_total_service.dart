import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../models/state_winning_ticket_total.dart';

/// State-level official counts, kept separate from geolocated winner records.
class StateWinningTicketTotalService {
  StateWinningTicketTotalService._();

  static const _asset = 'data/state_winning_ticket_totals.json';
  static const _url = String.fromEnvironment(
    'LOTTERY_STATE_TOTALS_FEED_URL',
    defaultValue:
        'https://apollohouser-cpu.github.io/lottery_atlas/state_winning_ticket_totals.json',
  );
  static final ValueNotifier<List<StateWinningTicketTotal>> totals =
      ValueNotifier<List<StateWinningTicketTotal>>(const []);

  static List<StateWinningTicketTotal> parse(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! Map || decoded['totals'] is! List) {
      throw const FormatException('Expected a totals list');
    }
    final parsed = <StateWinningTicketTotal>[];
    for (final item in decoded['totals'] as List) {
      final total = StateWinningTicketTotal.fromJson(item);
      if (total == null) throw const FormatException('Invalid state total');
      parsed.add(total);
    }
    final states = parsed.map((total) => total.state).toSet();
    if (states.length != parsed.length) {
      throw const FormatException('Duplicate state total');
    }
    return List.unmodifiable(parsed);
  }

  static Future<void> refresh({http.Client? client}) async {
    List<StateWinningTicketTotal> next;
    try {
      next = parse(await rootBundle.loadString(_asset));
    } catch (_) {
      next = const [];
    }
    if (_url.isNotEmpty) {
      final activeClient = client ?? http.Client();
      try {
        final response = await activeClient
            .get(Uri.parse(_url), headers: const {'accept': 'application/json'})
            .timeout(const Duration(seconds: 12));
        if (response.statusCode == 200) next = parse(response.body);
      } catch (_) {
        // Keep the last verified bundled or downloaded snapshot.
        if (totals.value.isNotEmpty) next = totals.value;
      } finally {
        if (client == null) activeClient.close();
      }
    }
    totals.value = next;
  }
}
