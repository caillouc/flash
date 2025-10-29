
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsNotifier extends ChangeNotifier {
  bool _apprentissage = true;
  bool _reverseCardOrientation = false;
  bool _mixCardOrientation = false;
  bool _privateMode = false;

  bool get apprentissage => _apprentissage;
  bool get reverseCardOrientation => _reverseCardOrientation;
  bool get mixCardOrientation => _mixCardOrientation;
  bool get privateMode => _privateMode;

  void init() {
    SharedPreferences.getInstance().then((prefs) {
      _apprentissage = prefs.getBool('apprentissage_mode') ?? _apprentissage;
      _reverseCardOrientation = prefs.getBool("reverseCardOrientation") ?? _reverseCardOrientation;
      _mixCardOrientation = prefs.getBool("mixCardOrientation") ?? _mixCardOrientation;
      _privateMode = prefs.getBool('private_mode') ?? _privateMode;
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

  set privateMode(bool v) {
    if (_privateMode == v) return;
    _privateMode = v;
    // persist
    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool('private_mode', v);
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

  set mixCardOrientation(bool v) {
    if (_mixCardOrientation == v) return;
    _mixCardOrientation = v;
    // persist
    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool('mixCardOrientation', v);
    });
    notifyListeners();
  }
}