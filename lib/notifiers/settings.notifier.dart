
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsNotifier extends ChangeNotifier {
  bool _apprentissage = true;
  bool _reverseCardOrientation = false;

  bool get apprentissage => _apprentissage;
  bool get reverseCardOrientation => _reverseCardOrientation;

  void init() {
    SharedPreferences.getInstance().then((prefs) {
      _apprentissage = prefs.getBool('apprentissage_mode') ?? _apprentissage;
      _reverseCardOrientation = prefs.getBool("reverseCardOrientation") ?? _reverseCardOrientation;
    });
  }

  set apprentissage(bool v) {
    if (_apprentissage == v) return;
    _apprentissage = v;
    // persist
    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool('apprentissage_mode', v);
    });
    notifyListeners();
  }

  set reverseCardOrientation(bool v) {
    if (_reverseCardOrientation == v) return;
    _reverseCardOrientation = v;
    // persist
    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool('reverseCardOrientation', v);
    });
    notifyListeners();
  }
}