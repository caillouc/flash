# Flash App Technical Fixes And Flow Review

This document aggregates the card stack fixes that were investigated and the broader flow-design issues found during review. The Dart code changes were intentionally reverted in this workspace, so this file is now a propagation guide for redoing the fixes in the environment where Flutter is installed and dynamic validation can be performed.

## Current State Of This Workspace

- The app code in `lib/` has been restored to its previous state.
- The proposed fixes are documented below but are not currently applied here.
- Reapply the changes in the Flutter-enabled environment, then run the validation checklist near the end of this file.

## Context

The visible issue was in the learning card stack, especially when cards had images on the front side.

Observed behavior:

- After swiping the front card, the card that was behind it became first.
- If that next card displayed an image, the image briefly blinked as if it was loaded again.
- Opening or closing the quiz menu also caused the card stack to reload or reshuffle, even when the selected quiz did not change.

Root causes found:

- `CardStack.build()` recomputed `cardNotifier.filteredCards()` on every build.
- `filteredCards()` shuffles cards for the stack view, so incidental rebuilds changed stack order.
- The card image lookup future was cached only inside a single `FlashCard` state instance.
- Some no-op UI actions still notified the card stack, causing unnecessary resets.
- Several widgets register notifier listeners without removing them in `dispose()`.
- Some quiz add/remove/update operations are async but exposed as `void`, making race conditions possible.

## Fixes To Reapply In Flutter Environment

The following fixes address the image blink and card stack reload behavior. They should be applied in the Flutter-enabled environment, then validated dynamically.

### 1. Stabilize The Card Stack List

File: `lib/card_stack.dart`

Problem:

- The stack called `cardNotifier.filteredCards()` during every `build()`.
- Because `filteredCards()` shuffles when used by the stack, opening the drawer, closing the drawer, or any parent repaint could reorder the deck.
- This made the swiper appear to reload, even when the quiz had not changed.

Fix:

- Store the filtered/shuffled card list in `_CardStackState`.
- Build that list once in `initState()`.
- Rebuild it only when card data, tag filters, or the relevant learning mode setting changes.
- Keep drawer open/close rebuilds from recomputing the shuffled deck.

How to redo:

- Add `_filteredCards` and `_apprentissageMode` fields to `_CardStackState`.
- Add a private `_buildFilteredCards()` helper that wraps `cardNotifier.filteredCards()` and returns the existing no-card placeholder if empty.
- Change `refresh()` so it updates `_filteredCards` inside `setState()`.
- Register named listener methods in `initState()` instead of anonymous callbacks.
- Remove those listeners in `dispose()`.
- Change `build()` so `CardSwiper` reads `_filteredCards` instead of recomputing `cardNotifier.filteredCards()` locally.

Important behavior after the fix:

- Opening the quiz menu should not reshuffle or reset the current stack.
- Closing the quiz menu should not reshuffle or reset the current stack.
- Selecting the same quiz should not reload the stack.
- Changing tags should still refresh the stack.
- Changing learning mode should still refresh the stack because it affects filtering.

Implementation shape:

```dart
class _CardStackState extends State<CardStack> {
  List<FlashCard> _filteredCards = [];
  late bool _apprentissageMode;

  List<FlashCard> _buildFilteredCards() { ... }

  void refresh() {
    cardNotifier.clearHistory();
    widget.controller.moveTo(0);
    setState(() {
      _filteredCards = _buildFilteredCards();
    });
  }
}
```

### 2. Cache Resolved Image Files Across Card State Lifetimes

File: `lib/card.dart`

Problem:

- `_imageCache` was stored inside `_FlashCardState`.
- When the swiper discarded or recreated a card widget/state, image path resolution restarted.
- The image was already available locally, but the widget still passed through a brief waiting state.
- That produced the blink when the second card moved to the first position.

Fix:

- Add static caches for resolved image futures and resolved `File` instances.
- Reuse the same future/file for the same image path across `FlashCard` state instances.
- Use `gaplessPlayback: true` on `Image.file`.
- Give `Image.file` a stable `ValueKey(file.path)`.

How to redo:

- Replace the per-state `_imageCache` with static caches in `_FlashCardState`.
- Add a helper that builds an already resolved image widget.
- In `_buildImage()`, return the resolved image immediately if the path is already cached.
- Otherwise, use `putIfAbsent()` to create and cache the local-file future.
- Use `gaplessPlayback: true` on `Image.file`.

Important behavior after the fix:

