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
  List<FlashCard> _filteredCards = [];
  late bool _apprentissageMode;

  List<FlashCard> _buildFilteredCards() {
    List<FlashCard> filteredCards = cardNotifier.filteredCards();
    if (filteredCards.isEmpty) {
      filteredCards = [
        const FlashCard(key: ValueKey('no_cards_placeholder'), frontTitle: "Aucune carte ne correspond aux filtres")
      ];
    }
    filteredCards = filteredCards
        .map((card) => FlashCard(
              key: card.key,
              id: card.id,
              frontTitle: card.frontTitle,
              frontDescription: card.frontDescription,
              frontImage: card.frontImage,
              backTitle: card.backTitle,
              backDescription: card.backDescription,
              backImage: card.backImage,
              tags: card.tags,
              randomReverse: card.randomReverse,
              showDescription: card.showDescription,
              enableImageZoom: false,
            ))
        .toList();
    return filteredCards;
  }

  void refresh({bool resetHistory = true}) {
    if (resetHistory) {
      cardNotifier.clearHistory();
    }
    widget.controller.moveTo(0);
    setState(() {
      _filteredCards = _buildFilteredCards();
      _apprentissageMode = settingsNotifier.apprentissage;
    });
  }

  void _handleCardNotifierChanged() {
    if (mounted) {
      refresh();
    }
  }

  void _handleTagNotifierChanged() {
    if (mounted) {
      refresh();
    }
  }

  void _handleSettingsNotifierChanged() {
    if (mounted) {
      refresh();
    }
  }

  @override
  void initState() {
    super.initState();
    _apprentissageMode = settingsNotifier.apprentissage;
    _filteredCards = _buildFilteredCards();
    cardNotifier.addListener(_handleCardNotifierChanged);
    tagNotifier.addListener(_handleTagNotifierChanged);
    settingsNotifier.addListener(_handleSettingsNotifierChanged);
  }

  @override
  void dispose() {
    cardNotifier.removeListener(_handleCardNotifierChanged);
    tagNotifier.removeListener(_handleTagNotifierChanged);
    settingsNotifier.removeListener(_handleSettingsNotifierChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<FlashCard> filteredCards = _filteredCards;
    bool hasNoCard = filteredCards.first.key == const ValueKey('no_cards_placeholder');
    return CardSwiper(
      cardsCount: filteredCards.length,
      controller: widget.controller,
      numberOfCardsDisplayed: filteredCards.length < 3 ? filteredCards.length : 3,
      isLoop: !hasNoCard,
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

      allowedSwipeDirection:
          const AllowedSwipeDirection.only(left: true, right: true),
      onEnd: () {
        refresh(resetHistory: false);
      },
      onSwipe: (previousIndex, currentIndex, direction) {
        if (hasNoCard) return false;
        if (_apprentissageMode) {
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
