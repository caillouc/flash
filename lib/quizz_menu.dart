import 'package:flutter/material.dart';
import 'quizz.dart';
import 'main.dart';

class QuizzMenu extends StatelessWidget{
  final List<Quizz> quizzes;

  const QuizzMenu({super.key, required this.quizzes});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 50),
            for (int i = 0; i < quizzes.length; i++) ...[
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          quizzes[i].name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Icon(
                        quizzes[i].icon == ""
                            ? Icons.done_all
                            : IconData(
                                int.parse(quizzes[i].icon),
                                fontFamily: 'MaterialIcons',
                              ),
                      ),
                    ],
                  ),
                  onTap: () async {
                    if (quizzes[i].name == stateNotifier.currentQuizz()) {
                      Navigator.of(context).pop();
                      return;
                    }
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}