- A card image that was already resolved while second in the stack should not blank while becoming first.
- A rebuild of the card widget should reuse the resolved file path instead of showing an empty loading placeholder.

Implementation shape:

```dart
static final Map<String, Future<File>> _imageFileFutures = {};
static final Map<String, File> _resolvedImageFiles = {};
```

```dart
Image.file(
  file,
  key: ValueKey(file.path),
  fit: BoxFit.contain,
  gaplessPlayback: true,
)
```

Known follow-up:

- If a quiz update replaces an image while keeping the same path, Flutter's decoded image cache may still show the old image during the same app session.
- On quiz update, consider evicting affected image paths from `FileImage(file).evict()` or clearing the app-level image caches for that quiz folder.

### 3. Do Not Reload When Selecting The Already Active Quiz

File: `lib/quizz_menu.dart`

Problem:

- Tapping the current quiz called `cardNotifier.loadQuizz(quizz)` again.
- This reloaded cards, reset stack state, and could trigger the image blink/reload behavior.

Fix:

- Only call `loadQuizz(quizz)` if the tapped quiz is different from `quizzListNotifier.currentQuizzName`.
- Still close the drawer after the tap.

How to redo:

- In `QuizzMenu.onTap`, keep `cardNotifier.setTextFilter('')`.
- Wrap `cardNotifier.loadQuizz(quizz)` in a current-quiz-name comparison.
- Keep `Navigator.of(context).pop()` outside the condition so tapping the current quiz still closes the drawer.

Implementation shape:

```dart
if (quizzListNotifier.currentQuizzName != quizz.name) {
  cardNotifier.loadQuizz(quizz);
}
Navigator.of(context).pop();
```

### 4. Do Not Notify On No-Op Text Filter Changes

File: `lib/notifiers/card_notifier.dart`

Problem:

- `cardNotifier.setTextFilter('')` notified listeners even when the filter was already empty.
- The quiz menu path called this before loading/selecting a quiz.
- For the currently selected quiz, this could still reset the stack.

Fix:

- Return early if the new filter equals the current filter.

How to redo:

- In `CardNotifier.setTextFilter`, add an equality guard before mutating `_cardTextFilter` or calling `notifyListeners()`.

Implementation shape:

```dart
void setTextFilter(String filter) {
  if (_cardTextFilter == filter) return;
  _cardTextFilter = filter;
  notifyListeners();
}
```

## Important Follow-Up Fixes Suggested

These changes are recommended before the app grows further. They are not all required to fix the image blink, but they address the same class of reload/race/state bugs.

## 1. Remove Notifier Listeners In `dispose()`

Affected files:

- `lib/card_list.dart`
- `lib/tag_bar.dart`
- `lib/settings.dart`
- `lib/quizz_menu.dart`
- `lib/main.dart`

Problem:

Several widgets add anonymous listeners in `initState()` and never remove them.

Example pattern:

```dart
tagNotifier.addListener(() {
  if (mounted) {
    setState(() {});
  }
});
```

The `mounted` check prevents `setState()` after disposal, but the callback remains registered. Over time, recreated widgets leave stale callbacks behind. This can cause extra work, duplicated reactions, memory retention, and harder-to-debug rebuild behavior.

Recommended fix pattern:

```dart
void _handleNotifierChanged() {
  if (mounted) {
    setState(() {});
  }
}

@override
void initState() {
  super.initState();
  tagNotifier.addListener(_handleNotifierChanged);
}

@override
void dispose() {
  tagNotifier.removeListener(_handleNotifierChanged);
  super.dispose();
}
```

Priority:

- High for `QuizzMenu`, because the drawer can be recreated repeatedly.
- High for widgets that listen to global notifiers and appear/disappear often.
- Medium for long-lived widgets, but still worth fixing for consistency.

## 2. Convert Async Quiz Operations From `void async` To `Future<void>`

Affected file: `lib/notifiers/quizz_list_notifier.dart`

Problem methods:

- `removeLocalQuizz(...) async`
- `addLocalQuizz(...) async`

Current issue:

- These methods are async but return `void`.
- Callers cannot `await` them.
- Errors are harder to handle.
- Ordering is not guaranteed from the caller's point of view.

Most important concrete risk:

```dart
void updateQuizz(Quizz quizz) {
  removeLocalQuizz(quizz, skipReload: true, isUpdate: true);
  ...
  addLocalQuizz(upToDateQuizz);
}
```

Because removal is not awaited, update can start adding/downloading the new quiz while the old quiz file and images are still being deleted or while the local quiz list is still being rewritten.

