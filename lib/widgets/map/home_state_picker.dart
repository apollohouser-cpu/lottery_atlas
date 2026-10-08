import 'package:flutter/material.dart';
import '../../models/state_model.dart';

Future<String?> showHomeStatePicker(BuildContext context, {String? selected}) =>
    showDialog<String>(
      context: context,
      builder: (_) => _HomeStatePicker(selected: selected),
    );

class _HomeStatePicker extends StatefulWidget {
  const _HomeStatePicker({this.selected});
  final String? selected;

  @override
  State<_HomeStatePicker> createState() => _HomeStatePickerState();
}

class _HomeStatePickerState extends State<_HomeStatePicker> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final states = allStates
        .where(
          (state) => '${state.name} ${state.abbreviation}'
              .toLowerCase()
              .contains(_query),
        )
        .toList();
    return Dialog(
      backgroundColor: const Color(0xFF102638),
      insetPadding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460, maxHeight: 560),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Choose your home state',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white70),
                  ),
                ],
              ),
              const Text(
                'Home will take you here. You can change it in Settings.',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 12),
              TextField(
                onChanged: (value) =>
                    setState(() => _query = value.trim().toLowerCase()),
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Search states',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: states.isEmpty
                    ? const Center(child: Text('No states match that search.'))
                    : ListView.builder(
                        itemCount: states.length,
                        itemBuilder: (context, index) {
                          final state = states[index];
                          return ListTile(
                            leading: Text(
                              state.abbreviation,
                              style: const TextStyle(color: Color(0xFF60A5FA)),
                            ),
                            title: Text(
                              state.name,
                              style: const TextStyle(color: Colors.white),
                            ),
                            trailing: state.name == widget.selected
                                ? const Icon(
                                    Icons.check,
                                    color: Color(0xFF60A5FA),
                                  )
                                : null,
                            onTap: () => Navigator.pop(context, state.name),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
