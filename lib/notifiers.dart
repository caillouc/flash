import 'dart:convert';
import 'dart:io';

import 'package:flash/card.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'quizz.dart';

class CurrentQuizzNotifier extends ChangeNotifier {
  List<FlashCard> _cards = [];
}

class QuizzesNotifier extends ChangeNotifier {
  List<Quizz> _quizzes = [];

  // URL to fetch the quizzes list JSON
  static const String _remoteUrl =
      'https://raw.githubusercontent.com/caillouc/flash/refs/heads/refactoring/resource/quizzesList.json';

  // SharedPreferences key for the saved version (etag or timestamp)
  static const String _prefsVersionKey = 'quizzes_list_version';

  // filename used to save the quizzes list locally
  static const String _localFileName = 'quizzesList.json';

  List<Quizz> get quizzes => List.unmodifiable(_quizzes);

  Future<void> loadQuizzesFromLocalFile() async {
    try {
      final file = await _localFile;
      if (await file.exists()) {
        final contents = await file.readAsString();
        _loadQuizzesFromJson(contents);
        notifyListeners();
      }
    } catch (e) {
      // ignore and leave quizzes empty
    }
  }

  Future<void> fetchAndSaveQuizzes() async {
    try {
      final resp = await http.get(Uri.parse(_remoteUrl));
      if (resp.statusCode == 200) {
        final body = resp.body;
        // save file
        final file = await _localFile;
        await file.writeAsString(body);
        String version = _loadQuizzesFromJson(body);
        print("Fetched quizzes list, version: $version");
        if (version.isNotEmpty) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_prefsVersionKey, version);
        }
        notifyListeners();
        return;
      }
    } catch (e) {
      // TODO: popup error message
    }
  }

  Future<File> get _localFile async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_localFileName');
  }

  String _loadQuizzesFromJson(String jsonStr) {
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
