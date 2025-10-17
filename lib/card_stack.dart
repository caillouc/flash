import 'package:flash/card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:win32/win32.dart';

import 'main.dart';
import 'card.dart';

class CardStack extends StatefulWidget {
  final CardSwiperController controller;

  const CardStack({super.key, required this.controller});

  @override
  State<CardStack> createState() => _CardStackState();
}

class _CardStackState extends State<CardStack> {

  void refresh() {
    cardNotifier.clearHistory();
    widget.controller.moveTo(0);
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    cardNotifier.addListener(() {
      if (mounted) {
        refresh();
      }
    });
    tagNotifier.addListener(() {
      if (mounted) {
        refresh();
      }
    });
    settingsNotifier.addListener(() {
      if (mounted) {
        setState(() {});
        cardNotifier.clearHistory();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    List<FlashCard> filterdCards = cardNotifier.filteredCards();
    if (filterdCards.isEmpty) {
      filterdCards = [
        const FlashCard(frontTitle: "Aucune carte ne correspond aux filtres")
      ];
    }
    return CardSwiper(
      cardsCount: filterdCards.length,
      controller: widget.controller,
      numberOfCardsDisplayed: 3,
      threshold: 70,
      cardBuilder: (context, index, percentThresholdX, percentThresholdY) {
        final card = filterdCards[index];
        // Determine the color based on swipe direction
        final color = percentThresholdX > 0
            ? Colors.green.withValues(alpha: (percentThresholdX / 100).abs())
            : Colors.red.withValues(alpha: (percentThresholdX / 100).abs());

        return Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12), // Match card's border radius
          ),
          child: card,
        );
      },

      // cardBuilder: (context, index, percentThresholdX, percentThresholdY) =>
      //     filterdCards[index],
      allowedSwipeDirection:
          const AllowedSwipeDirection.only(left: true, right: true),
      onSwipe: (previousIndex, currentIndex, direction) {
        if (settingsNotifier.apprentissage) {
          if (direction == CardSwiperDirection.left) {
            cardNotifier.demoteCard(filterdCards[previousIndex]);
          } else {
            cardNotifier.promoteCard(filterdCards[previousIndex]);
          }
        }
        return true;
      },
      onUndo: (previousIndex, currentIndex, direction) {
        return cardNotifier.undo(filterdCards[currentIndex]);
      },
    );
  }
}
