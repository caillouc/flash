import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:io';

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
