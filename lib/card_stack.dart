import 'package:flash/card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';

import 'main.dart';

class CardStack extends StatefulWidget {
  const CardStack({super.key});

  @override
  State<CardStack> createState() => _CardStackState();
}

class _CardStackState extends State<CardStack> {

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
    List<FlashCard> filterdCards = cardNotifier.cards;
    if (tagNotifier.selectedTags.isNotEmpty &&
        !tagNotifier.selectedTags.contains("Tout")) {
      filterdCards = filterdCards
          .where((card) => card.tags
              .any((tag) => tagNotifier.selectedTags.contains(tag)))
          .toList();
    }
    return CardSwiper(
      cardsCount: filterdCards.length,
      numberOfCardsDisplayed: 3,
      cardBuilder: (context, index, percentThresholdX, percentThresholdY) =>
          filterdCards[index],
      allowedSwipeDirection: const AllowedSwipeDirection.only(left: true, right: true),
    );
  }
}
