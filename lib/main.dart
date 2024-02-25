import 'package:shared_preferences/shared_preferences.dart';
import 'package:scrolls_to_top/scrolls_to_top.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'dart:convert';
import 'dart:math';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flash Learning',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // appBarTheme: AppBarTheme.,
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

  bool _learnMode = false;
  List<bool> _showLearnQuestion = [];
  bool _showQuestion = true;
  int _cardDisplayed = 0;

  List _questions = [];
  int _currentQuestionIndex = -1;
  double _currentQuestionTextSize = -1;
  double _currentQuestionDescriptionSize = -1;
  List _quizzes = [];
  int _currentQuizzIndex = -1;
  String _currentQuizzName = "";
  String _searchPattern = "";

  List<Widget> scoreButtons = [];
  List<int> _toAsk = [];
  int _toAskIndex = 0;

  late AnimationController _moveController;
  final _fieldTextController = TextEditingController();
  final _listViewController = ScrollController();

  @override
  void initState() {
    super.initState();
    _moveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _moveController.addListener(() {
      setState(() {});
    });
    _initQuizz();
    _buildSuccessButton();
  }

  void _buildSuccessButton() {
    List<Color> buttonColors = const [
      Color(0xFFC8F4C5),
      Color(0xFFC5DFF4),
      // Color(0xFFF1C5F4),
      Color(0xFFF4DAC5)
    ];
    List<String> buttonTexts = const ["Again", "Hard", "Good"];
    for (int i = 0; i < buttonTexts.length; i++) {
      scoreButtons.add(
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor:
                buttonColors[buttonTexts.length - 1 - i], // Background color
            foregroundColor: Colors.black,
            shape: const CircleBorder(),
            fixedSize: const Size(90, 90),
          ),
          onPressed: () {
            print("DEBUG: Button $i pressed");
            _updateQuestion(_currentQuestionIndex, i);
            setState(() {
              _showQuestion = true;
            });
            _moveController.forward().whenComplete(() {
              setState(() {
                _moveController.reset();
                _cardDisplayed = (_cardDisplayed + 1) % 3;
              });
              _setNextCard();
            });
          },
          child: Text(buttonTexts[i]),
        ),
      );
    }
  }

  @override
  void dispose() {
    super.dispose();
    _moveController.dispose();
    _fieldTextController.dispose();
    _listViewController.dispose();
  }

  void _updateDate() async {
    final prefs = await SharedPreferences.getInstance();
    int storedYear = prefs.getInt("year") ?? 0;
    int storedDayOfYear = prefs.getInt("dayOfYear") ?? -1;
    int year = int.parse(DateFormat.y().format(DateTime.now()));
    int dayOfYear = int.parse(DateFormat('D').format(DateTime.now()));
    prefs.setInt("year", year);
    prefs.setInt("dayOfYear", dayOfYear);
    print(
        "DEBUG: Stored year: $storedYear, stored day of year: $storedDayOfYear, current year: $year, current day of year: $dayOfYear");
    int dayDiff = dayOfYear + 365 * (year - storedYear) - storedDayOfYear;
    print("DEBUG: Day diff: $dayDiff");
    for (int i = 0; i < _questions.length; i++) {
      String? values = prefs.getString(_currentQuizzName + i.toString());
      if (values == null) {
        continue;
      }
      List<String> splitted = values.split('_');
      int day = int.parse(splitted[1]);
      int newDay = max(day - dayDiff, 0);
      if (day == newDay) {
        continue;
      }
      await prefs.setString(
          _currentQuizzName + i.toString(), '${splitted[0]}_$newDay');
      print(
          "DEBUG: Updated question ${_questions[i]["Question"]} with day: $newDay");
    }
  }

  void _initQuizz() async {
    final prefs = await SharedPreferences.getInstance();
    int? tempListindex = prefs.getInt("saveQuizzIndex");
    final String response =
        await rootBundle.loadString("resource/quizzesList.json");
    final data = await json.decode(response);
    setState(() {
      _quizzes = data;
      _currentQuizzIndex = tempListindex ?? 0;
      _currentQuestionTextSize = data[_currentQuizzIndex]["QuestionTextSize"];
      _currentQuestionDescriptionSize =
          data[_currentQuizzIndex]["DescriptionTextSize"];
      _currentQuizzName = data[_currentQuizzIndex]["Name"];
    });
    print("DEBUG: Quizz $_currentQuizzName loaded");
    _readQuestions(_quizzes[_currentQuizzIndex]["Path"]).then((value) {
      setState(() {
        _showLearnQuestion = List.filled(_questions.length, true);
      });
      _setNextCard(resuffle: true);
    });
  }

  Future<bool> suffleCard() async {
    final prefs = await SharedPreferences.getInstance();
    List<int> options = [];
    for (int i = 0; i < _questions.length; i++) {
      String? values = prefs.getString(_currentQuizzName + i.toString());
      if (values == null) {
        // values = box_remainingDay
        values ??= "0_0";
        await prefs.setString(_currentQuizzName + i.toString(), values);
      }
      // get all questions with remaining day = 0
      List<String> splitted = values.split('_');
      if (splitted[1] == "0") {
        options.add(i);
      }
    }
    // There are 5 boxes in total
    int box = -1;
    while (options.isEmpty && box < 4) {
      box++;
      for (int i = 0; i < _questions.length; i++) {
        String? values = prefs.getString(_currentQuizzName + i.toString());
        List<String> splitted = values!.split('_');
        if (splitted[0] == box.toString()) {
          options.add(i);
        }
      }
    }
    if (options.isEmpty) {
      options = List.generate(_questions.length, (i) => i);
    }
    if (box == -1) {
      print(
          "DEBUG: New order generated for current day with ${options.length} questions");
    } else {
      print(
          "DEBUG: New order generated for box $box with ${options.length} questions");
    }
    options.shuffle();
    setState(() {
      _toAsk = List.from(options);
    });
    print("DEBUG: toAsk : $_toAsk");
    return true;
  }

  void _setNextCard({bool resuffle = false}) {
    if (_toAsk.isEmpty || _toAskIndex >= _toAsk.length - 1 || resuffle) {
      suffleCard().then((value) {
        _updateDate();
        setState(() {
          _toAskIndex = 0;
          _currentQuestionIndex = _toAsk[0];
        });
      });
    } else {
      setState(() {
        _toAskIndex = _toAskIndex + 1;
      });
      setState(() {
        _currentQuestionIndex = _toAsk[_toAskIndex];
      });
    }
    // final prefs = await SharedPreferences.getInstance();
    // final String? values =
    //     prefs.getString(_currentQuizzName + _currentQuestionIndex.toString());
    // print("DEBUG: Next card set to $_currentQuestionIndex with values $values");
    print("DEBUG: Next card set to $_currentQuestionIndex");
  }

  void _updateQuestion(int questionIndex, int newValue) async {
    final prefs = await SharedPreferences.getInstance();
    final String? values =
        prefs.getString(_currentQuizzName + questionIndex.toString());
    if (values == null) {
      return;
    }
    List<String> splitted = values.split('_');
    int box = int.parse(splitted[0]);
    String toSet = "";
    if (newValue == 0) {
      toSet = "0_0";
    } else if (newValue == 1) {
      if (box - 1 <= 0){
      toSet = "0_0";
      } else {
        toSet = "${box - 1}_1";
      }
    } else {
      if (box == 0) {
        toSet = "1_1";
      } else if (box == 1) {
        toSet = "2_3";
      } else if (box == 2) {
        toSet = "3_7";
      } else if (box == 3) {
        toSet = "4_14";
      } else {
        toSet = "4_30";
      }
    }
    print(
        "DEBUG: New Values $toSet for ${_questions[questionIndex]["Question"]}");
    await prefs.setString(_currentQuizzName + questionIndex.toString(), toSet);
  }

  Future<int> _readQuestions(String filePath) async {
    print("DEBUG: trying to read questions in file $filePath");
    final String response = await rootBundle.loadString(filePath);
    final data = await json.decode(response);
    setState(() {
      _questions = data;
      setState(() {
        _searchPattern = "";
      });
      _fieldTextController.clear();
    });
    print("DEBUG: ${_questions.length} questions parsed");
    return 0;
  }

  Widget _flashCard(
      {required int cardID,
      required BuildContext context,
      required String question,
      required String answer,
      required String image,
      required String description}) {
    final List<Color> cardColors = [
      Theme.of(context).colorScheme.primary,
      Theme.of(context).colorScheme.secondary,
      Theme.of(context).colorScheme.tertiary,
    ];
    return Card(
      key: _learnMode
          ? ValueKey(_showLearnQuestion[cardID])
          : ValueKey(_showQuestion),
      color: cardColors[cardID % 3],
      elevation: 10,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: SizedBox(
        width: 300,
        height: 500,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: (cardID == _cardDisplayed && _currentQuestionIndex != -1) ||
                  _learnMode
              ? (_showQuestion && !_learnMode) ||
                      _learnMode && (_showLearnQuestion[cardID])
                  ? [
                      question == ""
                          ? const SizedBox(
                              height: 0,
                              width: 0,
                            )
                          : Container(
                              padding: const EdgeInsets.fromLTRB(0, 20, 0, 0),
                              child: Text(
                                question,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineLarge!
                                    .copyWith(
                                      fontSize: _currentQuestionTextSize,
                                    ),
                                textAlign: TextAlign.center,
                              )),
                      image == ""
                          ? const SizedBox(
                              height: 0,
                              width: 0,
                            )
                          : Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                child: Image.asset(
                                  image,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                    ]
                  : [
                      const SizedBox(
                        height: 20,
                        width: 20,
                      ),
                      Text(
                        answer,
                        style: Theme.of(context).textTheme.headlineLarge,
                        textAlign: TextAlign.center,
                      ),
                      description == ""
                          ? const SizedBox(
                              height: 0,
                              width: 0,
                            )
                          : Container(
                              padding: const EdgeInsets.all(30),
                              child: Text(
                                description,
                                textAlign: TextAlign.justify,
                                style: TextStyle(
                                  fontSize: _currentQuestionDescriptionSize,
                                ),
                              ),
                            ),
                    ]
              : [],
        ),
      ),
    );
  }

  Widget animatedCard(
      {required int cardID,
      required String question,
      required String answer,
      required String image,
      required String description}) {
    Widget transitionBuilder(Widget widget, Animation<double> animation) {
      final rotateAnim = Tween(begin: pi, end: 0.0).animate(animation);
      return AnimatedBuilder(
        animation: rotateAnim,
        child: widget,
        builder: (context, widget) {
          final isUnder = _learnMode
              ? ValueKey(_showLearnQuestion[cardID]) != widget!.key
              : ValueKey(_showQuestion) != widget!.key;
          // (_learnMode && _showLearnQuestion[cardID])) !=
          // widget!.key);
          var tilt = ((animation.value - 0.5).abs() - 0.5) * 0.001;
          tilt *= isUnder ? -1.0 : 1.0;
          final value =
              isUnder ? min(rotateAnim.value, pi / 2) : rotateAnim.value;
          return Transform(
            transform: Matrix4.rotationY(value)..setEntry(3, 0, tilt),
            alignment: Alignment.center,
            child: widget,
          );
        },
      );
    }

    return GestureDetector(
      onLongPress: () async {
        final prefs = await SharedPreferences.getInstance();
        String? values = _learnMode ? prefs.getString(_currentQuizzName + cardID.toString()) : prefs.getString(_currentQuizzName + _currentQuestionIndex.toString());
        SnackBar snackBar = SnackBar(
          content: Text(
              "Box: ${values == null ? 0 : values.split('_')[0]}, Day: ${values == null ? 0 : values.split('_')[1]}"),
          duration: const Duration(seconds: 2),
        );
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
       
      },
      onTap: () => setState(() {
        if (_learnMode) {
          _showLearnQuestion[cardID] = !_showLearnQuestion[cardID];
          return;
        }
        _showQuestion = !_showQuestion;
      }),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: transitionBuilder,
        layoutBuilder: (widget, list) => Stack(children: [widget!, ...list]),
        switchInCurve: Curves.easeInBack,
        switchOutCurve: Curves.easeInBack.flipped,
        child: _flashCard(
            cardID: cardID,
            context: context,
            question: question,
            answer: answer,
            image: image,
            description: description),
      ),
    );
  }

  List<Widget> _cardStack() {
    List<Widget> ret = [];
    for (int i = 0; i < 3; i++) {
      double offsetInitial = _cardDisplayed == i
          ? 0
          : i == (_cardDisplayed + 2) % 3
              ? 40
              : 20;
      double offsetNew = _cardDisplayed == i ? 40 : -20;
      ret.add(
        PositionedTransition(
          rect: RelativeRectTween(
            begin: RelativeRect.fromLTRB(
              offsetInitial,
              40 - offsetInitial,
              40 - offsetInitial,
              offsetInitial,
            ),
            end: RelativeRect.fromLTRB(
              offsetInitial + offsetNew,
              40 - offsetInitial - offsetNew,
              40 - offsetInitial - offsetNew,
              offsetInitial + offsetNew,
            ),
          ).animate(CurvedAnimation(
            parent: _moveController,
            curve: Curves.easeOut,
          )),
          child: _cardDisplayed == i
              ? FadeTransition(
                  opacity: Tween(
                    begin: 1.0,
                    end: 0.25,
                  ).animate(_moveController),
                  child: animatedCard(
                    cardID: i,
                    question: _questions[_currentQuestionIndex]["Question"],
                    answer: _questions[_currentQuestionIndex]["Answer"],
                    image: _questions[_currentQuestionIndex]["Image"],
                    description: _questions[_currentQuestionIndex]
                        ["Description"],
                  ),
                )
              : _flashCard(
                  cardID: i,
                  context: context,
                  question: _questions[_currentQuestionIndex]["Question"],
                  answer: _questions[_currentQuestionIndex]["Answer"],
                  image: _questions[_currentQuestionIndex]["Image"],
                  description: _questions[_currentQuestionIndex]["Description"],
                ),
        ),
      );
    }
    return [
      ret[(_cardDisplayed + 2) % 3],
      ret[(_cardDisplayed + 1) % 3],
      ret[_cardDisplayed],
    ];
  }

  void switchQuizz(int newIndex) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt("saveQuizzIndex", newIndex);
    setState(() {
      _currentQuizzIndex = newIndex;
      _currentQuestionTextSize = _quizzes[newIndex]["QuestionTextSize"];
      _currentQuestionDescriptionSize =
          _quizzes[newIndex]["DescriptionTextSize"];
      _currentQuizzName = _quizzes[newIndex]["Name"];
      _showQuestion = true;
    });
    _readQuestions(_quizzes[_currentQuizzIndex]["Path"]).whenComplete(() {
      setState(() {
        _showLearnQuestion = List.filled(_questions.length, true);
      });
      _setNextCard(resuffle: true);
    });
  }

  Widget quizzMenu() {
    return Drawer(
      child: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(
              height: 50,
            ),
            for (int i = 0; i < _quizzes.length; i++) ...[
              SizedBox(
                height: 60,
                child: Center(
                  child: Card(
                    child: ListTile(
                      title: Text(_quizzes[i]["Name"]),
                      // https://api.flutter.dev/flutter/material/Icons-class.html#constants
                      trailing: Icon(_quizzes[i]["Icon"] == ""
                          ? Icons.done_all
                          : IconData(int.parse(_quizzes[i]["Icon"]),
                              fontFamily: 'MaterialIcons')),
                      onTap: () {
                        if (i == _currentQuizzIndex) {
                          Navigator.of(context).pop();
                          return;
                        }
                        switchQuizz(i);
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                ),
              ),
            ]
          ],
        ),
      ),
    );
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
        drawer: quizzMenu(),
        appBar: AppBar(
          actions: [
            IconButton(
              icon: Icon(_learnMode ? Icons.school : Icons.school_outlined),
              onPressed: () {
                setState(() {
                  print("DEBUG: Learn mode toggled");
                  _learnMode = !_learnMode;
                  _showLearnQuestion = List.filled(_questions.length, true);
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
          title: Text(_currentQuizzName),
        ),
        floatingActionButton: _learnMode && _fieldTextController.text.isEmpty
            ? FloatingActionButton(
                child: const Icon(Icons.arrow_downward),
                onPressed: () {
                  _listViewController.animateTo(
                    518 * (_questions.length.toDouble() - 1) - 138,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                  );
                },
              )
            : null,
        body: Center(
          child: _learnMode
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    const SizedBox(
                      height: 20,
                    ),
                    Expanded(
                      child: ListView.builder(
                        controller: _listViewController,
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        itemCount: _questions.length + 1,
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return Container(
                              padding: const EdgeInsets.all(10),
                              child: TextField(
                                controller: _fieldTextController,
                                decoration: InputDecoration(
                                  border: const OutlineInputBorder(),
                                  labelText: 'Search',
                                  suffixIcon: IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: (() {
                                      _fieldTextController.clear();
                                      setState(() {
                                        _searchPattern = "";
                                      });
                                    }),
                                  ),
                                ),
                                onChanged: (value) => setState(() {
                                  _searchPattern = value;
                                }),
                              ),
                            );
                          }
                          if (_searchPattern.isEmpty ||
                              _questions[index - 1]["Question"]
                                  .toString()
                                  .toLowerCase()
                                  .replaceAll(RegExp(r'[\u0591-\u05C7]'), '')
                                  .contains(
                                      _searchPattern.trim().toLowerCase()) ||
                              _questions[index - 1]["Answer"]
                                  .toString()
                                  .toLowerCase()
                                  .replaceAll(RegExp(r'[\u0591-\u05C7]'), '')
                                  .contains(
                                      _searchPattern.trim().toLowerCase()) ||
                              _questions[index - 1]["Description"]
                                  .toString()
                                  .toLowerCase()
                                  .replaceAll(RegExp(r'[\u0591-\u05C7]'), '')
                                  .contains(
                                      _searchPattern.trim().toLowerCase())) {
                            return Center(
                              child: Container(
                                padding: const EdgeInsets.fromLTRB(0, 5, 0, 5),
                                child: animatedCard(
                                    cardID: index - 1,
                                    question: _questions[index - 1]["Question"],
                                    answer: _questions[index - 1]["Answer"],
                                    image: _questions[index - 1]["Image"],
                                    description: _questions[index - 1]
                                        ["Description"]),
                              ),
                            );
                          } else {
                            return const SizedBox(
                              height: 0,
                            );
                          }
                        },
                      ),
                    )
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    SizedBox(
                      height: 540,
                      width: 340,
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: _currentQuestionIndex == -1 ||
                                _currentQuestionIndex >= _questions.length
                            ? []
                            : _cardStack(),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: scoreButtons,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
