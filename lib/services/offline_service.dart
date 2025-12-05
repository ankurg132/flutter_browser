import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:path_provider/path_provider.dart';

import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:magtapp/services/database_service.dart';

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

      // Save metadata to DB
      await _databaseService.insertSavedPage({
        'url': url,
        'title': 'Offline Page', // We might want to pass title here
        'path': file.path,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      print('Error saving page content: $e');
    }
  }

  Future<void> saveHistory(String url, String title) async {
    try {
      await _databaseService.insertHistory({
        'url': url,
        'title': title,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      print('Error saving history: $e');
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

  final DatabaseService _databaseService = DatabaseService();

  Future<void> saveAIResult(String url, String type, String content) async {
    try {
      final fileName = _getFileName(url);
      final key = 'ai_${type}_$fileName';
      await _databaseService.insertAICache(key, content);
    } catch (e) {
      print('Error saving AI result: $e');
    }
  }

  Future<String?> getAIResult(String url, String type) async {
    try {
      final fileName = _getFileName(url);
      final key = 'ai_${type}_$fileName';
      return await _databaseService.getAICache(key);
    } catch (e) {
      print('Error getting AI result: $e');
    }
    return null;
  }
}
