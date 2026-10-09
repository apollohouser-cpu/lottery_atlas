import '../../widgets/map/north_carolina_draw_reports_sheet.dart';
import '../../widgets/map/north_carolina_scratch_catalog_sheet.dart';
import '../../widgets/map/missouri_local_directories_sheet.dart';
import '../../widgets/map/missouri_scratch_catalog_sheet.dart';
import '../../widgets/map/missouri_draw_reports_sheet.dart';
import '../../widgets/map/oregon_draw_reports_sheet.dart';
import '../../widgets/map/colorado_draw_reports_sheet.dart';
import '../../widgets/map/ohio_payout_reports_sheet.dart';
import '../../widgets/map/new_york_prize_tables_sheet.dart';
import '../../widgets/map/virginia_prize_tables_sheet.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/state_lottery_source_registry.dart';
import '../../services/state_source_cadence_registry.dart';
import '../../services/state_data_limitation_registry.dart';

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
        const SnackBar(content: Text('Could not open this page.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cadenceNotice = StateSourceCadenceRegistry.noticeFor(
      source.stateName,
    );
    final limitationNotice = StateDataLimitationRegistry.noticeFor(
      source.stateName,
    );
    return Scaffold(
      backgroundColor: const Color(0xFF071827),
      appBar: AppBar(
        backgroundColor: const Color(0xFF071827),
        foregroundColor: Colors.white,
        title: Text('${source.stateName} Lottery'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          if (source.stateName == 'North Carolina')
            Card(child: ListTile(
              title: const Text('North Carolina draw reports'),
              subtitle: const Text('Eight families • Separate sessions and source units'),
              onTap: () => showModalBottomSheet<void>(context: context, isScrollControlled: true, useSafeArea: true, builder: (_) => const NorthCarolinaDrawReportsSheet()),
            )),
          if (source.stateName == 'North Carolina')
            Card(child: ListTile(
              title: const Text('North Carolina Scratch-Off inventory'),
              subtitle: const Text('Literal prize tiers • Dated not-yet-claimed inventory'),
              onTap: () => showModalBottomSheet<void>(context: context, isScrollControlled: true, useSafeArea: true, builder: (_) => const NorthCarolinaScratchCatalogSheet()),
            )),
          if (source.stateName == 'Missouri')
            Card(child: ListTile(
              title: const Text('Missouri local retailer directories'),
              subtitle: const Text('Two city snapshots • Official search for other locations'),
              onTap: () => showModalBottomSheet<void>(context: context, isScrollControlled: true, builder: (_) => const MissouriLocalDirectoriesSheet()),
            )),
          if (source.stateName == 'Missouri')
            Card(child: ListTile(
              title: const Text('Missouri Scratchers inventory'),
              subtitle: const Text('Advertised prizes and estimated unclaimed inventory'),
              trailing: const Icon(Icons.confirmation_number_outlined),
              onTap: () => showModalBottomSheet<void>(context: context,
                isScrollControlled: true, builder: (_) => const MissouriScratchCatalogSheet()),
            )),
          if (source.stateName == 'Missouri')
            Card(child: ListTile(
              title: const Text('Missouri draw reports and game sources'),
              subtitle: const Text('Source prizes • Separate variants and sessions'),
              trailing: const Icon(Icons.table_chart_outlined),
              onTap: () => showModalBottomSheet<void>(context: context,
                isScrollControlled: true, builder: (_) => const MissouriDrawReportsSheet()),
            )),
          if (source.stateName == 'Oregon')
            Card(child: ListTile(
              title: const Text('Oregon draw reports and game sources'),
              subtitle: const Text('Reported winners and prizes • Source units and limits'),
              trailing: const Icon(Icons.table_chart_outlined),
              onTap: () => showModalBottomSheet<void>(context: context,
                isScrollControlled: true, builder: (_) => const OregonDrawReportsSheet()),
            )),
          if (source.stateName == 'Colorado')
            Card(child: ListTile(
              title: const Text('Colorado draw reports and game sources'),
              subtitle: const Text('Reported winners • Separate variants and wager units'),
              trailing: const Icon(Icons.table_chart_outlined),
              onTap: () => showModalBottomSheet<void>(context: context,
                isScrollControlled: true, builder: (_) => const ColoradoDrawReportsSheet()),
            )),
          if (source.stateName == 'Ohio')
            Card(child: ListTile(
              title: const Text('Ohio draw payouts and game sources'),
              subtitle: const Text('Published payout dollars • Winner counts unavailable'),
              trailing: const Icon(Icons.table_chart_outlined),
              onTap: () => showModalBottomSheet<void>(context: context,
                isScrollControlled: true, builder: (_) => const OhioPayoutReportsSheet()),
            )),
          if (source.stateName == 'Virginia' || source.stateName == 'New York')
            Card(
              child: ListTile(
                title: const Text('Draw reports and prize tables'),
                subtitle: const Text(
                  'National and state games • Source scope and limits shown per report',
                ),
                trailing: const Icon(Icons.table_chart_outlined),
                onTap: () => showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => source.stateName == 'New York'
                      ? const NewYorkPrizeTablesSheet()
                      : const VirginiaPrizeTablesSheet(),
                ),
              ),
            ),
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
          if (limitationNotice != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF4A340D),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                limitationNotice,
                style: const TextStyle(color: Colors.white, height: 1.4),
              ),
            ),
          ],
          if (cadenceNotice != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF4A340D),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFBBF24)),
              ),
              child: Text(
                cadenceNotice,
                style: const TextStyle(color: Colors.white, height: 1.35),
              ),
            ),
          ],
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
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () => _open(
              context,
              'https://apollohouser-cpu.github.io/lottery_atlas/state_refresh_status.html',
            ),
            icon: const Icon(Icons.update),
            label: const Text('Lottery Atlas data refresh status'),
          ),
        ],
      ),
    );
  }
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
