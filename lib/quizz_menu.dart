import 'package:flutter/material.dart';
import 'main.dart';

class QuizzMenu extends StatefulWidget {
  const QuizzMenu({super.key});

  @override
  State<QuizzMenu> createState() => _QuizzMenuState();
}

class _QuizzMenuState extends State<QuizzMenu> {
  var _editMode = quizzesNotifier.localQuizzes.isEmpty;

  @override
  void initState() {
    super.initState();
    quizzesNotifier.addListener(() {
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
                    ? quizzesNotifier.allQuizzes[index]
                    : quizzesNotifier.localQuizzes[index];
                return ListTile(
                  title: Text(quizz.name),
                  leading: _editMode
                      ? quizzesNotifier.isLocalQuizz(quizz)
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
                      if (quizzesNotifier.isLocalQuizz(quizz)) {
                        quizzesNotifier.removeLocalQuizz(quizz);
                      } else {
                        quizzesNotifier.addLocalQuizz(quizz);
                      }
                      return;
                    } else {
                      Navigator.of(context).pop();
                    }
                  },
                );
              },
              itemCount: _editMode
                  ? quizzesNotifier.allQuizzes.length
                  : quizzesNotifier.localQuizzes.length,
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
