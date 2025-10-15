import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'card.dart';
import 'quizz.dart';
import 'utils.dart' as utils;
import 'main.dart';
import 'constants.dart';


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
  String _currentQuizzName = "";

  List<FlashCard> get cards => List.unmodifiable(_cards);
  String get currentQuizzName => _currentQuizzName;
  int get nbCard => _cards.length;

  void loadCurrentQuizzFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? quizzName = prefs.getString('current_quizz');
    if (quizzName != null && quizzName.isNotEmpty) {
      Quizz? quizz = quizzListNotifier.localQuizzes.firstWhere((q) => q.name == quizzName);
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
      _currentQuizzName = quizz.name;
      tagNotifier.setAllTags(quizz.tags);
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_quizz', quizz.name);
      notifyListeners();
    } catch (e) {
      print('Error loading quizz from JSON: $e');
    }
  }
}