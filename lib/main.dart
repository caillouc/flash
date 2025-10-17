import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:scrolls_to_top/scrolls_to_top.dart';

import 'card_list.dart';
import 'card_stack.dart';
import 'notifiers/card_notifier.dart';
import 'notifiers/quizz_list_notifier.dart';
import 'notifiers/settings.notifier.dart';
import 'notifiers/tag_notifier.dart';
import 'quizz_menu.dart';
import 'search_bar.dart';
import 'settings.dart';
import 'tag_bar.dart';

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
        // textTheme: Theme.of(context).textTheme.apply(
        //   fontSizeFactor: 1.25,
        //   fontFamily: "SBL_Hbrw",
        //   fontFamilyFallback: ["SBL_Hbrw"],
        // ),
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.grey,
          dynamicSchemeVariant: DynamicSchemeVariant.monochrome,
          brightness: Brightness.light,
        ),
        primaryColor: Colors.grey,
      ),
      darkTheme: ThemeData(
        // textTheme: Theme.of(context).textTheme.apply(
        //   fontSizeFactor: 1.25,
        //   fontFamily: "SBL_Hbrw",
        //   fontFamilyFallback: ["SBL_Hbrw"],
        // ),
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.grey,
          dynamicSchemeVariant: DynamicSchemeVariant.monochrome,
          brightness: Brightness.dark,
        ),
        primaryColor: Colors.grey,
      ),
      themeMode: ThemeMode.system,
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _listViewController = ScrollController();
  final CardSwiperController _cardSwiperController = CardSwiperController();
  final TextEditingController _textEditingController = TextEditingController();

  bool _listView = false;

  @override
  void initState() {
    super.initState();
    // SharedPreferences.getInstance().then((prefs) {
    //   prefs.clear();
    // });
    settingsNotifier.init();
    // For Quizz name
    quizzListNotifier.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });

    quizzListNotifier.loadLocalQuizzList().then((_) {
      cardNotifier.loadCurrentQuizzFromPrefs();
      quizzListNotifier.fetchAndSaveOnlineQuizzList().then((_) {
        quizzListNotifier.checkNewVersion();
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    _listViewController.dispose();
    _cardSwiperController.dispose();
    _textEditingController.dispose();
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
              return IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () {
                  _scaffoldKey.currentState?.openDrawer();
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
                            child: CardStack(
                              controller: _cardSwiperController,
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
