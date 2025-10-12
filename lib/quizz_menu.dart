import 'package:flutter/material.dart';
import 'main.dart';

class QuizzMenu extends StatefulWidget {
  const QuizzMenu({super.key});

  @override
  State<QuizzMenu> createState() => _QuizzMenuState();
}

class _QuizzMenuState extends State<QuizzMenu> {
  var _editMode = quizzListNotifier.localQuizzes.isEmpty;

  @override
  void initState() {
    super.initState();
    quizzListNotifier.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          Text("Quizzes", style: Theme.of(context).textTheme.headlineMedium),
          Expanded(
            child: ListView.builder(
              itemBuilder: (context, index) {
                final quizz = _editMode
                    ? quizzListNotifier.allQuizzes[index]
                    : quizzListNotifier.localQuizzes[index];
                return ListTile(
                  title: Text(quizz.name),
                  leading: _editMode
                      ? quizzListNotifier.isLocalQuizz(quizz)
                          ? const Icon(Icons.check_box)
                          : const Icon(Icons.check_box_outline_blank)
                      : null,
                  trailing: Icon(
                    IconData(
                      int.parse(quizz.icon),
                      fontFamily: 'MaterialIcons',
                    ),
                  ),
                  onTap: () {
                    if (_editMode) {
                      if (quizzListNotifier.isLocalQuizz(quizz)) {
                        quizzListNotifier.removeLocalQuizz(quizz);
                      } else {
                        quizzListNotifier.addLocalQuizz(quizz);
                      }
                      return;
                    } else {
                      currentQuizzNotifier.loadQuizz(quizz);
                      Navigator.of(context).pop();
                    }
                  },
                );
              },
              itemCount: _editMode
                  ? quizzListNotifier.allQuizzes.length
                  : quizzListNotifier.localQuizzes.length,
            ),
          ),
          // Button to switch to edit mode
          ElevatedButton(
            onPressed: () {
              setState(() {
                _editMode = !_editMode;
              });
            },
            child: Text(_editMode ? 'Done' : 'Edit'),
          )
        ],
      ),
    );
  }
}
