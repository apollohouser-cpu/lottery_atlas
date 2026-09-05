import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/saved_lottery_ticket.dart';

/// Stores saved number sets locally on the current device.
///
/// Every save is written and then read back before the UI reports success, so
/// the Saved Tickets screen sees the same data.
class SavedTicketService {
  SavedTicketService._();

  static const _storageKey = 'lottery_atlas.saved_lottery_tickets';
  static Future<SharedPreferences>? _preferencesFuture;

  static Future<SharedPreferences> _preferences() =>
      _preferencesFuture ??= SharedPreferences.getInstance();

  static Future<List<SavedLotteryTicket>> load() async {
    final preferences = await _preferences();
    return _decode(preferences.getString(_storageKey));
  }

  /// Saves a number set and verifies it reached device storage.
  static Future<SavedLotteryTicket> save({
    required String gameCode,
    required List<String> whiteNumbers,
    required String specialNumber,
    String? label,
  }) async {
    final preferences = await _preferences();
    final tickets = _decode(preferences.getString(_storageKey));
    final normalizedWhiteNumbers = whiteNumbers
        .map((number) => int.parse(number).toString())
        .toList();
    final normalizedSpecialNumber = int.parse(specialNumber).toString();
    final normalizedLabel = label?.trim();
    final now = DateTime.now();
    final savedTicket = SavedLotteryTicket(
      id: now.microsecondsSinceEpoch.toString(),
      gameCode: gameCode,
      whiteNumbers: normalizedWhiteNumbers,
      specialNumber: normalizedSpecialNumber,
      savedAt: now,
      label: normalizedLabel == null || normalizedLabel.isEmpty
          ? null
          : normalizedLabel,
    );

    tickets.removeWhere(
      (ticket) =>
          ticket.gameCode == gameCode &&
          ticket.whiteNumbers.join(',') == normalizedWhiteNumbers.join(',') &&
          ticket.specialNumber == normalizedSpecialNumber,
    );
    tickets.insert(0, savedTicket);

    final trimmedTickets = tickets.take(50).toList();
    final wasWritten = await preferences.setString(
      _storageKey,
      jsonEncode(trimmedTickets.map((ticket) => ticket.toJson()).toList()),
    );
    if (!wasWritten) {
      throw StateError('Your number set could not be saved on this device.');
    }

    final verifiedTickets = _decode(preferences.getString(_storageKey));
    if (!verifiedTickets.any((ticket) => ticket.id == savedTicket.id)) {
      throw StateError('Your saved number set could not be verified.');
    }
    return savedTicket;
  }

  static Future<void> rename(String id, String? label) async {
    final preferences = await _preferences();
    final tickets = _decode(preferences.getString(_storageKey));
    final normalizedLabel = label?.trim();
    final ticketIndex = tickets.indexWhere((ticket) => ticket.id == id);
    if (ticketIndex == -1) {
      throw StateError('The saved number set could not be found.');
    }

    tickets[ticketIndex] = tickets[ticketIndex].copyWith(
      label: normalizedLabel == null || normalizedLabel.isEmpty
          ? null
          : normalizedLabel,
    );
    final wasWritten = await preferences.setString(
      _storageKey,
      jsonEncode(tickets.map((ticket) => ticket.toJson()).toList()),
    );
    if (!wasWritten) {
      throw StateError('The saved number set could not be renamed.');
    }
  }

  static Future<void> delete(String id) async {
    final preferences = await _preferences();
    final tickets = _decode(preferences.getString(_storageKey));
    tickets.removeWhere((ticket) => ticket.id == id);
    final wasWritten = await preferences.setString(
      _storageKey,
      jsonEncode(tickets.map((ticket) => ticket.toJson()).toList()),
    );
    if (!wasWritten) {
      throw StateError('The saved number set could not be removed.');
    }
  }

  static List<SavedLotteryTicket> _decode(String? raw) {
    if (raw == null || raw.isEmpty) return <SavedLotteryTicket>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List<dynamic>) return <SavedLotteryTicket>[];

      final tickets = <SavedLotteryTicket>[];
      for (final item in decoded) {
        if (item is! Map) continue;
        final ticket = SavedLotteryTicket.fromJson(
          Map<String, dynamic>.from(item),
        );
        if (ticket.id.isNotEmpty && ticket.whiteNumbers.length == 5) {
          tickets.add(ticket);
        }
      }
      tickets.sort((a, b) => b.savedAt.compareTo(a.savedAt));
      return tickets;
    } catch (_) {
      return <SavedLotteryTicket>[];
    }
  }
}
