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
        // Reset scroll position to top when quiz/cards change
        widget.controller.jumpTo(0);
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
      child: GridView.builder(
        controller: widget.controller,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 8.0,
          mainAxisSpacing: 8.0,
          childAspectRatio: 3.0 / 5.0,
        ),
        itemCount: filterdCards.length,
        itemBuilder: (context, index) {
          return Center(
            child: filterdCards[index],
          );
        },
      ),
    );
  }
}
