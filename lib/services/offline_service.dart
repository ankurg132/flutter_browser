import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class OfflineService {
  final Connectivity _connectivity = Connectivity();

  Future<bool> isOffline() async {
    final result = await _connectivity.checkConnectivity();
    return result == ConnectivityResult.none;
  }

  String _getFileName(String url) {
    var bytes = utf8.encode(url);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<void> savePageContent(String url, String html) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final fileName = _getFileName(url);
      final file = File('${directory.path}/$fileName.html');
      await file.writeAsString(html);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('page_$fileName', DateTime.now().toIso8601String());
    } catch (e) {
      print('Error saving page content: $e');
    }
  }

  Future<String?> getPageContent(String url) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final fileName = _getFileName(url);
      final file = File('${directory.path}/$fileName.html');
      if (await file.exists()) {
        return await file.readAsString();
      }
    } catch (e) {
      print('Error getting page content: $e');
    }
    return null;
  }

  Future<void> saveAIResult(String url, String type, String content) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final fileName = _getFileName(url);
      await prefs.setString('ai_${type}_$fileName', content);
    } catch (e) {
      print('Error saving AI result: $e');
    }
  }

  Future<String?> getAIResult(String url, String type) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final fileName = _getFileName(url);
      return prefs.getString('ai_${type}_$fileName');
    } catch (e) {
      print('Error getting AI result: $e');
    }
    return null;
  }
}
