import 'package:flash/card.dart';
import 'package:flutter/material.dart';

import 'quizz.dart';

class CurrentQuizzNotifier extends ChangeNotifier {
  List<FlashCard> _cards = [];
}

class QuizzesNotifier extends ChangeNotifier {
  List<Quizz> _quizzes = [];

  void FetchQuizzes() {
    
  }
}

class StateNotifier extends ChangeNotifier {
  String _currentQuizzName = "";

  String get currentQuizzName => _currentQuizzName;
}