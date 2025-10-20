import "dart:math";

import 'package:flash/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FlashCard extends StatefulWidget {
  final String id;
  final String frontTitle;
  final String frontDescription;
  final String frontImage;
  final String backTitle;
  final String backDescription;
  final String backImage;
  final List<String> tags;
  final bool randomReverse; // Optional override for random orientation

  const FlashCard({
    super.key,
    this.id = "",
    this.frontTitle = "",
    this.frontDescription = "",
    this.frontImage = "",
    this.backTitle = "",
    this.backDescription = "",
    this.backImage = "",
    this.tags = const [],
    this.randomReverse = false,
  });

  @override
  State<FlashCard> createState() => _FlashCardState();
}

class _FlashCardState extends State<FlashCard>
    with SingleTickerProviderStateMixin {
  bool isFront = true;
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    
    settingsNotifier.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    )
      ..addListener(() {
        setState(() {});
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          isFront = false;
        } else if (status == AnimationStatus.dismissed) {
          isFront = true;
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildFront() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.frontImage.isNotEmpty)
          Image.asset(widget.frontImage, width: 200, height: 200),
        const SizedBox(height: 20),
        Text(
          widget.frontTitle,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            widget.frontDescription,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildBack() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.backImage.isNotEmpty)
          Image.asset(widget.backImage, width: 200, height: 200),
        const SizedBox(height: 20),
        Text(
          widget.backTitle,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            widget.backDescription,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // angle from 0.0 -> pi (front -> back)
    final angle = _controller.value * pi;

    // choose which side to display depending on the animation angle
    final showFront = angle <= (pi / 2);
    
    final shouldReverse = settingsNotifier.mixCardOrientation
        ? widget.randomReverse
        : settingsNotifier.reverseCardOrientation;

    return Transform(
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.001)
        ..rotateY(angle),
      alignment: Alignment.center,
      child: Card(
        elevation: 10,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: SizedBox(
          width: 300,
          height: 500,
          child: GestureDetector(
            onLongPress: () async {
              SharedPreferences.getInstance().then((prefs) {
                String boxKey =
                    '${quizzListNotifier.currentQuizzUniqueId}_${widget.id}_box';
                String remainingDaysKey =
                    '${quizzListNotifier.currentQuizzUniqueId}_${widget.id}_remaining_days';
                int currentBox = prefs.getInt(boxKey) ?? 5;
                int currentRemaining = prefs.getInt(remainingDaysKey) ?? 0;
                SnackBar snackBar = SnackBar(
                  content: Text(
                      "${widget.frontTitle} : Box=$currentBox, RemainingDays=$currentRemaining"),
                  duration: const Duration(seconds: 2),
                );
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(snackBar);
              });
            },
            behavior: HitTestBehavior.opaque,
            onTap: () async {
              // give a light haptic feedback then animate flip
              try {
                await HapticFeedback.lightImpact();
              } catch (_) {}
              if (_controller.isAnimating) return;
              if (isFront) {
                _controller.forward();
              } else {
                _controller.reverse();
              }
            },
            child: Center(
              child: Container(
                width: 300,
                height: 500,
                padding: const EdgeInsets.all(16.0),
                child: showFront
                    ? shouldReverse
                        ? _buildBack()
                        : _buildFront()
                    // when showing the back after 90 degrees we rotate its content
                    // by pi so the text isn't mirrored
                    : Transform(
                        transform: Matrix4.identity()..rotateY(pi),
                        alignment: Alignment.center,
                        child: shouldReverse
                            ? _buildFront()
                            : _buildBack(),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
