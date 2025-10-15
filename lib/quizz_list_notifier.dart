import 'dart:convert';

import 'package:flutter/material.dart';

import 'quizz.dart';
import 'utils.dart' as utils;
import 'constants.dart';

class QuizzListNotifier extends ChangeNotifier {
  List<Quizz> _localQuizzes = [];
  List<Quizz> _onlineQuizzes = [];

  List<Quizz> get localQuizzes => List.unmodifiable(_localQuizzes);

  /// Returns the merged list of quizzes (no duplicates). If a quiz exists both
  /// locally and online, the local version is returned.
  List<Quizz> get allQuizzes {
    // Start with local quizzes (preferred)
    final merged = <Quizz>[];
    final seen = <String>{}; // track fileName keys

    for (final q in _localQuizzes) {
      merged.add(q);
      seen.add(q.fileName);
    }

    // Add online quizzes that are not present locally
    for (final q in _onlineQuizzes) {
      if (!seen.contains(q.fileName)) {
        merged.add(q);
        seen.add(q.fileName);
      }
    }

    return List.unmodifiable(merged);
  }

  bool isLocalQuizz(Quizz quizz) {
    return _localQuizzes.any((q) => q.fileName == quizz.fileName);
  }

  void removeLocalQuizz(Quizz quizz) async {
    print("Removing local quizz: ${quizz.name}");
    _localQuizzes.removeWhere((q) => q.fileName == quizz.fileName);
    utils.deleteLocalFile(localQuizzFolder + quizz.fileName);
    try {
      String localListContent =
          await utils.readLocalFile(localQuizzListFileName);
      if (localListContent.isNotEmpty) {
        Map<String, dynamic> root =
            json.decode(localListContent) as Map<String, dynamic>;
        if (root.containsKey('quizzes')) {
          List<dynamic> quizzList = root['quizzes'] as List<dynamic>;
          quizzList.removeWhere((item) {
            final map = item as Map<String, dynamic>;
            return map['file_name'] == quizz.fileName;
          });
          final newContent = json.encode(root);
          await utils.writeLocalFile(localQuizzListFileName, newContent);
        }
      }
    } catch (e) {
      print('Error updating local quizzes list after removal: $e');
    }
    notifyListeners();
  }

  void addLocalQuizz(Quizz quizz) async {
    if (!_localQuizzes.any((q) => q.fileName == quizz.fileName)) {
      String _ = await utils.fetchAndSaveFile(
          remoteQuizzBaseUrl + quizz.fileName,
          localQuizzFolder + quizz.fileName);
      try {
        // read existing local quizzes list
        String localListContent =
            await utils.readLocalFile(localQuizzListFileName);
        Map<String, dynamic> root;
        if (localListContent.isEmpty) {
          // create basic structure
          root = {'quizzes': []};
        } else {
          root = json.decode(localListContent) as Map<String, dynamic>;
        }

        // append and save
        List quizzList = root['quizzes'] as List<dynamic>;
        quizzList.add(quizz.toMap());
        final newContent = json.encode(root);
        await utils.writeLocalFile(localQuizzListFileName, newContent);
        _localQuizzes.add(quizz);
      } catch (e) {
        print('Error updating local quizzes list: $e');
      }
      notifyListeners();
    }
  }

  Future<void> loadLocalQuizzList() async {
    String jsonContent = await utils.readLocalFile(localQuizzListFileName);
    if (jsonContent.isNotEmpty) {
      _localQuizzes = _loadQuizzListFromJson(jsonContent);
      notifyListeners();
    }
  }

  void fetchAndSaveOnlineQuizzList() async {
    utils
        .fetchAndSaveFile(remoteQuizzListUrl, quizzListServerFileName)
        .then((jsonContent) {
      if (jsonContent.isNotEmpty) {
        _onlineQuizzes = _loadQuizzListFromJson(jsonContent);
        notifyListeners();
      }
    });
  }

  List<Quizz> _loadQuizzListFromJson(String jsonListStr) {
    try {
      final decoded = json.decode(jsonListStr);

      Map<String, dynamic>? root = decoded as Map<String, dynamic>?;

      if (root == null ||
          root.isEmpty ||
          !root.containsKey('quizzes') ||
          root['quizzes'].isEmpty) {
        return [];
      }

      List<Quizz> ret = root["quizzes"].map<Quizz>((e) {
        final item = e as Map<String, dynamic>;
        return Quizz.fromJson(item);
      }).toList();
      return ret;
    } catch (e) {
      print("Error loading quizzes List from JSON: $e");
      return [];
    }
  }
}
