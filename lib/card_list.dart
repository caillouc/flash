import 'package:flash/card.dart';
import 'package:flutter/material.dart';

class CardList extends StatelessWidget {
  final List<FlashCard> cards;
  final ScrollController controller;

  const CardList({super.key, required this.cards, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ListView.builder(
        controller: controller,
        itemCount: cards.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
            child: cards[index],
          );
        },
      ),
    );
  }

}