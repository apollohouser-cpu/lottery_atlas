import 'package:flutter/material.dart';

import '../../models/state_model.dart';

class StateTestScreen extends StatefulWidget {
  const StateTestScreen({super.key});

  @override
  State<StateTestScreen> createState() => _StateTestScreenState();
}

class _StateTestScreenState extends State<StateTestScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      appBar: AppBar(
        title: const Text('Lottery Atlas - States'),
        backgroundColor: Colors.black,
      ),

      body: ListView.builder(
        itemCount: allStates.length,

        itemBuilder: (context, index) {
          final state = allStates[index];

          return Card(
            color: Colors.grey[900],

            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),

            child: ListTile(
              title: Text(
                state.name,

                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              subtitle: Text(
                state.abbreviation,

                style: const TextStyle(color: Colors.white70),
              ),

              trailing: const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white,
                size: 18,
              ),

              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${state.name} selected')),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
