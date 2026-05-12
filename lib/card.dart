import "dart:io";
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
  final bool showDescription;

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
    this.showDescription = true,
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

  Widget _buildImage(String imagePath) {
    if (imagePath.isEmpty) return const SizedBox.shrink();
    final file = File(imagePath);
    return Expanded(
      child: Image.file(
        file,
        fit: BoxFit.contain,
        gaplessPlayback: true,
        errorBuilder: (context, error, stackTrace) {
          return const Center(child: Icon(Icons.image_not_supported, size: 50));
        },
      ),
    );
  }

  Widget _buildSide(bool isFrontSide) {
    String image = isFrontSide ? widget.frontImage : widget.backImage;
    String title = isFrontSide ? widget.frontTitle : widget.backTitle;
    String description =
        isFrontSide ? widget.frontDescription : widget.backDescription;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (image.isNotEmpty) ...[_buildImage(image)],
        if (title.isNotEmpty) ...[
          const SizedBox(height: 20),
          LayoutBuilder(builder: (context, constraints) {
            return ConstrainedBox(
              constraints: BoxConstraints(maxWidth: constraints.maxWidth),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  title,
                  style: const TextStyle(
                      fontSize: 28, fontWeight: FontWeight.bold),
                ),
              ),
            );
          }),
        ],
        if (description.isNotEmpty && widget.showDescription) ...[
          const SizedBox(height: 10),
          Flexible(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: SingleChildScrollView(
                child: Text(
                  description,
                  textAlign: TextAlign.justify,
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ),
          ),
        ],
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

    return LayoutBuilder(builder: (context, constraints) {
      final maxAvailableWidth = constraints.maxWidth.isFinite
          ? constraints.maxWidth
          : MediaQuery.of(context).size.width;
      final maxAvailableHeight = constraints.maxHeight.isFinite
          ? constraints.maxHeight
          : MediaQuery.of(context).size.height;

      const ratioWidth = 3.0;
      const ratioHeight = 5.0;
      const maxCardWidth = 600.0;
      const maxCardHeight = 900.0;

      // Keep a fixed 3:5 ratio, computed from the minimum fitting dimension.
      final availableWidth = min(maxAvailableWidth, maxCardWidth);
      final availableHeight = min(maxAvailableHeight, maxCardHeight);
      final scale = min(
        availableWidth / ratioWidth,
        availableHeight / ratioHeight,
      );
      final cardWidth = ratioWidth * scale;
      final cardHeight = ratioHeight * scale;

      return Transform(
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..rotateY(angle),
        alignment: Alignment.center,
        child: Card(
          elevation: 10,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: SizedBox(
            width: cardWidth,
            height: cardHeight,
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
                  width: cardWidth,
                  height: cardHeight,
                  padding: const EdgeInsets.all(16.0),
                  child: showFront
                      ? shouldReverse
                          ? _buildSide(false)
                          : _buildSide(true)
                      // when showing the back after 90 degrees we rotate its content
                      // by pi so the text isn't mirrored
                      : Transform(
                          transform: Matrix4.identity()..rotateY(pi),
                          alignment: Alignment.center,
                          child: shouldReverse
                              ? _buildSide(true)
                              : _buildSide(false),
                        ),
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
}
