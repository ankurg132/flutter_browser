import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:magtapp/services/database_service.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class FileRepository {
  final DatabaseService _databaseService;

  FileRepository({DatabaseService? databaseService})
    : _databaseService = databaseService ?? DatabaseService();

  Future<void> pickAndSaveFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'docx', 'pptx', 'xlsx'],
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final name = result.files.single.name;
      final size = result.files.single.size;
      final extension = result.files.single.extension ?? 'unknown';

      // Save metadata to DB
      await _databaseService.insertDownload({
        'path': file.path,
        'name': name,
        'type': extension,
        'size': size,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    }
  }

  Future<List<Map<String, dynamic>>> getDownloads() async {
    return await _databaseService.getDownloads();
  }

  Future<OpenResult> openFile(String path) async {
    return await OpenFilex.open(path);
  }

  Future<void> deleteFile(int id, String path) async {
    // Delete from DB
    await _databaseService.deleteDownload(id);

    // Optionally delete from filesystem if it was copied there.
    // For picked files, we might not want to delete the original.
    // If we implement downloading later, we should delete the file.
  }

  Future<String?> downloadFile(String url, String suggestedFilename) async {
    try {
      final dio = Dio();
      final dir = await getApplicationDocumentsDirectory();

      // Ensure filename is valid and has an extension if possible
      String filename = suggestedFilename;
      if (filename.isEmpty) {
        filename = url.split('/').last;
      }
      if (filename.isEmpty) {
        filename = 'download_${DateTime.now().millisecondsSinceEpoch}';
      }

      // Sanitize filename
      filename = filename.replaceAll(RegExp(r'[^\w\s\.-]'), '_');

      final savePath = path.join(dir.path, filename);

      await dio.download(url, savePath);

      final file = File(savePath);
      final size = await file.length();
      final extension = path.extension(savePath).replaceAll('.', '');

      await _databaseService.insertDownload({
        'path': savePath,
        'name': filename,
        'type': extension,
        'size': size,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });

      return savePath;
    } catch (e) {
      print('Download failed: $e');
      return null;
    }
  }
}
