import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:magtapp/bloc/browser_bloc.dart';
import 'package:magtapp/bloc/browser_event.dart';
import 'package:magtapp/bloc/browser_state.dart';
import 'package:magtapp/screens/browser/browser_tabs_screen.dart';

class BrowserScreen extends StatefulWidget {
  const BrowserScreen({super.key});

  @override
  State<BrowserScreen> createState() => _BrowserScreenState();
}

class _BrowserScreenState extends State<BrowserScreen> {
  late final TextEditingController _urlController;

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

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<BrowserBloc, BrowserState>(
      listener: (context, state) {
        final activeTab = state.activeTab;
        if (activeTab != null && _urlController.text != activeTab.url) {
          if (!activeTab.isLoading) {
            _urlController.text = activeTab.url;
          }
        }
      },
      builder: (context, state) {
        final activeTab = state.activeTab;

        return Scaffold(
          appBar: AppBar(
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
                  prefixIcon: Icon(Icons.lock, size: 16, color: Colors.grey),
                ),
                onSubmitted: (value) {
                  if (activeTab != null) {
                    context.read<BrowserBloc>().add(
                      BrowserLoadUrl(id: activeTab.id, url: value),
                    );
                  } else {
                    context.read<BrowserBloc>().add(BrowserAddTab(url: value));
                  }
                },
              ),
            ),
            actions: [
              if (activeTab != null)
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => context.read<BrowserBloc>().add(
                    BrowserRefresh(activeTab.id),
                  ),
                ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const BrowserTabsScreen(),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: Text(
                      '${state.tabs.length}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
              // PopupMenuButton<String>(
              //   onSelected: (value) {
              //     // Handle menu options
              //   },
              //   itemBuilder: (BuildContext context) {
              //     return {'History', 'Bookmarks', 'Settings'}.map((
              //       String choice,
              //     ) {
              //       return PopupMenuItem<String>(
              //         value: choice,
              //         child: Text(choice),
              //       );
              //     }).toList();
              //   },
              // ),
            ],
          ),
          body: activeTab == null
              ? const Center(child: Text('No tabs open'))
              : Column(
                  children: [
                    if (activeTab.isLoading)
                      const LinearProgressIndicator(minHeight: 2),
                    Expanded(
                      child: activeTab.controller != null
                          ? WebViewWidget(controller: activeTab.controller!)
                          : const Center(child: CircularProgressIndicator()),
                    ),
                  ],
                ),
          bottomNavigationBar: BottomAppBar(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios),
                  onPressed: activeTab?.canGoBack == true
                      ? () => context.read<BrowserBloc>().add(
                          BrowserGoBack(activeTab!.id),
                        )
                      : null,
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios),
                  onPressed: activeTab?.canGoForward == true
                      ? () => context.read<BrowserBloc>().add(
                          BrowserGoForward(activeTab!.id),
                        )
                      : null,
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    context.read<BrowserBloc>().add(const BrowserAddTab());
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.home),
                  onPressed: () {
                    if (activeTab != null) {
                      context.read<BrowserBloc>().add(
                        BrowserLoadUrl(
                          id: activeTab.id,
                          url: 'https://www.google.com',
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
