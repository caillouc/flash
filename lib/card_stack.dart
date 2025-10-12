import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'card.dart';

class CardStack extends StatelessWidget {
  final List<FlashCard> cards;

  const CardStack({super.key, required this.cards});

  @override
  Widget build(BuildContext context) {
    return CardSwiper(
      cardsCount: cards.length,
      numberOfCardsDisplayed: 3,
      cardBuilder: (context, index, percentThresholdX, percentThresholdY) =>
          cards[index],
    );
  }
}
