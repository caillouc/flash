import 'package:flash/card.dart';
import 'package:flutter/material.dart';

import 'main.dart';

class CardList extends StatefulWidget {
  final ScrollController controller;

  const CardList({super.key, required this.controller});

  @override
  State<CardList> createState() => _CardListState();
}

class _CardListState extends State<CardList> {
  @override
  void initState() {
    super.initState();
    cardNotifier.addListener(() {
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
    List<FlashCard> filterdCards = cardNotifier.filteredCards(inListView: true);
    return Expanded(
      child: ListView.builder(
        controller: widget.controller,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        itemCount: filterdCards.length,
        itemBuilder: (context, index) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
              child: filterdCards[index],
            ),
          );
        },
      ),
    );
  }
}
