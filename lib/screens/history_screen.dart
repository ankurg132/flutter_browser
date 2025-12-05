import 'package:flutter/material.dart';
import 'package:magtapp/services/database_service.dart';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:magtapp/bloc/browser_bloc.dart';
import 'package:magtapp/bloc/browser_event.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final DatabaseService _databaseService = DatabaseService();
  List<Map<String, dynamic>> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
    });
    final history = await _databaseService.getHistory();
    setState(() {
      _history = history;
      _isLoading = false;
    });
  }

  Future<void> _clearHistory() async {
    await _databaseService.clearHistory();
    _loadHistory();
  }

  Future<void> _deleteHistoryItem(int id) async {
    await _databaseService.deleteHistory(id);
    _loadHistory();
  }

  void _openUrl(String url) {
    // We need to find the main browser screen and load the URL.
    // Since this screen is pushed from Settings, we can pop until we are back at the browser
    // or use the Bloc to load the URL in the active tab.

    // Assuming we want to load it in the current active tab or a new one.
    // Let's load it in the current active tab for simplicity, or add a new tab.
    // Given the navigation structure, we might need to pop back to the main screen.

    // Strategy: Add a new tab with this URL and pop back to root.
    context.read<BrowserBloc>().add(BrowserAddTab(url: url));
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Clear History'),
                  content: const Text(
                    'Are you sure you want to clear all browsing history?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Clear'),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                _clearHistory();
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _history.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No history found'),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _history.length,
              itemBuilder: (context, index) {
                final item = _history[index];
                final date = DateTime.fromMillisecondsSinceEpoch(
                  item['timestamp'] as int,
                );
                final formattedDate = DateFormat('MMM d, HH:mm').format(date);

                return ListTile(
                  leading: const Icon(Icons.public, color: Colors.grey),
                  title: Text(
                    item['title'] as String,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '${item['url']}\n$formattedDate',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    onPressed: () => _deleteHistoryItem(item['id'] as int),
                  ),
                  onTap: () => _openUrl(item['url'] as String),
                );
              },
            ),
    );
  }
}
