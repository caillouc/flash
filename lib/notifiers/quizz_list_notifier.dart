import 'dart:convert';

import 'package:flutter/material.dart';

import '../quizz.dart';
import '../utils.dart' as utils;
import '../constants.dart';

class QuizzListNotifier extends ChangeNotifier {
  List<Quizz> _localQuizzes = [];
  List<Quizz> _onlineQuizzes = [];

  String _currentQuizzName = "";
  String _currentQuizzUniqueId = "";

  final List<Quizz> _updateAvailable = [];

  String get currentQuizzName => _currentQuizzName;
  String get currentQuizzUniqueId => _currentQuizzUniqueId;
  List<Quizz> get localQuizzes {
    final sortedLocal = List<Quizz>.from(_localQuizzes);
    sortedLocal.sort((a, b) => a.name.compareTo(b.name));
    return sortedLocal;
  }

  set currentQuizzName(String name) {
    _currentQuizzName = name;
    _currentQuizzUniqueId = utils.computeSha1(_localQuizzes.firstWhere((q) => q.name == name).fileName);
    notifyListeners();
  }

  List<Quizz> get allQuizzes {
    // Create a sorted list of local quizzes.
    final sortedLocal = List<Quizz>.from(_localQuizzes);
    sortedLocal.sort((a, b) => a.name.compareTo(b.name));

    // Create a set of local quiz file names for efficient lookup.
    final localFileNames = _localQuizzes.map((q) => q.fileName).toSet();

    // Filter online quizzes to get only those not present locally, then sort them.
    final sortedOnlineOnly = _onlineQuizzes
        .where((q) => !localFileNames.contains(q.fileName))
        .toList();
    sortedOnlineOnly.sort((a, b) => a.name.compareTo(b.name));

    // Combine the two lists.
    final merged = [...sortedLocal, ...sortedOnlineOnly];

    return List.unmodifiable(merged);
  }

  bool isLocalQuizz(Quizz quizz) {
    return _localQuizzes.any((q) => q.fileName == quizz.fileName);
  }

  bool isUpdateAvailable(Quizz quizz) {
    return _updateAvailable.any((q) => q.fileName == quizz.fileName);
  }

  void updateQuizz(Quizz quizz) {
    removeLocalQuizz(quizz, skipReload: true);
    Quizz upToDateQuizz = _onlineQuizzes.firstWhere((q) => q.fileName == quizz.fileName);
    _updateAvailable.removeWhere((q) => q.fileName == quizz.fileName);
    addLocalQuizz(upToDateQuizz);
  }

  void removeLocalQuizz(Quizz quizz, {bool skipReload = false}) async {
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
    if (!skipReload) {
      notifyListeners();
    }
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
        print("${quizz.name} added");
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

  Future<void> fetchAndSaveOnlineQuizzList() async {
    await utils
        .fetchAndSaveFile(remoteQuizzListUrl, quizzListServerFileName)
        .then((jsonContent) {
      if (jsonContent.isNotEmpty) {
        _onlineQuizzes = _loadQuizzListFromJson(jsonContent);
        notifyListeners();
      }
    });
  }

  void checkNewVersion() {
    for (Quizz local in _localQuizzes) {
      if (_onlineQuizzes.any((q) => q.fileName == local.fileName)) {
        Quizz? online = _onlineQuizzes.firstWhere((q) => q.fileName == local.fileName);
        if (online.version != local.version) {
          print("Update available for ${local.name}");
          _updateAvailable.add(local);
        }
      }
    }
    notifyListeners();
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
