import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../card.dart';
import '../quizz.dart';
import '../utils.dart' as utils;
import '../main.dart';
import '../constants.dart';

const int maxHistory = 5;

class CardNotifier extends ChangeNotifier {
  final List<FlashCard> _noLocalQuizzCards = [
    const FlashCard(
        key: ValueKey('placeholder_1'),
        frontDescription: "Téléchargez un quiz pour commencer"),
    const FlashCard(
        key: ValueKey('placeholder_2'),
        frontDescription:
            "Naviguez dans le menu en haut à gauche et sélectionnez vos quizz"),
    const FlashCard(
        key: ValueKey('placeholder_3'),
        frontDescription:
            "Vous pourrez ensuite réviser les cartes dans cette section"),
  ];
  List<FlashCard> _cards = [];
  String _cardTextFilter = "";
  // in-memory cache of remaining days per card id
  final Map<String, int> _remainingDaysMap = {};
  // in-memory cache of box levels per card id
  final Map<String, int> _boxMap = {};
  final List _history = [];

  List<FlashCard> get cards => List.unmodifiable(_cards);
  int get nbCard => _cards.length;

  void setNoLocalQuizz() {
    _cards = _noLocalQuizzCards;
    quizzListNotifier.currentQuizzName = "";
    tagNotifier.setAllTags([]);
    notifyListeners();
  }

  List<FlashCard> filteredCards({bool inListView = false}) {
    if (_cards == _noLocalQuizzCards) {
      return _cards;
    }
    List<FlashCard> filteredCards = List.from(cards);
    if (tagNotifier.hasSelectedTags) {
      filteredCards = filteredCards
          .where(
              (card) => card.tags.any((tag) => tagNotifier.isTagSelected(tag)))
          .toList();
    }
    if (_cardTextFilter.isNotEmpty) {
      filteredCards = filteredCards.where((card) {
        final lowerFilter = utils.removeAccents(_cardTextFilter).toLowerCase();
        return utils
                .removeAccents(card.frontTitle)
                .toLowerCase()
                .contains(lowerFilter) ||
            utils
                .removeAccents(card.frontDescription)
                .toLowerCase()
                .contains(lowerFilter) ||
            utils
                .removeAccents(card.backTitle)
                .toLowerCase()
                .contains(lowerFilter) ||
            utils
                .removeAccents(card.backDescription)
                .toLowerCase()
                .contains(lowerFilter);
      }).toList();
    }

    // If apprentissage mode is enabled, only keep cards with remaining_days == 0
    if (settingsNotifier.apprentissage && !inListView) {
      List<FlashCard> tempFilteredCards = filteredCards.where((card) {
        final remaining = _remainingDaysMap[card.id] ?? 0;
        return remaining <= 0;
      }).toList();
      if (tempFilteredCards.isNotEmpty) {
        filteredCards = tempFilteredCards;
      } else {
        filteredCards = _selectCardsWithWeightedRandom(filteredCards);
      }
    }
    if (!inListView &&
        quizzListNotifier.currentQuizzName.isNotEmpty &&
        _cards != _noLocalQuizzCards) {
      filteredCards = _shuffleAvoidingConsecutiveDuplicates(filteredCards);
    }
    return filteredCards;
  }

  List<FlashCard> _shuffleAvoidingConsecutiveDuplicates(List<FlashCard> cards) {
    if (cards.length < 2) return cards;

    final shuffled = List<FlashCard>.from(cards);
    const maxAttempts = 3;
    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      shuffled.shuffle();
      if (!_hasConsecutiveDuplicates(shuffled)) {
        return shuffled;
      }
    }