Recommended fix:

```dart
Future<void> updateQuizz(Quizz quizz) async {
  await removeLocalQuizz(quizz, skipReload: true, isUpdate: true);
  ...
  await addLocalQuizz(upToDateQuizz);
}
```

Also change:

```dart
Future<void> removeLocalQuizz(...)
Future<void> addLocalQuizz(...)
```

Priority: High.

## 3. Only Mark A Quiz Local After Download Success

Affected file: `lib/notifiers/quizz_list_notifier.dart`

Problem:

`addLocalQuizz()` currently adds the quiz to `_localQuizzes` before the quiz JSON has been successfully fetched and saved.

Risk:

- Network request fails.
- Quiz still appears local.
- Local quiz list may be written with a quiz whose file does not exist.
- Selecting that quiz later can fail or load empty/corrupt data.

Recommended flow:

1. Add the quiz file name to `_downloadingQuizzFileNames`.
2. Notify listeners so the UI can show loading.
3. Download quiz JSON.
4. If download fails, remove downloading state and notify listeners.
5. Download images if needed.
6. Only then add to `_localQuizzes` and write `quizzesList.json`.
7. If it is the current quiz, load it.
8. Remove downloading state and notify listeners.

Priority: High.

## 4. Make Settings Initialization Awaitable And Notifying

Affected file: `lib/notifiers/settings_notifier.dart`

Problem:

`settingsNotifier.init()` loads SharedPreferences asynchronously, but it does not return a `Future` and does not call `notifyListeners()` after values are loaded.

Risk:

- UI first renders with default settings.
- Settings silently change after preferences load.
- Widgets depending on settings may not refresh.
- Card stack filtering can use the default `apprentissage` value until another event occurs.

Recommended fix:

```dart
Future<void> init() async {
  final prefs = await SharedPreferences.getInstance();
  _apprentissage = prefs.getBool('apprentissage_mode') ?? _apprentissage;
  _reverseCardOrientation = prefs.getBool('reverseCardOrientation') ?? _reverseCardOrientation;
  _mixCardOrientation = prefs.getBool('mixCardOrientation') ?? _mixCardOrientation;
  _privateMode = prefs.getBool('private_mode') ?? _privateMode;
  notifyListeners();
}
```

Then in app startup, await settings initialization before dependent state is built or loaded.

Priority: High.

## 5. Guard `firstWhere()` Calls Against Missing Data

Affected files:

- `lib/notifiers/card_notifier.dart`
- `lib/notifiers/quizz_list_notifier.dart`

Problem:

Several `firstWhere()` calls assume persisted quiz names and local quiz lists are always consistent.

Risk examples:

- `current_quizz` in SharedPreferences references a quiz that was removed.
- A download failed but the quiz was still written to the local list.
- A private/online quiz disappears from the server list.
- The current quiz name is set before `_localQuizzes` contains the corresponding quiz.

Recommended fix:

Use a nullable lookup helper instead of raw `firstWhere()`.

Example:

```dart
Quizz? findLocalQuizByName(String name) {
  for (final quiz in _localQuizzes) {
    if (quiz.name == name) return quiz;
  }
  return null;
}
```

Then handle null explicitly by clearing current quiz, selecting a fallback quiz, or showing the no-local-quiz placeholder.

Priority: Medium to High.

## 6. Avoid Storing Widgets As App Data

Affected file: `lib/notifiers/card_notifier.dart`

Current design:

```dart
List<FlashCard> _cards = [];
```

Problem:

The notifier stores `FlashCard` widgets directly. This mixes persistent quiz data, filtering logic, scheduling state, and UI state.

Why it is risky:

- Widgets are not ideal model objects.
- It makes image caching and widget identity harder to reason about.
- It makes testing filtering/scheduling logic harder.
- It couples notifier code to UI implementation details.
- It encourages rebuild/reuse bugs in swiper/list contexts.

Recommended direction:

Introduce a plain data model, for example:

```dart
class FlashCardData {
  final String id;
  final String frontTitle;
  final String frontDescription;
  final String frontImage;
  final String backTitle;
  final String backDescription;
  final String backImage;
  final List<String> tags;
  final bool randomReverse;
}
```

Then store:

```dart
List<FlashCardData> _cards = [];
```

And build widgets only in UI:

```dart
FlashCard(
  key: ValueKey(card.id),
  id: card.id,
  frontTitle: card.frontTitle,
  ...
)
```

