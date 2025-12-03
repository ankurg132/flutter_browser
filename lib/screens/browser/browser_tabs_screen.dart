import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:magtapp/bloc/browser_bloc.dart';
import 'package:magtapp/bloc/browser_event.dart';
import 'package:magtapp/bloc/browser_state.dart';

class BrowserTabsScreen extends StatelessWidget {
  const BrowserTabsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tabs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              context.read<BrowserBloc>().add(const BrowserAddTab());
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: BlocBuilder<BrowserBloc, BrowserState>(
        builder: (context, state) {
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.8,
            ),
            itemCount: state.tabs.length,
            itemBuilder: (context, index) {
              final tab = state.tabs[index];
              final isActive = tab.id == state.activeTabId;

              return InkWell(
                onTap: () {
                  context.read<BrowserBloc>().add(BrowserSetActiveTab(tab.id));
                  Navigator.pop(context);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isActive ? Colors.blue : Colors.grey.shade300,
                      width: isActive ? 2 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(11),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                tab.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                context.read<BrowserBloc>().add(
                                  BrowserCloseTab(tab.id),
                                );
                              },
                              child: const Icon(Icons.close, size: 16),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Container(
                          color: Colors.grey[50],
                          child: const Center(
                            child: Icon(
                              Icons.web,
                              size: 48,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          tab.url,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
