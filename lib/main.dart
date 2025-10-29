import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:scrolls_to_top/scrolls_to_top.dart';

import 'card_list.dart';
import 'card_stack.dart';
import 'notifiers/card_notifier.dart';
import 'notifiers/quizz_list_notifier.dart';
import 'notifiers/settings_notifier.dart';
import 'notifiers/tag_notifier.dart';
import 'quizz_menu.dart';
import 'search_bar.dart';
import 'settings.dart';
import 'tag_bar.dart';
import 'utils.dart' as utils;

void main() {
  runApp(const MyApp());
}

QuizzListNotifier quizzListNotifier = QuizzListNotifier();
CardNotifier cardNotifier = CardNotifier();
TagNotifier tagNotifier = TagNotifier();
SettingsNotifier settingsNotifier = SettingsNotifier();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flash Learning',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.grey,
          dynamicSchemeVariant: DynamicSchemeVariant.monochrome,
          brightness: Brightness.light,
        ),
        primaryColor: Colors.grey,
        fontFamily: 'SBL_BLit',
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.grey,
          dynamicSchemeVariant: DynamicSchemeVariant.monochrome,
          brightness: Brightness.dark,
        ),
        primaryColor: Colors.grey,
        fontFamily: 'SBL_BLit',
      ),
      themeMode: ThemeMode.system,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.20)),
          child: child!,
        );
      },
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _listViewController = ScrollController();
  final CardSwiperController _cardSwiperController = CardSwiperController();
  final TextEditingController _textEditingController = TextEditingController();

  bool _listView = false;
  bool _quizzesLoaded = false;
  String _lastQuizzName = "";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // SharedPreferences.getInstance().then((prefs) {
    //   prefs.clear();
    // });
    settingsNotifier.init();
    // For Quizz name - only rebuild if the current quiz name actually changed
    quizzListNotifier.addListener(() {
      if (mounted && _lastQuizzName != quizzListNotifier.currentQuizzName) {
        _lastQuizzName = quizzListNotifier.currentQuizzName;
        setState(() {});
      }
    });
    
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await quizzListNotifier.loadLocalQuizzList();
    
    if (quizzListNotifier.localQuizzes.isNotEmpty) {
      await cardNotifier.loadCurrentQuizzFromPrefs();
    }
    if (mounted) setState(() => _quizzesLoaded = true);

    // Load private quizzes if previously fetched
    if (settingsNotifier.privateMode) {
      await quizzListNotifier.fetchAndSavePrivateQuizzList();
    }
    await quizzListNotifier.fetchAndSaveOnlineQuizzList();
    quizzListNotifier.checkNewVersion();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _handleAppResumed();
    }
  }

  Future<void> _handleAppResumed() async {
    // Update remaining days for current quiz if a quiz is loaded
    if (quizzListNotifier.currentQuizzName.isNotEmpty) {
      await utils.updateRemainingDay();
      // Update the in-memory cache in CardNotifier
      await cardNotifier.refreshRemainingDaysCache();
    }

    // Check for updates
    await quizzListNotifier.fetchAndSaveOnlineQuizzList();
    if (settingsNotifier.privateMode) {
      await quizzListNotifier.fetchAndSavePrivateQuizzList();
    }
    quizzListNotifier.checkNewVersion();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _listViewController.dispose();
    _cardSwiperController.dispose();
    _textEditingController.dispose();
    super.dispose();
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
        drawer: const QuizzMenu(),
        appBar: AppBar(
          actions: [
            IconButton(
              icon: Icon(_listView ? Icons.school : Icons.school_outlined),
              onPressed: () {
                cardNotifier.setTextFilter('');
                _textEditingController.clear();
                setState(() {
                  _listView = !_listView;
                });
              },
            ),
          ],
          leading: Builder(
            builder: (BuildContext context) {
              return ListenableBuilder(
                listenable: quizzListNotifier,
                builder: (context, child) {
                  final hasAnyUpdates = quizzListNotifier.localQuizzes.any((quiz) => 
                    quizzListNotifier.isUpdateAvailable(quiz));
                  
                  // Check if current quiz has an update available
                  final currentQuizHasUpdate = quizzListNotifier.currentQuizzName.isNotEmpty &&
                    quizzListNotifier.localQuizzes
                      .where((quiz) => quiz.name == quizzListNotifier.currentQuizzName)
                      .any((quiz) => quizzListNotifier.isUpdateAvailable(quiz));
                  
                  return Stack(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.menu),
                        onPressed: () {
                          _scaffoldKey.currentState?.openDrawer();
                        },
                      ),
                      if (hasAnyUpdates)
                        Positioned(
                          right: 18,
                          top: 13,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: currentQuizHasUpdate ? Colors.orange : Theme.of(context).iconTheme.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              );
            },
          ),
          title: Text(quizzListNotifier.currentQuizzName),
        ),
        body: SafeArea(
          child: Center(
            child: _listView
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      const TagBar(),
                      CustomSearchBar(
                        controller: _textEditingController,
                      ),
                      CardList(
                        controller: _listViewController,
                      )
                    ],
                  )
                : Stack(
                    children: [
                      const Settings(),
                      Positioned(
                          bottom: 10,
                          right: 10,
                          child: IconButton(
                              onPressed: () => _cardSwiperController.undo(),
                              icon: Icon(
                                  size: 25,
                                  Icons.undo,
                                  color: Theme.of(context).primaryColor))),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const TagBar(),
                          SizedBox(
                            height: 540,
                            width: 340,
                            child: _quizzesLoaded
                                ? CardStack(
                                    controller: _cardSwiperController,
                                  )
                                : const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                          ),
                          const SizedBox(
                            height: 0,
                          )
                        ],
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
