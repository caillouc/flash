import 'package:flutter/material.dart';
import 'quizz.dart';
import 'main.dart';
import 'utils.dart' as utils;

class QuizzMenu extends StatefulWidget {
  const QuizzMenu({super.key});

  @override
  State<QuizzMenu> createState() => _QuizzMenuState();
}

class _QuizzMenuState extends State<QuizzMenu> {
  var _editMode = quizzListNotifier.localQuizzes.isEmpty;
  List<Quizz> _quizzesInEditMode = [];
  final _searchController = TextEditingController();
  String _searchFilter = '';

  void _handleQuizzListNotifierChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    if (_editMode) {
      _quizzesInEditMode = List.from(quizzListNotifier.allQuizzes);
    }
    quizzListNotifier.addListener(_handleQuizzListNotifierChanged);
  }

  @override
  void dispose() {
    quizzListNotifier.removeListener(_handleQuizzListNotifierChanged);
    _searchController.dispose();
    super.dispose();
  }

  List<Quizz> get _displayedQuizzes {
    final quizzes =
        _editMode ? _quizzesInEditMode : quizzListNotifier.localQuizzes;
    if (_searchFilter.isEmpty) {
      return quizzes;
    }
    final lowerFilter = utils.removeAccents(_searchFilter.toLowerCase());
    return quizzes
        .where((quizz) => utils
            .removeAccents(quizz.name.toLowerCase())
            .contains(lowerFilter))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final displayedQuizzes = _displayedQuizzes;
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchFilter = value.trim();
                  });
                },
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: 'Rechercher',
                  isDense: true,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      if (_searchController.text.isEmpty) {
                        return;
                      }
                      _searchController.clear();
                      setState(() {
                        _searchFilter = '';
                      });
                    },
                  ),
                ),
              ),
            ),
            if (displayedQuizzes.isEmpty && _searchFilter.isNotEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Aucun quiz trouvé'),
              ),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.zero,
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                itemBuilder: (context, index) {
                  final quizz = displayedQuizzes[index];
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
                        if (quizzListNotifier.currentQuizzName != quizz.name) {
                          cardNotifier.setTextFilter('');
                          cardNotifier.loadQuizz(quizz);
                        }
                        Navigator.of(context).pop();
                      }
                    },
                  );
                },
                itemCount: displayedQuizzes.length,
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
                      if (_editMode) {
                        if (quizzListNotifier.localQuizzes.length == 1) {
                          final quizz = quizzListNotifier.localQuizzes.first;
                          if (quizzListNotifier.currentQuizzName != quizz.name) {
                            cardNotifier.setTextFilter('');
                            cardNotifier.loadQuizz(quizz);
                          }
                          Navigator.of(context).pop();
                        }
                      } else {
                        _quizzesInEditMode =
                            List.from(quizzListNotifier.allQuizzes);
                      }
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
