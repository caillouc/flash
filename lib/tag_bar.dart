import 'package:flutter/material.dart';
import 'main.dart';

class TagBar extends StatefulWidget {
  const TagBar({super.key});

  @override
  State<TagBar> createState() => _TagBarState();
}

class _TagBarState extends State<TagBar> {
  @override
  void initState() {
    super.initState();
    tagNotifier.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (tagNotifier.allTags.isEmpty) {
      return const SizedBox.shrink();
    }
    return Container(
        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 2.0),
        child: SizedBox(
          height: 36,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: tagNotifier.allTags.length,
            itemBuilder: (context, index) {
              final tag = tagNotifier.allTags[index];
              final isSelected = tagNotifier.selectedTags.contains(tag);
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
                    print("Tag selected: $tag");
                    if (tag == "Tout") {
                      tagNotifier.clearTags();
                    } else {
                      tagNotifier.toggleTag(tag);
                    }
                  },
                ),
              );
            },
          ),
        ));
  }
}