    return shuffled;
  }

  bool _hasConsecutiveDuplicates(List<FlashCard> cards) {
    for (int i = 1; i < cards.length; i++) {
      if (cards[i].id == cards[i - 1].id) {
        return true;
      }
    }
    return false;
  }

  List<FlashCard> _selectCardsWithWeightedRandom(List<FlashCard> cards) {
    final random = Random();

    // Define weights for each box (higher box = higher weight)
    // Box 5: 28.5%, Box 4: 23.8%, Box 3: 19%, Box 2: 14.3%, Box 1: 9.5%, Box 0: 4.7%
    final Map<int, double> boxWeights = {
      5: 28.5,
      4: 23.8,
      3: 19.0,
      2: 14.3,
      1: 9.5,
      0: 4.7,
    };

    final weightedCards = <FlashCard>[];
    final weights = <double>[];
    double totalWeight = 0;
    for (final card in cards) {
      final box = _boxMap[card.id] ?? 5; // Use cached box value
      final weight = boxWeights[box] ?? 1.0;
      if (weight > 0) {
        weightedCards.add(card);
        weights.add(weight);
        totalWeight += weight;
      }
    }

    if (weightedCards.isEmpty || totalWeight <= 0) {
      return cards;
    }

    // Select len(filtered) / 2 cards using weighted random selection with diminishing returns
    final numberOfCardsToSelect = max(3, (cards.length / 2).round());
    final selectedCards = <FlashCard>[];

    // Weighted sampling with diminishing returns without list expansion.
    for (int i = 0;
        i < numberOfCardsToSelect && weightedCards.isNotEmpty;
        i++) {
      if (totalWeight <= 0) {
        break;
      }

      final roll = random.nextDouble() * totalWeight;
      double cumulative = 0;
      int pickedIndex = -1;
      for (int index = 0; index < weights.length; index++) {
        cumulative += weights[index];
        if (roll <= cumulative) {
          pickedIndex = index;
          break;
        }
      }

      if (pickedIndex == -1) {
        break;
      }

      selectedCards.add(weightedCards[pickedIndex]);

      // Diminishing returns: reduce weight by ~1/3 each time it is selected.
      final oldWeight = weights[pickedIndex];
      final newWeight = oldWeight * 2 / 3;
      totalWeight -= (oldWeight - newWeight);
      if (newWeight <= 0.0001) {
        final lastIndex = weights.length - 1;
        if (pickedIndex != lastIndex) {
          weights[pickedIndex] = weights[lastIndex];
          weightedCards[pickedIndex] = weightedCards[lastIndex];
        }
        weights.removeLast();
        weightedCards.removeLast();
      } else {
        weights[pickedIndex] = newWeight;
      }
    }

    return selectedCards;
  }

  void clearHistory() {
    _history.clear();
  }

  void setTextFilter(String filter) {
    if (_cardTextFilter == filter) return;
    _cardTextFilter = filter;
    notifyListeners();
  }

  Future<void> loadCurrentQuizzFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? quizzName = prefs.getString('current_quizz');
    if (quizzName != null && quizzName.isNotEmpty) {
      Quizz? quizz =
          quizzListNotifier.localQuizzes.firstWhere((q) => q.name == quizzName);
      if (quizz.name.isNotEmpty) {
        await loadQuizz(quizz);
      }
    }
  }

  Future<void> loadQuizz(Quizz quizz) async {
    final String jsonContent =
        await utils.readLocalFile('$localQuizzFolder/${quizz.fileName}');
    try {
      final decoded = json.decode(jsonContent);

      final dir = await getApplicationDocumentsDirectory();
      final appDocPath = dir.path;

      String resolveLocalImagePath(String imagePath) {
        if (imagePath.isEmpty) return "";
        if (imagePath.startsWith('/') || imagePath.startsWith(appDocPath)) {
          return imagePath;
        }
        return '$appDocPath/$imagePath';
      }

      List<dynamic> list = decoded as List<dynamic>;

      final parsed = <FlashCard>[];

      for (final e in list) {
        final item = e as Map<String, dynamic>;

        // Handle image_path for private quizzes with images
        String frontImagePath = "";
        if (item.containsKey("frontImage") &&
            item["frontImage"] != null &&
            item["frontImage"].isNotEmpty &&
            quizz.imageFolder.isNotEmpty) {
          // Construct the full local path
          frontImagePath =
              '$localImageFolder/${quizz.imageFolder}/${item["frontImage"]}';
        }
        String backImagePath = "";
        if (item.containsKey("backImage") &&
            item["backImage"] != null &&
            item["backImage"].isNotEmpty &&
            quizz.imageFolder.isNotEmpty) {
          // Construct the full local path
          backImagePath =
              '$localImageFolder/${quizz.imageFolder}/${item["backImage"]}';
        }

        final rawFrontImage = frontImagePath.isNotEmpty
            ? frontImagePath
            : (item["frontImage"] ?? "");
        final rawBackImage = backImagePath.isNotEmpty
            ? backImagePath
            : (item["backImage"] ?? "");

        parsed.add(FlashCard(
            key: ValueKey(item["id"]),
            id: item["id"],
            frontTitle: item["frontTitle"] ?? "",
            frontDescription: item["frontDescription"] ?? "",
            frontImage: resolveLocalImagePath(rawFrontImage),
            backTitle: item["backTitle"] ?? "",
            backDescription: item["backDescription"] ?? "",
            backImage: resolveLocalImagePath(rawBackImage),
            tags: item["tags"] is List<dynamic>
                ? (item["tags"] as List<dynamic>).cast<String>()
                : <String>[],
            randomReverse: Random(
                    DateTime.now().millisecondsSinceEpoch + item["id"].hashCode)
                .nextBool()));
      }

      _cards = parsed;
      quizzListNotifier.currentQuizzName = quizz.name;
      tagNotifier.setAllTags(quizz.tags);
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_quizz', quizz.name);

      await utils.updateRemainingDay();
      await refreshRemainingDaysCache();
      _history.clear();
      notifyListeners();
    } catch (e) {
      print('Error loading quizz from JSON: $e');
    }
  }

  void setBoxForCard(FlashCard card, int Function(int) update,
      {isUndo = false}) {
    SharedPreferences.getInstance().then((prefs) {
      String boxKey =
          '${quizzListNotifier.currentQuizzUniqueId}_${card.id}_box';
      String remainingDaysKey =
          '${quizzListNotifier.currentQuizzUniqueId}_${card.id}_remaining_days';
      int currentBox = prefs.getInt(boxKey) ?? 5;
      int newBox;
      int remaining;
      if (!isUndo) {
        int currentRemaining = prefs.getInt(remainingDaysKey) ?? 0;
        if (_history.length >= maxHistory) {
          _history.removeAt(0);
        }
        _history.add([currentBox, currentRemaining, card.id]);
        newBox = update(currentBox).clamp(0, 5);
        remaining = utils.getRemaingDaysForBox(newBox);
      } else {
        var last = _history.removeLast();
        newBox = last[0];
        remaining = last[1];
        if (last[2] != card.id) {
          // Wrong card, there is an issue in the history ...
          _history.clear();
          return;
        }
      }
      prefs.setInt(boxKey, newBox);
      prefs.setInt(remainingDaysKey, remaining);
      _remainingDaysMap[card.id] = remaining;
      _boxMap[card.id] = newBox;
    });
  }

  void promoteCard(FlashCard card) {
    setBoxForCard(card, (box) => box - 1);
  }

  void demoteCard(FlashCard card) {
    setBoxForCard(card, (box) => box + 2);
  }

  bool undo(FlashCard card) {
    if (_history.isEmpty) {
      return false;
    }
    setBoxForCard(card, (_) => 5, isUndo: true);
    return true;
  }

  Future<void> refreshRemainingDaysCache() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _remainingDaysMap.clear();
    _boxMap.clear();

    final currentQuizzId = quizzListNotifier.currentQuizzUniqueId;
    if (currentQuizzId.isEmpty) return;

    for (final card in _cards) {
      final remainingDaysKey = '${currentQuizzId}_${card.id}_remaining_days';
      final boxKey = '${currentQuizzId}_${card.id}_box';
      final remainingVal = prefs.getInt(remainingDaysKey);
      final boxVal = prefs.getInt(boxKey);

      if (remainingVal != null) {
        _remainingDaysMap[card.id] = remainingVal;
      }
      if (boxVal != null) {
        _boxMap[card.id] = boxVal;
      } else {
        _boxMap[card.id] = 5; // default box
      }
    }
  }
}
