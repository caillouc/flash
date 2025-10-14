import 'package:flash/card.dart';
import 'package:flutter/material.dart';

import 'main.dart';

class CardList extends StatefulWidget {
  final ScrollController controller;
  final TextEditingController searchController;

  const CardList({super.key, required this.controller, required this.searchController});

  @override
  State<CardList> createState() => _CardListState();
}

class _CardListState extends State<CardList> {

  @override
  void initState() {
    super.initState();
    currentQuizzNotifier.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
    tagNotifier.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    List<FlashCard> filterdCards = currentQuizzNotifier.cards;
    if (tagNotifier.selectedTags.isNotEmpty &&
        !tagNotifier.selectedTags.contains("Tout")) {
      filterdCards = filterdCards
          .where((card) => card.tags
              .any((tag) => tagNotifier.selectedTags.contains(tag)))
          .toList();
    }
    if (widget.searchController.text.isNotEmpty) {
      filterdCards = filterdCards
          .where((card) =>
              card.frontTitle
                  .toLowerCase()
                  .contains(widget.searchController.text.toLowerCase()) ||
              card.backTitle
                  .toLowerCase()
                  .contains(widget.searchController.text.toLowerCase()) ||
              card.backDescription
                  .toLowerCase()
                  .contains(widget.searchController.text.toLowerCase()) ||
              card.tags.any((tag) =>
                  tag.toLowerCase().contains(widget.searchController.text.toLowerCase())))
          .toList();
    }
    return Expanded(
      child: ListView.builder(
        controller: widget.controller,
        itemCount: filterdCards.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
            child: filterdCards[index],
          );
        },
      ),
    );
  }

}