import 'dart:convert';

import 'package:flash/card.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'quizz.dart';
import 'utils.dart' as utils;

class CurrentQuizzNotifier extends ChangeNotifier {
  List<FlashCard> _cards = [];

  Future<void> loadQuizz(Quizz quizz) async {
    final String jsonContent = await utils.readLocalFile(quizz.fileName);
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
      notifyListeners();
    } catch (e) {
      print('Error loading quizz from JSON: $e');
      _cards = [];
      notifyListeners();
    }
  }
}

class QuizzesNotifier extends ChangeNotifier {
  List<Quizz> _quizzes = [];
  List<String> _localQuizzesName = [];

  // URL to fetch the quizzes list JSON
  static const String _remoteQuizzListUrl =
      'https://raw.githubusercontent.com/caillouc/flash-quizzes/refs/heads/main/quizzesList.json';
  static const String _remoteQuizzBaseUrl =
      'https://raw.githubusercontent.com/caillouc/flash-quizzes/refs/heads/main/quizzes/';
  static const String _prefsVersionKey = 'quizzes_list_version';
  static const String _localQuizzListFileName = 'quizzesList.json';
  static const String _localQuizzFolder =
      'quizzes/'; // directory to save quizzes

  List<Quizz> get allQuizzes => List.unmodifiable(_quizzes);
  List<Quizz> get localQuizzes =>
      _quizzes.where((q) => _localQuizzesName.contains(q.name)).toList();

  bool isLocalQuizz(Quizz quizz) => _localQuizzesName.contains(quizz.name);
  void removeLocalQuizz(Quizz quizz) {
    _localQuizzesName.remove(quizz.name);
    utils.deleteLocalFile(_localQuizzFolder + quizz.fileName);
    notifyListeners();
  }

  void addLocalQuizz(Quizz quizz) async {
    if (!_localQuizzesName.contains(quizz.name)) {
      String _ = await utils.fetchAndSaveFile(
          _remoteQuizzBaseUrl + quizz.fileName,
          _localQuizzFolder + quizz.fileName);
      _localQuizzesName.add(quizz.name);
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

class StateNotifier extends ChangeNotifier {
  String _currentQuizzName = "";

  String get currentQuizzName => _currentQuizzName;
}
