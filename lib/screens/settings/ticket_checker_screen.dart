import 'package:flutter/material.dart';

import '../../models/saved_lottery_ticket.dart';
import '../../services/musl_draw_service.dart';
import '../../services/saved_ticket_service.dart';
import 'saved_tickets_screen.dart';

class TicketCheckerScreen extends StatefulWidget {
  const TicketCheckerScreen({super.key, this.initialTicket});

  final SavedLotteryTicket? initialTicket;

  @override
  State<TicketCheckerScreen> createState() => _TicketCheckerScreenState();
}

class _TicketCheckerScreenState extends State<TicketCheckerScreen> {
  final MuslDrawService _service = MuslDrawService();
  final TextEditingController _numbersController = TextEditingController();
  final TextEditingController _specialController = TextEditingController();

  String _gameCode = 'powerball';
  bool _isChecking = false;
  String? _inputError;
  _TicketCheck? _check;

  @override
  void initState() {
    super.initState();
    final ticket = widget.initialTicket;
    if (ticket != null) {
      _gameCode = ticket.gameCode;
      _numbersController.text = ticket.whiteNumbers.join(', ');
      _specialController.text = ticket.specialNumber;
    }
  }

  Future<void> _openSavedTickets() async {
    final ticket = await Navigator.of(context).push<SavedLotteryTicket>(
      MaterialPageRoute(builder: (_) => const SavedTicketsScreen()),
    );
    if (ticket == null || !mounted) return;
    setState(() {
      _gameCode = ticket.gameCode;
      _numbersController.text = ticket.whiteNumbers.join(', ');
      _specialController.text = ticket.specialNumber;
      _check = null;
      _inputError = null;
    });
  }

