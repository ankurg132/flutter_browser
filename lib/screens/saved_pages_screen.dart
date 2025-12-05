import 'package:flutter/material.dart';
import 'package:magtapp/services/database_service.dart';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:magtapp/bloc/browser_bloc.dart';
import 'package:magtapp/bloc/browser_event.dart';

class SavedPagesScreen extends StatefulWidget {
  const SavedPagesScreen({super.key});

  @override
  State<SavedPagesScreen> createState() => _SavedPagesScreenState();
}

class _SavedPagesScreenState extends State<SavedPagesScreen> {
  final DatabaseService _databaseService = DatabaseService();
  List<Map<String, dynamic>> _savedPages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSavedPages();
  }

  Future<void> _loadSavedPages() async {
    setState(() {
      _isLoading = true;
    });
    final pages = await _databaseService.getSavedPages();
    setState(() {
      _savedPages = pages;
      _isLoading = false;
    });
  }

  Future<void> _deleteSavedPage(int id) async {
    await _databaseService.deleteSavedPage(id);
    _loadSavedPages();
  }

  void _openPage(String url) {
    // Open in browser. The browser will handle loading from cache if offline.
    context.read<BrowserBloc>().add(BrowserAddTab(url: url));
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Offline Pages')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _savedPages.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.offline_pin, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No offline pages found'),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _savedPages.length,
              itemBuilder: (context, index) {
                final page = _savedPages[index];
                final date = DateTime.fromMillisecondsSinceEpoch(
                  page['timestamp'] as int,
                );
                final formattedDate = DateFormat('MMM d, HH:mm').format(date);

                return ListTile(
                  leading: const Icon(Icons.web, color: Colors.green),
                  title: Text(
                    page['title'] as String? ?? 'Offline Page',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '${page['url']}\n$formattedDate',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _deleteSavedPage(page['id'] as int),
                  ),
                  onTap: () => _openPage(page['url'] as String),
                );
              },
            ),
    );
  }
}
