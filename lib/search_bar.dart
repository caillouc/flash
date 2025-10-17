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
          cardNotifier.setTextFilter(value); 
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
