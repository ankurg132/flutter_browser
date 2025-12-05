import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:magtapp/bloc/browser_bloc.dart';
import 'package:magtapp/bloc/browser_event.dart';
import 'package:magtapp/bloc/browser_state.dart';
import 'package:magtapp/bloc/ai/ai_bloc.dart';
import 'package:magtapp/bloc/ai/ai_event.dart';
import 'package:magtapp/screens/browser/browser_view.dart';
import 'package:magtapp/screens/browser/browser_tabs_screen.dart';
import 'package:magtapp/screens/files_screen.dart';
import 'package:magtapp/screens/settings_screen.dart';
import 'package:magtapp/screens/history_screen.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class BrowserScreen extends StatefulWidget {
  const BrowserScreen({super.key});

  @override
  State<BrowserScreen> createState() => _BrowserScreenState();
}

class _BrowserScreenState extends State<BrowserScreen> {
  late final TextEditingController _urlController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController();
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<BrowserBloc, BrowserState>(
      listenWhen: (previous, current) {
        // Listen for URL changes, active tab ID changes, or new messages
        return (previous.activeTab?.url != current.activeTab?.url) ||
            (previous.activeTabId != current.activeTabId) ||
            (current.message != null && current.message != previous.message);
      },
      listener: (context, state) {
        // Show SnackBar if there is a message
        if (state.message != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message!),
              duration: const Duration(seconds: 2),
            ),
          );
        }

        final activeTab = state.activeTab;
        if (activeTab != null) {
          if (_urlController.text != activeTab.url) {
            _urlController.text = activeTab.url;
          }
          // Load summary for the active tab
          context.read<AIBloc>().add(AILoadSummary(activeTab.url));
        }

        // If we are in Tabs screen and active tab changed, switch to Home
        if (_currentIndex == 2 && state.activeTabId.isNotEmpty) {
          setState(() {
            _currentIndex = 0;
          });
        }
      },
      builder: (context, state) {
        // If we are in Tabs screen and active tab changed, switch to Home
        // Note: doing this in builder is bad practice, should be in listener.
        // But listener above handles it.

        // Wait, I can't setState in listener easily without scheduling.
        // Let's refine the listener.

        return Scaffold(
          appBar: _currentIndex == 0
              ? AppBar(
                  backgroundColor: Colors.white,
                  elevation: 1,
                  title: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: TextField(
                      controller: _urlController,
                      decoration: const InputDecoration(
                        hintText: 'Search or enter address',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        prefixIcon: Icon(
                          Icons.lock,
                          size: 16,
                          color: Colors.grey,
                        ),
                      ),
                      onSubmitted: (value) {
                        final activeTab = state.activeTab;
                        if (activeTab != null) {
                          context.read<BrowserBloc>().add(
                            BrowserLoadUrl(id: activeTab.id, url: value),
                          );
                        } else {
                          context.read<BrowserBloc>().add(
                            BrowserAddTab(url: value),
                          );
                        }
                      },
                    ),
                  ),
                  actions: [
                    if (state.activeTab != null)
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: () => context.read<BrowserBloc>().add(
                          BrowserRefresh(state.activeTab!.id),
                        ),
                      ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        context.read<BrowserBloc>().add(const BrowserAddTab());
                      },
                    ),
                  ],
                )
              : null, // Hide AppBar for other screens (they have their own)
          body: Column(
            children: [
              StreamBuilder<List<ConnectivityResult>>(
                stream: Connectivity().onConnectivityChanged,
                builder: (context, snapshot) {
                  final results = snapshot.data;
                  if (results != null &&
                      results.contains(ConnectivityResult.none)) {
                    return Container(
                      color: Colors.red,
                      width: double.infinity,
                      padding: const EdgeInsets.all(4),
                      child: const Text(
                        'Offline Mode',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              Expanded(
                child: IndexedStack(
                  index: _currentIndex,
                  children: [
                    const BrowserView(),
                    const FilesScreen(),
                    const BrowserTabsScreen(),
                    const SettingsScreen(),
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: _onTabSelected,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: Colors.blue,
            unselectedItemColor: Colors.grey,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
              BottomNavigationBarItem(icon: Icon(Icons.folder), label: 'Files'),
              BottomNavigationBarItem(icon: Icon(Icons.layers), label: 'Tabs'),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings),
                label: 'Settings',
              ),
            ],
          ),
        );
      },
    );
  }
}
