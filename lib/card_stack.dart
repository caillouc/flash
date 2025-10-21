import 'package:flash/card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';

import 'main.dart';

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
        refresh();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    List<FlashCard> filteredCards = cardNotifier.filteredCards();
    if (filteredCards.isEmpty) {
      filteredCards = [
        const FlashCard(key: ValueKey('no_cards_placeholder'), frontTitle: "Aucune carte ne correspond aux filtres")
      ];
    }
    return CardSwiper(
      cardsCount: filteredCards.length,
      controller: widget.controller,
      numberOfCardsDisplayed: 3,
      isLoop: false,
      threshold: 70,
      cardBuilder: (context, index, percentThresholdX, percentThresholdY) {
        final card = filteredCards[index];
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
      //     filteredCards[index],
      allowedSwipeDirection:
          const AllowedSwipeDirection.only(left: true, right: true),
      onEnd: () {
        filteredCards = cardNotifier.filteredCards();
        refresh();
      },
      onSwipe: (previousIndex, currentIndex, direction) {
        if (settingsNotifier.apprentissage) {
          if (direction == CardSwiperDirection.left) {
            cardNotifier.demoteCard(filteredCards[previousIndex]);
          } else {
            cardNotifier.promoteCard(filteredCards[previousIndex]);
          }
        }
        return true;
      },
      onUndo: (previousIndex, currentIndex, direction) {
        return cardNotifier.undo(filteredCards[currentIndex]);
      },
    );
  }
}
