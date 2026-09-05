import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/state_lottery_source_registry.dart';

/// Reusable official-resource screen for states added to the source registry.
class StateLotterySourceScreen extends StatelessWidget {
  const StateLotterySourceScreen({super.key, required this.source});

  final StateLotterySource source;

  Future<void> _open(BuildContext context, String url) async {
    final launched = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open the official lottery site.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF071827),
    appBar: AppBar(
      backgroundColor: const Color(0xFF071827),
      foregroundColor: Colors.white,
      title: Text('${source.stateName} Lottery'),
    ),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFF102638),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFF355066)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'OFFICIAL STATE SOURCE',
                style: TextStyle(
                  color: Color(0xFF60A5FA),
                  fontSize: 12,
                  letterSpacing: 1.1,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Lottery Atlas opens current information directly from ${source.providerName}. Always verify a ticket with the official lottery.',
                style: const TextStyle(color: Colors.white70, height: 1.35),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        ...source.resources.map(
          (resource) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _OfficialResourceButton(
              resource: resource,
              onTap: () => _open(context, resource.url),
            ),
          ),
        ),
      ],
    ),
  );
}

class _OfficialResourceButton extends StatelessWidget {
  const _OfficialResourceButton({required this.resource, required this.onTap});

  final StateLotteryResource resource;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xFF102638),
    borderRadius: BorderRadius.circular(16),
    child: InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF355066)),
        ),
        child: Row(
          children: [
            Icon(_iconFor(resource.title), color: const Color(0xFF60A5FA)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    resource.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    resource.subtitle,
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.open_in_new_rounded, color: Colors.white54),
          ],
        ),
      ),
    ),
  );

  IconData _iconFor(String title) {
    if (title.contains('Remaining')) return Icons.workspace_premium_outlined;
    if (title.contains('Scratch-Off')) {
      return Icons.confirmation_number_outlined;
    }
    if (title.contains('Draw')) return Icons.schedule_rounded;
    return Icons.emoji_events_outlined;
  }
}
