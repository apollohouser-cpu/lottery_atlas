import 'package:flutter/material.dart';

import '../../models/state_model.dart';
import 'state_details_screen.dart';

class StateTestScreen extends StatelessWidget {
  const StateTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      appBar: AppBar(
        title: const Text('State Test Screen'),

        backgroundColor: Colors.black,

        foregroundColor: Colors.white,
      ),

      body: ListView.builder(
        itemCount: allStates.length,

        itemBuilder: (context, index) {
          final state = allStates[index];

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),

            decoration: BoxDecoration(
              color: Colors.grey[900],

              borderRadius: BorderRadius.circular(8),
            ),

            child: ListTile(
              title: Text(
                state.name,

                style: const TextStyle(
                  color: Colors.white,

                  fontSize: 17,

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
                Navigator.push(
                  context,

                  MaterialPageRoute(
                    builder: (context) => StateDetailsScreen(state: state),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
