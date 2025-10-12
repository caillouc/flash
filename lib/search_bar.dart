import 'package:flutter/material.dart';

class CustomSearchBar extends StatelessWidget {
  final TextEditingController controller;

  const CustomSearchBar({super.key, required this.controller});


  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          labelText: 'Search',
          suffixIcon: IconButton(
            icon: const Icon(Icons.clear),
            onPressed: (() {
              controller.clear();
            }),
          ),
        ),
      ),
    );
  }
}
