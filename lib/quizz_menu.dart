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
          const Divider(
            endIndent: 20,
            indent: 20,
          ),
          Expanded(
            child: ListView.builder(
              itemBuilder: (context, index) {
                final quizz = _editMode
                    ? quizzListNotifier.allQuizzes[index]
                    : quizzListNotifier.localQuizzes[index];
                return ListTile(
                  title: Text(quizz.name),
                  leading: _editMode
                      ? Switch(
                          value: quizzListNotifier.isLocalQuizz(quizz),
                          onChanged: (selected) {
                            if (selected) {
                              quizzListNotifier.addLocalQuizz(quizz);
                            } else {
                              quizzListNotifier.removeLocalQuizz(quizz);
                            }
                          },
                        )
                      : null,
                  trailing: quizzListNotifier.isUpdateAvailable(quizz)
                      ? IconButton(
                          onPressed: () {
                            quizzListNotifier.removeLocalQuizz(quizz);
                            quizzListNotifier.addLocalQuizz(quizz);
                            quizzListNotifier.markAsUpdated(quizz);
                          },
                          icon: const Icon(Icons.update, color: Colors.orange),
                        )
                      : Icon(
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
                      cardNotifier.loadQuizz(quizz);
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
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _editMode = !_editMode;
                  });
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.black),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(7),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(_editMode ? 'Done' : 'Edit'),
              ),
            ),
          )
        ],
      ),
    );
  }
}
