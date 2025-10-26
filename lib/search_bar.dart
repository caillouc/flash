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
          // Easter egg: activate private mode when typing flash.clsn.fr
          if (value.toLowerCase() == 'flash.clsn.fr') {
            quizzListNotifier.enablePrivateMode().then((_) {
              // Clear the search bar
              controller.clear();
              cardNotifier.setTextFilter('');
              quizzListNotifier.checkNewVersion();
              
              // Show a subtle confirmation
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('🔓 Private mode activated'),
                  duration: Duration(seconds: 2),
                ),
              );
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