Priority: Medium. This is a larger refactor, but it is the cleanest long-term design improvement.

## 7. Serialize Or Await Box/History Updates

Affected file: `lib/notifiers/card_notifier.dart`

Problem:

`setBoxForCard()` writes SharedPreferences inside a `.then(...)` callback.

Risk:

- Rapid swipe/undo actions can overlap.
- `_history`, `_remainingDaysMap`, `_boxMap`, and SharedPreferences can briefly disagree.
- Undo can become harder to reason about if writes complete out of order.

Recommended fix:

- Convert `setBoxForCard()` to `Future<void>`.
- Await SharedPreferences writes where actions need strict ordering.
- Optionally serialize updates through a simple internal queue if rapid swipes are common.

Priority: Medium.

## 8. Prevent Duplicate Update Entries

Affected file: `lib/notifiers/quizz_list_notifier.dart`

Problem:

`checkNewVersion()` appends to `_updateAvailable` without clearing or checking duplicates first.

Risk:

- Repeated app resumes or repeated remote fetches can add duplicate entries.
- `isUpdateAvailable()` still works, but internal state becomes noisy and less reliable.

Recommended fix:

Either clear before recomputing:

```dart
void checkNewVersion() {
  _updateAvailable.clear();
  ...
}
```

Or store update availability as a `Set<String>` keyed by quiz file name.

Priority: Low to Medium.

## 9. Review Private Mode Search Easter Egg Flow

Affected file: `lib/search_bar.dart`

Problem:

Typing `flash.clsn.fr` toggles private mode and fetches the private quiz list. When private mode is deactivated, the same code path still calls `fetchAndSavePrivateQuizzList()`.

Risk:

- Private list may be fetched even when private mode was just turned off.
- Existing private quizzes/lists may remain in memory until another refresh path replaces them.

Recommended fix:

- If private mode is turned on, fetch private quizzes.
- If private mode is turned off, clear private quiz list from memory or exclude it from `allQuizzes` based on `settingsNotifier.privateMode`.

Priority: Low to Medium.

## Validation Checklist For Flutter Environment

Run these checks after propagating the changes.

### Static Checks

```bash
flutter analyze
```

```bash
flutter test
```

### Manual Stack Behavior

1. Open a quiz with image cards.
2. Swipe the first card.
3. Confirm the second card becomes first without image blink.
4. Open the quiz menu.
5. Close the quiz menu without selecting a quiz.
6. Confirm the visible stack did not reset, reshuffle, or reload.
7. Open the quiz menu again.
8. Tap the currently selected quiz.
9. Confirm the drawer closes but the stack does not reload.
10. Select a different quiz.
11. Confirm the stack reloads as expected.

### Manual Filter Behavior

1. Open list mode.
2. Type a search filter.
3. Clear the filter.
4. Clear it again while already empty.
5. Confirm no unnecessary stack reset happens when returning to stack mode.

### Manual Settings Behavior

1. Toggle learning mode.
2. Confirm the stack refreshes because learning mode affects card selection.
3. Toggle reverse orientation.
4. Confirm cards update orientation without resetting the stack order unless intended.
5. Toggle mixed orientation.
6. Confirm behavior is acceptable and no repeated full-stack resets occur.

### Manual Quiz Update Behavior

After async quiz flow fixes are applied:

1. Update a quiz with images.
2. Confirm old files are removed before new files are written.
3. Confirm local quiz list has no duplicate entries.
4. Confirm the updated quiz can be selected immediately.
5. Confirm images display after update.

## Suggested Implementation Order

Recommended order for the Flutter environment:

1. Validate the prepared stack/image/no-op reload fixes.
2. Fix listener cleanup in all stateful widgets.
3. Convert quiz add/remove/update methods to `Future<void>` and await them.
4. Make settings initialization awaitable and notifying.
5. Guard `firstWhere()` calls.
6. Improve quiz download flow so local state changes only after download success.
7. Clean up update availability duplicates.
8. Later, refactor `FlashCard` widget storage into a data model.

## Summary

The blink and stack reload issue came from unnecessary deck recomputation and short-lived image resolution state. The prepared fix makes the visible deck stable across incidental rebuilds and lets image file resolution survive card widget churn.

The broader app risk is that many flows are global-notifier driven, async operations are not always awaitable, and widgets sometimes register listeners without cleanup. Those patterns are manageable in a small app, but they explain why unrelated UI actions can reset or reload the learning stack. Fixing those flows will make the app much more predictable before adding more quizzes, image-heavy cards, or update behavior.
