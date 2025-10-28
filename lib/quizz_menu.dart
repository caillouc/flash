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
      child: SafeArea(
        child: Column(
          children: [
            Text("Quiz",
                style: Theme.of(context).textTheme.headlineMedium),
            const Divider(
              endIndent: 20,
              indent: 20,
            ),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemBuilder: (context, index) {
                  final quizz = _editMode
                      ? quizzListNotifier.allQuizzes[index]
                      : quizzListNotifier.localQuizzes[index];
                  final isDownloading =
                      quizzListNotifier.isQuizzDownloading(quizz.fileName);

                  return ListTile(
                    title: Text(quizz.name),
                    leading: _editMode
                        ? (isDownloading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Switch(
                                value: quizzListNotifier.isLocalQuizz(quizz),
                                onChanged: (selected) {
                                  if (selected) {
                                    quizzListNotifier.addLocalQuizz(quizz);
                                  } else {
                                    quizzListNotifier.removeLocalQuizz(quizz);
                                  }
                                },
                              ))
                        : null,
                    trailing: isDownloading && !_editMode
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : quizzListNotifier.isUpdateAvailable(quizz)
                            ? TextButton.icon(
                                onPressed: () {
                                  quizzListNotifier.updateQuizz(quizz);
                                },
                                style: TextButton.styleFrom(
                                  padding:
                                      EdgeInsets.zero, // Remove default padding
                                  minimumSize:
                                      const Size(0, 0), // Remove minimum size
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                iconAlignment: IconAlignment.end,
                                label: const Text(
                                  "MàJ",
                                  style: TextStyle(
                                      color: Colors.orange, fontSize: 16),
                                ),
                                icon: const Icon(Icons.update,
                                    color: Colors.orange, size: 25),
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
                        cardNotifier.setTextFilter('');
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
                  child: Text(_editMode ? 'Terminer' : 'Modifer'),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
