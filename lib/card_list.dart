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
          return _PinchToOpenCard(
            onPinchOut: () => _openCard(card),
            child: Center(
              child: card,
            ),
          );
        },
      ),
    );
  }
}

class _PinchToOpenCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onPinchOut;

  const _PinchToOpenCard({
    required this.child,
    required this.onPinchOut,
  });

  @override
  State<_PinchToOpenCard> createState() => _PinchToOpenCardState();
}

class _PinchToOpenCardState extends State<_PinchToOpenCard> {
  double _maxScale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onScaleStart: (_) {
        _maxScale = 1.0;
      },
      onScaleUpdate: (details) {
        if (details.scale > _maxScale) {
          _maxScale = details.scale;
        }
      },
      onScaleEnd: (_) {
        if (_maxScale >= 1.12) {
          widget.onPinchOut();
        }
      },
      child: widget.child,
    );
  }
}
