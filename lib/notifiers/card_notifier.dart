import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../card.dart';
import '../quizz.dart';
import '../utils.dart' as utils;
import '../main.dart';
import '../constants.dart';

class CardNotifier extends ChangeNotifier {
  List<FlashCard> _cards = [
    const FlashCard(frontTitle: "Téléchargez un quiz pour commencer"),
    const FlashCard(
        frontTitle:
            "Naviguez dans le menu en haut à gauche et sélectionnez vos quizz"),
    const FlashCard(
        frontTitle:
            "Vous pourrez ensuite réviser les cartes dans cette section"),
  ];
  String _cardTextFilter = "";
  // in-memory cache of remaining days per card id
  final Map<String, int> _remainingDaysMap = {};
  final List _history = [];

  List<FlashCard> get cards => List.unmodifiable(_cards);
  int get nbCard => _cards.length;

  List<FlashCard> filteredCards({bool inListView = false}) {
    List<FlashCard> filterdCards = cards;
    if (tagNotifier.hasSelectedTags) {
      filterdCards = filterdCards
          .where(
              (card) => card.tags.any((tag) => tagNotifier.isTagSelected(tag)))
          .toList();
    }
    if (_cardTextFilter.isNotEmpty) {
      filterdCards = filterdCards.where((card) {
        final lowerFilter = _cardTextFilter.toLowerCase();
        return card.frontTitle.toLowerCase().contains(lowerFilter) ||
            card.frontDescription.toLowerCase().contains(lowerFilter) ||
            card.backTitle.toLowerCase().contains(lowerFilter) ||
            card.backDescription.toLowerCase().contains(lowerFilter);
      }).toList();
    }
    // If apprentissage mode is enabled, only keep cards with remaining_days == 0
    if (settingsNotifier.apprentissage && !inListView) {
      filterdCards = filterdCards.where((card) {
        final remaining = _remainingDaysMap[card.id] ?? 0;
        return remaining <= 0;
      }).toList();
    }
    if (!inListView && quizzListNotifier.currentQuizzName.isNotEmpty) {
      filterdCards.shuffle();
    }
    return filterdCards;
  }

  void clearHistory() {
    _history.clear();
  }

  void setTextFilter(String filter) {
    _cardTextFilter = filter;
    notifyListeners();
  }

  void loadCurrentQuizzFromPrefs() async {
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
        await utils.readLocalFile(localQuizzFolder + quizz.fileName);
    try {
      final decoded = json.decode(jsonContent);

      List<dynamic> list = decoded as List<dynamic>;

      final parsed = <FlashCard>[];

      for (final e in list) {
        final item = e as Map<String, dynamic>;

          parsed.add(FlashCard(
          id: item["id"],
          frontTitle: item["frontTitle"] ?? "",
          frontDescription: item["frontDescription"] ?? "",
          frontImage: item["frontImage"] ?? "",
          backTitle: item["backTitle"] ?? "",
          backDescription: item["backDescription"] ?? "",
          backImage: item["backImage"] ?? "",
          tags: item["tags"] is List<dynamic>
              ? (item["tags"] as List<dynamic>).cast<String>()
              : <String>[],
        ));
      }

      _cards = parsed;
      quizzListNotifier.currentQuizzName = quizz.name;
      tagNotifier.setAllTags(quizz.tags);
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_quizz', quizz.name);

      // Load remaining days for each card into memory if present
      _remainingDaysMap.clear();
      for (final c in _cards) {
        final remainingDaysKey = '${quizzListNotifier.currentQuizzUniqueId}_${c.id}_remaining_days';
        final val = prefs.getInt(remainingDaysKey);
        if (val != null) {
          _remainingDaysMap[c.id] = val;
        } 
      }

      _history.clear();
      utils.updateRemainingDay();
      notifyListeners();
    } catch (e) {
      print('Error loading quizz from JSON: $e');
    }
  }

  void setBoxForCard(FlashCard card, int Function(int) update, {isUndo = false}) {
    SharedPreferences.getInstance().then((prefs) {
      String boxKey = '${quizzListNotifier.currentQuizzUniqueId}_${card.id}_box';
      String remainingDaysKey = '${quizzListNotifier.currentQuizzUniqueId}_${card.id}_remaining_days';
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
    });
  }

  void promoteCard(FlashCard card) {
    setBoxForCard(card, (box) => box - 1);
  }

  void demoteCard(FlashCard card) {
    setBoxForCard(card, (box) => box + 2);
  }

  bool undo(FlashCard card) {
    if (_history.isEmpty) {return false;}
    if (settingsNotifier.apprentissage) {
      setBoxForCard(card, (_) => 5, isUndo: true);
    }
    return true;
  }


}
