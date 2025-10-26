import 'dart:convert';

import 'package:flash/main.dart';
import 'package:flutter/material.dart';

import '../quizz.dart';
import '../utils.dart' as utils;
import '../constants.dart';

class QuizzListNotifier extends ChangeNotifier {
  List<Quizz> _localQuizzes = [];
  List<Quizz> _onlineQuizzes = [];
  List<Quizz> _privateQuizzes = [];
  String? _downloadingQuizzFileName; // Track which quiz is being downloaded

  String _currentQuizzName = "";
  String _currentQuizzUniqueId = "";

  final List<Quizz> _updateAvailable = [];

  String get currentQuizzName => _currentQuizzName;
  String get currentQuizzUniqueId => _currentQuizzUniqueId;
  String? get downloadingQuizzFileName => _downloadingQuizzFileName;
  List<Quizz> get localQuizzes {
    final sortedLocal = List<Quizz>.from(_localQuizzes);
    sortedLocal.sort((a, b) => a.name.compareTo(b.name));
    return sortedLocal;
  }

  set currentQuizzName(String name) {
    _currentQuizzName = name;
    if (name.isEmpty) {
      _currentQuizzUniqueId = "";
    } else {
      _currentQuizzUniqueId = utils.computeSha1(_localQuizzes.firstWhere((q) => q.name == name).fileName);
    }
    notifyListeners();
  }

  List<Quizz> get allQuizzes {
    // Create a sorted list of local quizzes.
    final sortedLocal = List<Quizz>.from(_localQuizzes);
    sortedLocal.sort((a, b) => a.name.compareTo(b.name));

    // Create a set of local quiz file names for efficient lookup.
    final localFileNames = _localQuizzes.map((q) => q.fileName).toSet();

    // Determine which online list to use based on mode
    final onlineList = _privateQuizzes + _onlineQuizzes;

    // Filter online quizzes to get only those not present locally, then sort them.
    final sortedOnlineOnly = onlineList
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
    removeLocalQuizz(quizz, skipReload: true, isUpdate: true);
    // Check if it's a private quiz or online quiz
    Quizz? upToDateQuizz;
    if (_privateQuizzes.any((q) => q.fileName == quizz.fileName)) {
      upToDateQuizz = _privateQuizzes.firstWhere((q) => q.fileName == quizz.fileName);
    } else {
      upToDateQuizz = _onlineQuizzes.firstWhere((q) => q.fileName == quizz.fileName);
    }
    _updateAvailable.removeWhere((q) => q.fileName == quizz.fileName);
    addLocalQuizz(upToDateQuizz);
  }

  void removeLocalQuizz(Quizz quizz, {bool skipReload = false, bool isUpdate = false}) async {
    _localQuizzes.removeWhere((q) => q.fileName == quizz.fileName);
    utils.deleteLocalFile('$localQuizzFolder/${quizz.fileName}');
    
    // Delete associated images if the quiz has an image folder
    if (quizz.imageFolder.isNotEmpty) {
      await utils.deleteLocalDirectory('$localImageFolder/${quizz.imageFolder}');
    }
    
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
    if (quizzListNotifier._currentQuizzName == quizz.name && !isUpdate) {
      if (_localQuizzes.isEmpty) {
        cardNotifier.setNoLocalQuizz();
      } else {
        cardNotifier.loadQuizz(_localQuizzes.first);
      }
    }

    if (!skipReload) {
      notifyListeners();
    }
  }

  void addLocalQuizz(Quizz quizz) async {
    if (!_localQuizzes.any((q) => q.fileName == quizz.fileName)) {
        _localQuizzes.add(quizz);
      // Set downloading state
      _downloadingQuizzFileName = quizz.fileName;
      notifyListeners();
      
      // Determine the base URL based on whether the quiz is from private list
      final isPrivateQuizz = _privateQuizzes.any((q) => q.fileName == quizz.fileName);
      final baseUrl = isPrivateQuizz ? privateQuizzBaseUrl : remoteQuizzBaseUrl;
      
      String quizzContent = await utils.fetchAndSaveFile(
          baseUrl + quizz.fileName,
          '$localQuizzFolder/${quizz.fileName}');
      
      // If quiz has an image folder, download all images from the cards
      if (quizz.imageFolder.isNotEmpty && quizzContent.isNotEmpty) {
        await _downloadQuizzImages(quizz.imageFolder, quizzContent);
      }
      
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
      } catch (e) {
        print('Error updating local quizzes list: $e');
      }
      
      // Clear downloading state
      _downloadingQuizzFileName = null;
      notifyListeners();
    }
  }

  Future<void> _downloadQuizzImages(String imageFolder, String quizzContent) async {
    try {
      final decoded = json.decode(quizzContent);
      List<dynamic> cards = decoded as List<dynamic>;
      
      // Collect all unique image paths from cards
      Set<String> imagePaths = {};
      for (final card in cards) {
        final cardMap = card as Map<String, dynamic>;
        for (final key in ['frontImage', 'backImage']) {
          if (cardMap.containsKey(key) && cardMap[key] != null) {
            final imagePath = cardMap[key] as String;
            if (imagePath.isNotEmpty) {
              imagePaths.add(imagePath);
            }
          }
        }
      }
      
      // Download each unique image
      for (final imagePath in imagePaths) {
        final imageUrl = '$privateImageBaseUrl$imageFolder/$imagePath';
        final localPath = '$localImageFolder/$imageFolder/$imagePath';
        await utils.fetchAndSaveBinaryFile(imageUrl, localPath);
      }
    } catch (e) {
      print('Error downloading quiz images: $e');
    }
  }

  Future<void> loadLocalQuizzList() async {
    String jsonContent = await utils.readLocalFile(localQuizzListFileName);
    if (jsonContent.isNotEmpty) {
      _localQuizzes = _loadQuizzListFromJson(jsonContent);
      notifyListeners();
    } else {
      cardNotifier.setNoLocalQuizz();
    }
  }

  Future<void> loadPrivateQuizzListIfExists() async {
    // Try to load private quiz list if it was previously fetched
    String jsonContent = await utils.readLocalFile(privateQuizzListFileName);
    if (jsonContent.isNotEmpty) {
      _privateQuizzes = _loadQuizzListFromJson(jsonContent);
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

  Future<void> enablePrivateMode() async {
    // Fetch private quiz list
    await utils
        .fetchAndSaveFile(privateQuizzListUrl, privateQuizzListFileName)
        .then((jsonContent) {
      if (jsonContent.isNotEmpty) {
        _privateQuizzes = _loadQuizzListFromJson(jsonContent);
        notifyListeners();
      }
    });
  }

  void checkNewVersion() {
    for (Quizz local in _localQuizzes) {
      // Check in online quizzes
      if (_onlineQuizzes.any((q) => q.fileName == local.fileName)) {
        Quizz? online = _onlineQuizzes.firstWhere((q) => q.fileName == local.fileName);
        if (online.version != local.version) {
          _updateAvailable.add(local);
        }
      }
      // Also check in private quizzes
      else if (_privateQuizzes.any((q) => q.fileName == local.fileName)) {
        Quizz? private = _privateQuizzes.firstWhere((q) => q.fileName == local.fileName);
        if (private.version != local.version) {
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
