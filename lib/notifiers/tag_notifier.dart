import 'package:flutter/material.dart';

class TagNotifier extends ChangeNotifier {
  List<String> _allTags = [];
  final List<String> _selectedTags = [];

  List<String> get allTags {
    if (_allTags.isEmpty) return [];

    // Build a list of tags excluding 'Tout', sorted alphabetically (case-insensitive)
    final others = _allTags.where((t) => t != 'Tout').toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    // Selected tags (excluding 'Tout'), then the remaining tags
    final selected = others.where((t) => _selectedTags.contains(t)).toList();
    final notSelected = others.where((t) => !_selectedTags.contains(t)).toList();

    return ['Tout', ...selected, ...notSelected];
  }

  bool get hasSelectedTags {
    return _selectedTags.isNotEmpty && !(_selectedTags.length == 1 && _selectedTags.contains("Tout"));
  }

  bool isTagSelected(String tag) {
    return _selectedTags.contains(tag);
  }

  void setAllTags(List<String> tags) {
    if (tags.isNotEmpty) {
      tags = ["Tout", ...tags];
    }
    _allTags = tags.toSet().toList();
    clearTags();
  }

  void toggleTag(String tag) {
    if (_selectedTags.contains(tag)) {
      _selectedTags.remove(tag);
    } else {
      _selectedTags.add(tag);
      _selectedTags.remove("Tout");
    }
    if (_selectedTags.isEmpty) {
      _selectedTags.add("Tout");
    }
    notifyListeners();
  }

  void clearTags({bool noRefresh = false}) {
    _selectedTags.clear();
    _selectedTags.add("Tout");
    notifyListeners();
  }
}