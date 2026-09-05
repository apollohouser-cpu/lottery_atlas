import 'package:flutter/material.dart';

import '../../models/saved_lottery_ticket.dart';
import '../../services/saved_ticket_service.dart';

class SavedTicketsScreen extends StatefulWidget {
  const SavedTicketsScreen({super.key});

  @override
  State<SavedTicketsScreen> createState() => _SavedTicketsScreenState();
}

class _SavedTicketsScreenState extends State<SavedTicketsScreen> {
  late Future<List<SavedLotteryTicket>> _tickets;

  @override
  void initState() {
    super.initState();
    _tickets = SavedTicketService.load();
  }

  Future<void> _deleteTicket(SavedLotteryTicket ticket) async {
    try {
      await SavedTicketService.delete(ticket.id);
      if (mounted) setState(() => _tickets = SavedTicketService.load());
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not remove this saved number set.'),
        ),
      );
    }
  }

  Future<void> _renameTicket(SavedLotteryTicket ticket) async {
    final labelController = TextEditingController(text: ticket.label ?? '');
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
            helperText: 'Leave blank to remove the name.',
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
    try {
      await SavedTicketService.rename(ticket.id, label);
      if (mounted) setState(() => _tickets = SavedTicketService.load());
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not rename this number set.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF071827),
    appBar: AppBar(
      backgroundColor: const Color(0xFF071827),
      foregroundColor: Colors.white,
      title: const Text('My Tickets'),
    ),
    body: FutureBuilder<List<SavedLotteryTicket>>(
      future: _tickets,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF1478FF)),
          );
        }
        final tickets = snapshot.data ?? const <SavedLotteryTicket>[];
        if (tickets.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.bookmark_border_rounded,
                    color: Colors.white54,
                    size: 44,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'No saved number sets yet',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Save a number set from Ticket Checker to keep it on this device.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white60),
                  ),
                ],
              ),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          itemCount: tickets.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final ticket = tickets[index];
            return Material(
              color: const Color(0xFF102638),
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => Navigator.of(context).pop(ticket),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF355066)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.confirmation_number_outlined,
                        color: Color(0xFF60A5FA),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (ticket.label != null) ...[
                              Text(
                                ticket.label!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 3),
                            ],
                            Text(
                              ticket.gameName,
                              style: TextStyle(
                                color: ticket.label == null
                                    ? Colors.white
                                    : Colors.white70,
                                fontWeight: FontWeight.w700,
                                fontSize: ticket.label == null ? null : 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${ticket.whiteNumbers.join('  ')}  •  ${ticket.specialNumber}',
                              style: const TextStyle(color: Colors.white70),
                            ),
                            const SizedBox(height: 3),
                            const Text(
                              'Tap to check the latest draw',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Rename saved numbers',
                        onPressed: () => _renameTicket(ticket),
                        icon: const Icon(
                          Icons.edit_outlined,
                          color: Colors.white54,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Delete saved numbers',
                        onPressed: () => _deleteTicket(ticket),
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.white54,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    ),
  );
}