  Future<void> _askToSaveNumbers() async {
    final labelController = TextEditingController();
    final label = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF102638),
        title: const Text(
          'Name this number set',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: labelController,
          autofocus: true,
          maxLength: 32,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Example: Friday numbers',
            hintStyle: TextStyle(color: Colors.white38),
            helperText: 'Optional — you can change it later.',
            helperStyle: TextStyle(color: Colors.white54),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF355066)),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF1478FF)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(labelController.text),
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
    labelController.dispose();
    if (label == null || !mounted) return;
    await _saveNumbers(label: label);
  }

  Future<void> _saveNumbers({String? label}) async {
    final ticketNumbers = _numbersFromInput();
    final specialNumber = int.tryParse(_specialController.text.trim());
    if (ticketNumbers == null || specialNumber == null) {
      setState(() {
        _inputError =
            'Enter five different white-ball numbers and one special ball.';
      });
      return;
    }
    try {
      await SavedTicketService.save(
        gameCode: _gameCode,
        whiteNumbers: ticketNumbers,
        specialNumber: specialNumber.toString(),
        label: label,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Number set saved on this device.'),
          action: SnackBarAction(label: 'VIEW', onPressed: _openSavedTickets),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save this number set. Please try again.'),
        ),
      );
    }
  }

  @override
  void dispose() {
    _service.dispose();
    _numbersController.dispose();
    _specialController.dispose();
    super.dispose();
  }

  List<String>? _numbersFromInput() {
    final values = _numbersController.text
        .trim()
        .split(RegExp(r'[\s,]+'))
        .where((value) => value.isNotEmpty)
        .toList();
    if (values.length != 5 ||
        values.any((value) => int.tryParse(value) == null)) {
      return null;
    }
    if (values.toSet().length != values.length) return null;
    return values.map((value) => int.parse(value).toString()).toList();
  }

  Future<void> _checkTicket() async {
    final ticketNumbers = _numbersFromInput();
    final specialNumber = int.tryParse(_specialController.text.trim());
    if (ticketNumbers == null || specialNumber == null) {
      setState(() {
        _inputError =
            'Enter five different white-ball numbers and one special ball.';
        _check = null;
      });
      return;
    }

    setState(() {
      _inputError = null;
      _check = null;
      _isChecking = true;
    });

    try {
      final result = await _service.latest(_gameCode);
      final matchedWhites = ticketNumbers
          .where((number) => result.numbers.contains(number))
          .length;
      final specialMatched = result.specialNumber == specialNumber.toString();
      if (!mounted) return;
      setState(() {
        _check = _TicketCheck(
          result: result,
          matchedWhites: matchedWhites,
          specialMatched: specialMatched,
        );
      });
    } on MuslDrawException catch (error) {
      if (!mounted) return;
      setState(() => _inputError = error.message);
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF071827),
    appBar: AppBar(
      backgroundColor: const Color(0xFF071827),
      foregroundColor: Colors.white,
      title: const Text('Ticket Checker'),
      actions: [
        IconButton(
          tooltip: 'My tickets',
          onPressed: _openSavedTickets,
          icon: const Icon(Icons.bookmark_outline_rounded),
        ),
      ],
    ),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      children: [
        const Text(
          'CHECK LATEST DRAW',
          style: TextStyle(
            color: Color(0xFF60A5FA),
            fontSize: 12,
            letterSpacing: 1.1,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'This compares your numbers with the latest completed national draw. It does not calculate a prize or validate a ticket.',
          style: TextStyle(color: Colors.white60, height: 1.35),
        ),
        const SizedBox(height: 20),
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _gameCode,
                dropdownColor: const Color(0xFF102638),
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Game',
                  labelStyle: TextStyle(color: Colors.white70),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF355066)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF1478FF)),
                  ),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'powerball',
                    child: Text('Powerball'),
                  ),
                  DropdownMenuItem(
                    value: 'mega-millions',
                    child: Text('Mega Millions'),
                  ),
                ],
                onChanged: _isChecking
                    ? null
                    : (value) => setState(() {
                        _gameCode = value!;
                        _check = null;
                        _inputError = null;
                      }),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _numbersController,
                enabled: !_isChecking,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Five white-ball numbers',
                  hintText: 'Example: 4, 12, 23, 45, 60',
                  labelStyle: TextStyle(color: Colors.white70),
                  hintStyle: TextStyle(color: Colors.white38),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF355066)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF1478FF)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _specialController,
                enabled: !_isChecking,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Special ball',
                  hintText: 'Example: 11',
                  labelStyle: TextStyle(color: Colors.white70),
                  hintStyle: TextStyle(color: Colors.white38),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF355066)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF1478FF)),
                  ),
                ),
              ),
              if (_inputError != null) ...[
                const SizedBox(height: 12),
                Text(
                  _inputError!,
                  style: const TextStyle(color: Color(0xFFFCA5A5)),
                ),
              ],
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isChecking || !_service.isConfigured
                      ? null
                      : _checkTicket,
                  icon: _isChecking
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_circle_outline_rounded),
                  label: Text(_isChecking ? 'CHECKING…' : 'CHECK NUMBERS'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF1478FF),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(50),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isChecking ? null : _askToSaveNumbers,
                  icon: const Icon(Icons.bookmark_add_outlined),
                  label: const Text('SAVE THESE NUMBERS'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFF355066)),
                    minimumSize: const Size.fromHeight(46),
                  ),
                ),
              ),
              if (!_service.isConfigured) ...[
                const SizedBox(height: 10),
                const Text(
                  'Connect MUSL results first to use the ticket checker.',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ],
          ),
        ),
        if (_check != null) ...[
          const SizedBox(height: 18),
          _MatchCard(check: _check!),
        ],
      ],
    ),
  );

  Widget _card({required Widget child}) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFF102638),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFF355066)),
    ),
    child: child,
  );
}

class _TicketCheck {
  const _TicketCheck({
    required this.result,
    required this.matchedWhites,
    required this.specialMatched,
  });

  final NationalDrawResult result;
  final int matchedWhites;
  final bool specialMatched;
}

class _MatchCard extends StatelessWidget {
  const _MatchCard({required this.check});

  final _TicketCheck check;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: const Color(0xFF102638),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFF2CC36B)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'LATEST-DRAW MATCH',
          style: TextStyle(
            color: Color(0xFF86EFAC),
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          check.result.gameName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 21,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          'Completed draw: ${check.result.drawDate}',
          style: const TextStyle(color: Colors.white60, fontSize: 12),
        ),
        const Divider(height: 28, color: Colors.white12),
        Text(
          '${check.matchedWhites} white-ball match${check.matchedWhites == 1 ? '' : 'es'}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          check.specialMatched
              ? 'Special ball matched'
              : 'Special ball did not match',
          style: TextStyle(
            color: check.specialMatched
                ? const Color(0xFF86EFAC)
                : Colors.white60,
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'This is not a prize determination. Check your physical ticket and verify all results with the official lottery.',
          style: TextStyle(color: Colors.white54, fontSize: 12, height: 1.35),
        ),
      ],
    ),
  );
}
