import 'package:flutter/material.dart';

import 'main.dart';

class CustomSearchBar extends StatelessWidget {
  final TextEditingController controller;

  const CustomSearchBar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: TextField(
        controller: controller,
        onChanged: (value) {
          // Easter egg: toggle private mode when typing flash.clsn.fr
          if (value.toLowerCase() == 'flash.clsn.fr') {
            settingsNotifier.privateMode = !settingsNotifier.privateMode;
            // Clear the search bar
            quizzListNotifier.fetchAndSavePrivateQuizzList().then((_) {
              controller.clear();
              cardNotifier.setTextFilter('');
              quizzListNotifier.checkNewVersion();

              // Show a subtle confirmation
              if (context.mounted) {
                final modeStatus = settingsNotifier.privateMode ? '🔓 Private mode activated' : '🔒 Private mode deactivated';
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(modeStatus),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            });
          } else {
            cardNotifier.setTextFilter(value);
          }
        },
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          labelText: 'Rechercher',
          suffixIcon: IconButton(
            icon: const Icon(Icons.clear),
            onPressed: (() {
              cardNotifier.setTextFilter('');
              controller.clear();
            }),
          ),
        ),
      ),
    );
  }
}
