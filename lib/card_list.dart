import 'package:flash/card.dart';
import 'package:flutter/material.dart';

import 'main.dart';
import 'expanded_card_view.dart';

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
              showDescription: false,
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
    return Stack(
      children: [
        Center(
          child: card,
        ),
        Positioned(
          top: 5,
          right: 5,
          child: Material(
            color: Colors.transparent,
            child: IconButton(
              iconSize: 20,
              constraints: const BoxConstraints(minWidth: 0, minHeight: 0),
              padding: const EdgeInsets.all(4),
              icon: const Icon(Icons.zoom_in),
              onPressed: onExpand,
            ),
          ),
        ),
      ],
    );
  }
}
