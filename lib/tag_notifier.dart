import 'package:flutter/material.dart';

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
    notifyListeners();
  }

  void clearTags() {
    _selectedTags.clear();
    notifyListeners();
  }
}