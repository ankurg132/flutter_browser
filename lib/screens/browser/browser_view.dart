import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:magtapp/bloc/browser_bloc.dart';
import 'package:magtapp/bloc/browser_state.dart';
import 'package:magtapp/bloc/ai/ai_bloc.dart';
import 'package:magtapp/bloc/ai/ai_state.dart';
import 'package:magtapp/bloc/ai/ai_event.dart';
import 'package:magtapp/widgets/collapsible_summary_panel.dart';

class BrowserView extends StatelessWidget {
  const BrowserView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BrowserBloc, BrowserState>(
      builder: (context, state) {
        final activeTab = state.activeTab;

        if (activeTab == null) {
          return const Center(child: Text('No tabs open'));
        }

        return Column(
          children: [
            if (activeTab.isLoading)
              const LinearProgressIndicator(minHeight: 2),
            Expanded(
              child: Stack(
                children: [
                  activeTab.controller != null
                      ? WebViewWidget(controller: activeTab.controller!)
                      : const Center(child: CircularProgressIndicator()),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: BlocBuilder<AIBloc, AIState>(
                      builder: (context, aiState) {
                        return CollapsibleSummaryPanel(
                          summary: aiState.summary ?? aiState.result ?? '',
                          translation: aiState.translation,
                          originalText: '',
                          isLoading: aiState.status == AIStatus.loading,
                          error: aiState.status == AIStatus.failure
                              ? aiState.error
                              : null,
                          onSummarize: () async {
                            if (activeTab.controller != null) {
                              final result = await activeTab.controller!
                                  .runJavaScriptReturningResult(
                                    'document.body.innerText',
                                  );
                              String text = result.toString();
                              if (text.startsWith('"') && text.endsWith('"')) {
                                text = text.substring(1, text.length - 1);
                              }
                              text = text
                                  .replaceAll('\\n', '\n')
                                  .replaceAll('\\"', '"');

                              if (context.mounted) {
                                context.read<AIBloc>().add(
                                  AISummarizePage(text, activeTab.url),
                                );
                              }
                            }
                          },
                          onTranslate: (language) {
                            final textToTranslate =
                                aiState.summary ?? aiState.result;
                            if (textToTranslate != null &&
                                textToTranslate.isNotEmpty) {
                              context.read<AIBloc>().add(
                                AITranslatePage(
                                  textToTranslate,
                                  language,
                                  activeTab.url,
                                ),
                              );
                            }
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
