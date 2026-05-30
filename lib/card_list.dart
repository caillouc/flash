import 'dart:math';

import 'package:flash/card.dart';
import 'package:flutter/material.dart';

import 'expanded_card_view.dart';
import 'main.dart';

class CardList extends StatefulWidget {
  final ScrollController controller;

  const CardList({super.key, required this.controller});

  @override
  State<CardList> createState() => _CardListState();
}

class _CardListState extends State<CardList> {
  void _openCard(FlashCard card) {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (context) => ExpandedCardView(card: card),
    );
  }

  void _handleCardNotifierChanged() {
    if (mounted) {
      // Reset scroll position to top when quiz/cards change
      widget.controller.jumpTo(0);
      setState(() {});
    }
  }

  void _handleTagNotifierChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    cardNotifier.addListener(_handleCardNotifierChanged);
    tagNotifier.addListener(_handleTagNotifierChanged);
  }

  @override
  void dispose() {
    cardNotifier.removeListener(_handleCardNotifierChanged);
    tagNotifier.removeListener(_handleTagNotifierChanged);
    super.dispose();
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
          final card = filterdCards[index];
          return _CardWithPinchAndButton(
            card: FlashCard(
              id: card.id,
              frontTitle: card.frontTitle,
              frontDescription: card.frontDescription,
              frontImage: card.frontImage,
              backTitle: card.backTitle,
              backDescription: card.backDescription,
              backImage: card.backImage,
              tags: card.tags,
              randomReverse: card.randomReverse,
              showDescription: quizzListNotifier.currentQuizzName.isEmpty,
            ),
            onExpand: () => _openCard(card),
          );
        },
      ),
    );
  }
}

class _CardWithPinchAndButton extends StatelessWidget {
  final FlashCard card;
  final VoidCallback onExpand;

  const _CardWithPinchAndButton({
    required this.card,
    required this.onExpand,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      const ratioWidth = 3.0;
      const ratioHeight = 5.0;
      const maxCardWidth = 600.0;
      const maxCardHeight = 900.0;

      final availableWidth = min(constraints.maxWidth, maxCardWidth);
      final availableHeight = min(constraints.maxHeight, maxCardHeight);
      final scale = min(
        availableWidth / ratioWidth,
        availableHeight / ratioHeight,
      );
      final cardWidth = ratioWidth * scale;
      final cardHeight = ratioHeight * scale;

      return Center(
        child: SizedBox(
          width: cardWidth,
          height: cardHeight,
          child: Stack(
            children: [
              Positioned.fill(child: card),
              Positioned(
                top: 5,
                right: 5,
                child: Material(
                  color: Colors.transparent,
                  child: IconButton(
                    iconSize: 20,
                    constraints: const BoxConstraints(
                      minWidth: 0,
                      minHeight: 0,
                    ),
                    padding: const EdgeInsets.all(4),
                    icon: const Icon(Icons.zoom_in),
                    onPressed: onExpand,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
