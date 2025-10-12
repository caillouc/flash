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
    currentQuizzNotifier.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return CardSwiper(
      cardsCount: currentQuizzNotifier.nbCard,
      numberOfCardsDisplayed: 3,
      cardBuilder: (context, index, percentThresholdX, percentThresholdY) =>
          currentQuizzNotifier.cards[index],
      allowedSwipeDirection: const AllowedSwipeDirection.only(left: true, right: true),
    );
  }
}
