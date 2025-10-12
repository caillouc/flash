import 'package:flash/quizz.dart';
import 'package:scrolls_to_top/scrolls_to_top.dart';
import 'package:flutter/material.dart';

import 'card.dart';
import 'card_stack.dart';
import 'tag_bar.dart';
import 'card_list.dart';
import 'search_bar.dart';
import 'notifiers.dart';
import 'quizz_menu.dart';

void main() {
  runApp(const MyApp());
}

CurrentQuizzNotifier currentQuizzNotifier = CurrentQuizzNotifier();
QuizzesNotifier quizzesNotifier = QuizzesNotifier();
StateNotifier stateNotifier = StateNotifier();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flash Learning',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        textTheme: Theme.of(context).textTheme.apply(
          fontSizeFactor: 1.25,
          fontFamily: "SBL_Hbrw",
          fontFamilyFallback: ["SBL_Hbrw"],
        ),
        colorScheme: const ColorScheme.light(
          primary: Color(0xffb5bbbd),
          primaryContainer: Color(0xff9ec4d4),
          secondary: Color(0xfff4dac5),
          secondaryContainer: Color(0xffffdbc8),
          tertiary: Color(0xfff7f8f9),
          tertiaryContainer: Color(0xffb5cddb),
        ),
      ),
      themeMode: ThemeMode.light,
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _listViewController = ScrollController();
  final TextEditingController _fieldTextController = TextEditingController();


  bool _learnMode = false;

  final List<FlashCard> _testFlashCard = [
    const FlashCard(frontTitle: "Question 1", backTitle: "Reponse 1"),
    const FlashCard(frontTitle: "Question 2", backTitle: "Reponse 2"),
    const FlashCard(frontTitle: "Question 3", backTitle: "Reponse 3"),
    const FlashCard(frontTitle: "Question 4", backTitle: "Reponse 4"),
    const FlashCard(frontTitle: "Question 5", backTitle: "Reponse 5")
  ];

  final List<String> _tagTest = const ["Tag 1", "Tag2", "Tag3"];
  final List<Quizz> _quizzTest = [
    Quizz(name: "Quizz1", tags: [], icon: "0xe0bf"),
    Quizz(name: "Quizz2", tags: ["tg1", "tg2", "tg3"], icon: "")
  ];


  @override
  void initState() {
    super.initState();
    // initQuizz
    // Update dates
  }

  @override
  void dispose() {
    super.dispose();
    _listViewController.dispose();
  }



  Future<void> _onScrollsToTop(ScrollsToTopEvent event) async {
    _listViewController.animateTo(
      _listViewController.position.minScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScrollsToTop(
      onScrollsToTop: _onScrollsToTop,
      child: Scaffold(
        key: _scaffoldKey,
        drawer: QuizzMenu(
          quizzes: _quizzTest,
        ),
        appBar: AppBar(
          actions: [
            IconButton(
              icon: Icon(_learnMode ? Icons.school : Icons.school_outlined),
              onPressed: () {
                setState(() {
                  _learnMode = !_learnMode;
                });
              },
            ),
          ],
          leading: Builder(
            builder: (BuildContext context) {
              return IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () {
                  _scaffoldKey.currentState?.openDrawer();
                },
              );
            },
          ),
          title: Text(stateNotifier.currentQuizzName),
        ),
        body: Center(
          child: _learnMode
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    TagBar(tags: _tagTest),
                    CustomSearchBar(controller: _fieldTextController),
                    CardList(cards: _testFlashCard, controller: _listViewController,)
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TagBar(tags: _tagTest),
                    SizedBox(
                      height: 540,
                      width: 340,
                      child: CardStack(cards: _testFlashCard),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
