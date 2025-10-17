import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flash/card.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'main.dart';
import 'dart:math';

Future<File> _localFile(String filePath) async {
  final dir = await getApplicationDocumentsDirectory();
  final file = File('${dir.path}/$filePath');
  final parent = file.parent;
  if (!await parent.exists()) {
    await parent.create(recursive: true);
  }
  return file;
}

Future<String> fetchAndSaveFile(String url, String localFilePath) async {
  try {
    final resp = await http.get(Uri.parse(url));
    if (resp.statusCode == 200) {
      final body = resp.body;
      // save file
      final file = await _localFile(localFilePath);
      await file.writeAsString(body);
      print('File successfully fetched and saved to $localFilePath');
      return body;
    }
  } catch (e) {
    print("Error fetching file from $url: $e");
    // TODO: Snackbar ther error ?
  }
  return "";
}

Future<String> readLocalFile(String localFilePath) async {
  try {
    final file = await _localFile(localFilePath);
    if (await file.exists()) {
      return await file.readAsString();
    }
  } catch (e) {
    // ignore and leave quizzes empty
  }
  return "";
}

Future<void> writeLocalFile(String localFilePath, String content) async {
  try {
    final file = await _localFile(localFilePath);
    await file.writeAsString(content);
  } catch (e) {
    print('Error writing local file $localFilePath: $e');
  }
}

Future<void> deleteLocalFile(String localFilePath) async {
  try {
    final file = await _localFile(localFilePath);
    if (await file.exists()) {
      await file.delete();
    }
    print('File $localFilePath deleted');
  } catch (e) {
    // ignore
  }
}

String computeSha1(String input) {
  // Simple SHA1 hash computation
  var bytes = utf8.encode(input);
  var digest = sha1.convert(bytes);
  return digest.toString();
}

int getRemaingDaysForBox(int box) {
  switch (box) {
    case 5:
      return 0;
    case 4:
      return 1;
    case 3:
      return 3;
    case 2:
      return 7;
    case 1:
      return 14;
    case 0:
      return 30;
    default:
      return 0;
  }
}

void updateRemainingDay() async {
    final prefs = await SharedPreferences.getInstance();
    int year = int.parse(DateFormat.y().format(DateTime.now()));
    int dayOfYear = int.parse(DateFormat('D').format(DateTime.now()));
    int storedYear = prefs.getInt("year") ?? year;
    int storedDayOfYear = prefs.getInt("dayOfYear") ?? dayOfYear;
    prefs.setInt("year", year);
    prefs.setInt("dayOfYear", dayOfYear);
    int dayDiff = dayOfYear + 365 * (year - storedYear) - storedDayOfYear;
    for (FlashCard card in cardNotifier.cards) {
      String remainingDaysKey = '${quizzListNotifier.currentQuizzUniqueId}_${card.id}_remaining_days';
      int? stored = prefs.getInt(remainingDaysKey);
      if (stored == null) continue;
      int newDay = max(stored - dayDiff, 0);
      if (stored == newDay) continue;
      prefs.setInt(remainingDaysKey, newDay);
    }
  }