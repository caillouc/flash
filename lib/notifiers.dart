import 'dart:convert';

import 'package:flash/card.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'quizz.dart';
import 'utils.dart' as utils;
import 'main.dart';

const String _remoteQuizzListUrl =
    'https://raw.githubusercontent.com/caillouc/flash-quizzes/refs/heads/main/quizzesList.json';
const String _remoteQuizzBaseUrl =
    'https://raw.githubusercontent.com/caillouc/flash-quizzes/refs/heads/main/quizzes/';
const String _prefsVersionKey = 'quizzes_list_version';
const String _localQuizzListFileName = 'quizzesList.json';
const String _localQuizzFolder = 'quizzes/'; // directory to save quizzes

class TagNotifier extends ChangeNotifier {
  List<String> _allTags = [];
  final List<String> _selectedTags = [];

  List<String> get allTags => List.unmodifiable(_allTags);
  List<String> get selectedTags => List.unmodifiable(_selectedTags);

  void setAllTags(List<String> tags) {
    if (tags.isNotEmpty) {
      tags = ["Tout", ...tags];
    }
    _allTags = tags.toSet().toList();
    notifyListeners();
  }

  void toggleTag(String tag) {
    if (_selectedTags.contains(tag)) {
      _selectedTags.remove(tag);
    } else {
      _selectedTags.add(tag);
    }
    print(_selectedTags);
    notifyListeners();
  }

  void clearTags() {
    _selectedTags.clear();
    notifyListeners();
  }
}

class CurrentQuizzNotifier extends ChangeNotifier {
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

  CurrentQuizzNotifier() {
    SharedPreferences.getInstance().then((prefs) {
      String? savedQuizz = prefs.getString('current_quizz');
      print("Saved quizz: $savedQuizz");
      if (savedQuizz != null && savedQuizz.isNotEmpty) {
        Quizz? quizz = quizzListNotifier.localQuizzes
            .firstWhere((q) => q.name == savedQuizz);
        loadQuizz(quizz);
      }
    });
  }

  List<FlashCard> get cards => List.unmodifiable(_cards);
  String get currentQuizzName => _currentQuizzName;
  int get nbCard => _cards.length;

  Future<void> loadQuizz(Quizz quizz) async {
    final String jsonContent =
        await utils.readLocalFile(_localQuizzFolder + quizz.fileName);
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

class QuizzListNotifier extends ChangeNotifier {
  List<Quizz> _quizzes = [];
  List<String> _localQuizzesName = [];

  QuizzListNotifier() {
    SharedPreferences.getInstance().then((prefs) {
      _localQuizzesName = prefs.getStringList('local_quizzes') ?? [];
      fetchAndSaveQuizzList();
      loadQuizzListFromLocalFile();
    });
  }

  List<Quizz> get allQuizzes => List.unmodifiable(_quizzes);
  List<Quizz> get localQuizzes =>
      _quizzes.where((q) => _localQuizzesName.contains(q.name)).toList();

  bool isLocalQuizz(Quizz quizz) => _localQuizzesName.contains(quizz.name);
  void removeLocalQuizz(Quizz quizz) {
    _localQuizzesName.remove(quizz.name);
    utils.deleteLocalFile(_localQuizzFolder + quizz.fileName);
    SharedPreferences.getInstance().then((prefs) {
      prefs.setStringList('local_quizzes', _localQuizzesName);
      prefs.remove('${quizz.name}_version');
    });
    notifyListeners();
  }

  void addLocalQuizz(Quizz quizz) async {
    if (!_localQuizzesName.contains(quizz.name)) {
      String _ = await utils.fetchAndSaveFile(
          _remoteQuizzBaseUrl + quizz.fileName,
          _localQuizzFolder + quizz.fileName);
      _localQuizzesName.add(quizz.name);
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('local_quizzes', _localQuizzesName);
      await prefs.setString('${quizz.name}_version', quizz.version);
      notifyListeners();
    }
  }

  void loadQuizzListFromLocalFile() async {
    String jsonContent = await utils.readLocalFile(_localQuizzListFileName);
    _loadQuizzListFromJson(jsonContent);
    notifyListeners();
  }

  void fetchAndSaveQuizzList() async {
    String jsonContent = await utils.fetchAndSaveFile(
        _remoteQuizzListUrl, _localQuizzListFileName);
    if (jsonContent.isNotEmpty) {
      String version = _loadQuizzListFromJson(jsonContent);
      if (version.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_prefsVersionKey, version);
      }
      notifyListeners();
    }
  }

  String _loadQuizzListFromJson(String jsonStr) {
    try {
      final decoded = json.decode(jsonStr);

      String version = '';
      List<dynamic>? list;

      version = decoded['version']?.toString() ?? '';
      list = decoded['quizzes'] as List<dynamic>?;

      if (list == null) {
        _quizzes = [];
        return version;
      }

      _quizzes = list.map((e) {
        final item = e as Map<String, dynamic>;
        return Quizz(
          name: item["name"], // mandatory field
          tags: item["tags"] is List<dynamic>
              ? (item["tags"] as List<dynamic>).cast<String>()
              : <String>[],
          icon: item["icon"] ?? "0xe877",
          fileName: item["file_name"], // mandatory field
          version: item["version"], // mandatory field
        );
      }).toList();

      return version;
    } catch (e) {
      print("Error loading quizzes from JSON: $e");
      _quizzes = [];
      return '';
    }
  }
}
