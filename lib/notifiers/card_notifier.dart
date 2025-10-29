import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../card.dart';
import '../quizz.dart';
import '../utils.dart' as utils;
import '../main.dart';
import '../constants.dart';

class CardNotifier extends ChangeNotifier {
  final List<FlashCard> _noLocalQuizzCards = [
    const FlashCard(
        key: ValueKey('placeholder_1'),
        frontTitle: "Téléchargez un quiz pour commencer"),
    const FlashCard(
        key: ValueKey('placeholder_2'),
        frontTitle:
            "Naviguez dans le menu en haut à gauche et sélectionnez vos quizz"),
    const FlashCard(
        key: ValueKey('placeholder_3'),
        frontTitle:
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
    notifyListeners();
  }

  List<FlashCard> filteredCards({bool inListView = false}) {
    List<FlashCard> filteredCards = List.from(cards);
    if (tagNotifier.hasSelectedTags) {
      filteredCards = filteredCards
          .where(
              (card) => card.tags.any((tag) => tagNotifier.isTagSelected(tag)))
          .toList();
    }
    if (_cardTextFilter.isNotEmpty) {
      filteredCards = filteredCards.where((card) {
        final lowerFilter = _cardTextFilter.toLowerCase();
        return card.frontTitle.toLowerCase().contains(lowerFilter) ||
            card.frontDescription.toLowerCase().contains(lowerFilter) ||
            card.backTitle.toLowerCase().contains(lowerFilter) ||
            card.backDescription.toLowerCase().contains(lowerFilter);
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
    if (!inListView && quizzListNotifier.currentQuizzName.isNotEmpty) {
      filteredCards.shuffle();
    }
    return filteredCards;
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

    // Create weighted list - each card appears multiple times based on its weight
    final List<FlashCard> weightedCards = [];
    for (final card in cards) {
      final box = _boxMap[card.id] ?? 5; // Use cached box value
      final weight = boxWeights[box] ?? 1.0;
      // Convert percentage to count (multiply by 10 for better precision)
      final count = (weight * 10).round();
      for (int i = 0; i < count; i++) {
        weightedCards.add(card);
      }
    }

    if (weightedCards.isEmpty) {
      return cards;
    }

    // Select len(filtered) / 2 cards using weighted random selection with diminishing returns
    final numberOfCardsToSelect = (cards.length / 2).round();
    final selectedCards = <FlashCard>[];
    final selectionCounts = <String, int>{}; // Track how many times each card was selected
    
    // Create a dynamic weighted list that gets modified as we select cards
    final dynamicWeightedCards = List<FlashCard>.from(weightedCards);
    
    for (int i = 0; i < numberOfCardsToSelect && dynamicWeightedCards.isNotEmpty; i++) {
      // Select a random card
      final randomIndex = random.nextInt(dynamicWeightedCards.length);
      final selectedCard = dynamicWeightedCards[randomIndex];
      selectedCards.add(selectedCard);
      
      // Increment selection count
      selectionCounts[selectedCard.id] = (selectionCounts[selectedCard.id] ?? 0) + 1;
      
      // Reduce the card's presence in the weighted list (remove half of its occurrences)
      final cardOccurrences = dynamicWeightedCards.where((card) => card.id == selectedCard.id).length;
      final toRemove = (cardOccurrences / 3).round();
      
      int removed = 0;
      dynamicWeightedCards.removeWhere((card) {
        if (card.id == selectedCard.id && removed < toRemove) {
          removed++;
          return true;
        }
        return false;
      });
    }
    
    return selectedCards;
  }

  void clearHistory() {
    _history.clear();
  }

  void setTextFilter(String filter) {
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

        parsed.add(FlashCard(
            key: ValueKey(item["id"]),
            id: item["id"],
            frontTitle: item["frontTitle"] ?? "",
            frontDescription: item["frontDescription"] ?? "",
            frontImage: frontImagePath.isNotEmpty
                ? frontImagePath
                : (item["frontImage"] ?? ""),
            backTitle: item["backTitle"] ?? "",
            backDescription: item["backDescription"] ?? "",
            backImage: backImagePath.isNotEmpty
                ? backImagePath
                : (item["backImage"] ?? ""),
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
        _history.add([currentBox, currentRemaining]);
        newBox = update(currentBox).clamp(0, 5);
        remaining = utils.getRemaingDaysForBox(newBox);
      } else {
        var last = _history.removeLast();
        newBox = last[0];
        remaining = last[1];
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
    
    for (final card in _cards) {
      final remainingDaysKey =
          '${quizzListNotifier.currentQuizzUniqueId}_${card.id}_remaining_days';
      final boxKey = '${quizzListNotifier.currentQuizzUniqueId}_${card.id}_box';
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
