import 'package:flutter/material.dart';
import 'package:magtapp/repositories/file_repository.dart';
import 'package:intl/intl.dart';

class FilesScreen extends StatefulWidget {
  const FilesScreen({super.key});

  @override
  State<FilesScreen> createState() => _FilesScreenState();
}

class _FilesScreenState extends State<FilesScreen> {
  final FileRepository _fileRepository = FileRepository();
  List<Map<String, dynamic>> _files = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    setState(() {
      _isLoading = true;
    });
    final files = await _fileRepository.getDownloads();
    setState(() {
      _files = files;
      _isLoading = false;
    });
  }

  Future<void> _pickFile() async {
    await _fileRepository.pickAndSaveFile();
    _loadFiles();
  }

  Future<void> _openFile(String path) async {
    await _fileRepository.openFile(path);
  }

  Future<void> _deleteFile(int id, String path) async {
    await _fileRepository.deleteFile(id, path);
    _loadFiles();
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Files'),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _pickFile),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _files.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.folder_open, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No files found'),
                  SizedBox(height: 8),
                  Text(
                    'Tap + to add files',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _files.length,
              itemBuilder: (context, index) {
                final file = _files[index];
                final date = DateTime.fromMillisecondsSinceEpoch(
                  file['timestamp'] as int,
                );
                final formattedDate = DateFormat(
                  'MMM d, yyyy HH:mm',
                ).format(date);

                return ListTile(
                  leading: Icon(
                    _getFileIcon(file['type'] as String),
                    color: Colors.blue,
                    size: 32,
                  ),
                  title: Text(
                    file['name'] as String,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '${_formatSize(file['size'] as int)} • $formattedDate',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () =>
                        _deleteFile(file['id'] as int, file['path'] as String),
                  ),
                  onTap: () => _openFile(file['path'] as String),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _pickFile,
        child: const Icon(Icons.add),
      ),
    );
  }

  IconData _getFileIcon(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      default:
        return Icons.insert_drive_file;
    }
  }
}
