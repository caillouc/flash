import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import "dart:math";

class FlashCard extends StatefulWidget {
  final String frontTitle;
  final String frontDescription;
  final String frontImage;
  final String backTitle;
  final String backDescription;
  final String backImage;

  const FlashCard(
      {super.key,
      required this.frontTitle,
      this.frontDescription = "",
      this.frontImage = "",
      required this.backTitle,
      this.backDescription = "",
      this.backImage = ""});

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
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
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
                    ? _buildFront()
                    // when showing the back after 90 degrees we rotate its content
                    // by pi so the text isn't mirrored
                    : Transform(
                        transform: Matrix4.identity()..rotateY(pi),
                        alignment: Alignment.center,
                        child: _buildBack(),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
