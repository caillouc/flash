import 'package:flutter/material.dart';

class TagBar extends StatefulWidget {
  final List<String> tags;

  TagBar({super.key, required List<String> tags})
      : tags = tags.isNotEmpty ? ["Tout", ...tags] : [];

  @override
  State<TagBar> createState() => _TagBarState();
}

class _TagBarState extends State<TagBar> {
  List selectedTags = [];

  @override
  Widget build(BuildContext context) {
    if (widget.tags.isEmpty) {
      return const SizedBox.shrink();
    }
    return Container(
        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 2.0),
        child: SizedBox(
          height: 36,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: widget.tags.length,
            itemBuilder: (context, index) {
              final tag = widget.tags[index];
              final isSelected = selectedTags.contains(tag);
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2.0),
                child: ChoiceChip(
                  label: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 2.0, horizontal: 8.0),
                    child: Text(
                      tag,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w500),
                    ),
                  ),
                  selected: isSelected,
                  visualDensity: VisualDensity.compact,
                  onSelected: (bool value) {
                    setState(() {
                      if (tag == "Tout") {
                        selectedTags.clear();
                      } else {
                        if (value) {
                          selectedTags.add(tag);
                        } else {
                          selectedTags.remove(tag);
                        }
                      }
                    });
                  },
                ),
              );
            },
          ),
        ));
  }
}
