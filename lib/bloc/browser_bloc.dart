import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:webview_flutter/webview_flutter.dart';
// ignore: avoid_web_libraries_in_flutter
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'package:magtapp/bloc/browser_event.dart';
import 'package:magtapp/bloc/browser_state.dart';
import 'package:magtapp/models/browser_model.dart';
import 'package:magtapp/services/offline_service.dart';

import 'package:magtapp/repositories/file_repository.dart';

class BrowserBloc extends Bloc<BrowserEvent, BrowserState> {
  final OfflineService _offlineService;
  final FileRepository _fileRepository;

  BrowserBloc({OfflineService? offlineService, FileRepository? fileRepository})
    : _offlineService = offlineService ?? OfflineService(),
      _fileRepository = fileRepository ?? FileRepository(),
      super(const BrowserState()) {
    on<BrowserAddTab>(_onAddTab);
    on<BrowserCloseTab>(_onCloseTab);
    on<BrowserSetActiveTab>(_onSetActiveTab);
    on<BrowserLoadUrl>(_onLoadUrl);
    on<BrowserPageStarted>(_onPageStarted);
    on<BrowserPageFinished>(_onPageFinished);
    on<BrowserGoBack>(_onGoBack);
    on<BrowserGoForward>(_onGoForward);
    on<BrowserRefresh>(_onRefresh);
    on<BrowserDownloadFile>(_onDownloadFile);

    // Initialize with one tab
    add(const BrowserAddTab(url: 'https://www.google.com'));
  }

  Future<void> _onAddTab(
    BrowserAddTab event,
    Emitter<BrowserState> emit,
  ) async {
    final String newId = DateTime.now().millisecondsSinceEpoch.toString();
    final newTab = BrowserTab(
      id: newId,
      url: event.url ?? 'https://www.google.com',
      title: 'New Tab',
    );

    await _initializeController(newTab);

    final updatedTabs = List<BrowserTab>.from(state.tabs)..add(newTab);
    emit(state.copyWith(tabs: updatedTabs, activeTabId: newId));
  }

  Future<void> _onCloseTab(
    BrowserCloseTab event,
    Emitter<BrowserState> emit,
  ) async {
    if (state.tabs.length <= 1) {
      // Don't close the last tab, just reset it
      if (state.tabs.first.id == event.id) {
        add(BrowserLoadUrl(id: event.id, url: 'https://www.google.com'));
      }
      return;
    }

    final int indexToRemove = state.tabs.indexWhere(
      (tab) => tab.id == event.id,
    );
    if (indexToRemove == -1) return;

    final updatedTabs = List<BrowserTab>.from(state.tabs)
      ..removeAt(indexToRemove);
    String newActiveId = state.activeTabId;

    if (state.activeTabId == event.id) {
      if (indexToRemove > 0) {
        newActiveId = updatedTabs[indexToRemove - 1].id;
      } else {
        newActiveId = updatedTabs.first.id;
      }
    }

    emit(state.copyWith(tabs: updatedTabs, activeTabId: newActiveId));
  }

  void _onSetActiveTab(BrowserSetActiveTab event, Emitter<BrowserState> emit) {
    if (state.tabs.any((tab) => tab.id == event.id)) {
      emit(state.copyWith(activeTabId: event.id));
    }
  }

  Future<void> _onLoadUrl(
    BrowserLoadUrl event,
    Emitter<BrowserState> emit,
  ) async {
    final tab = state.tabs.firstWhere((t) => t.id == event.id);
    String url = event.url.trim();

    // Simple heuristic to determine if it's a URL or a search query
    bool isUrl = false;
    if (!url.contains(' ') && url.contains('.')) {
      isUrl = true;
    }

    if (isUrl) {
      if (!url.startsWith('http')) {
        url = 'https://$url';
      }
    } else {
      url = 'https://www.google.com/search?q=${Uri.encodeComponent(url)}';
    }

    final isOffline = await _offlineService.isOffline();
    if (isOffline) {
      final cachedContent = await _offlineService.getPageContent(url);
      if (cachedContent != null) {
        tab.controller?.loadHtmlString(cachedContent, baseUrl: url);
        // Manually trigger page finished since loadHtmlString might not trigger it exactly as we want for "url" tracking
        // But typically it does trigger navigation events.
        // We might need to handle the "Offline Mode" indicator here or in the UI based on connectivity.
      } else {
        // Load error page or show snackbar (handled in UI usually, but we can load a data URI)
        tab.controller?.loadHtmlString(
          '<html><body><h1>Offline</h1><p>No cached version available for this page.</p></body></html>',
        );
      }
    } else {
      tab.controller?.loadRequest(Uri.parse(url));
    }
  }

  void _onPageStarted(BrowserPageStarted event, Emitter<BrowserState> emit) {
    final tabIndex = state.tabs.indexWhere((t) => t.id == event.id);
    if (tabIndex != -1) {
      final updatedTab = state.tabs[tabIndex].copyWith(
        isLoading: true,
        url: event.url,
      );
      final updatedTabs = List<BrowserTab>.from(state.tabs);
      updatedTabs[tabIndex] = updatedTab;
      emit(state.copyWith(tabs: updatedTabs));
    }
  }

  Future<void> _onPageFinished(
    BrowserPageFinished event,
    Emitter<BrowserState> emit,
  ) async {
    final tabIndex = state.tabs.indexWhere((t) => t.id == event.id);
    if (tabIndex != -1) {
      final updatedTab = state.tabs[tabIndex].copyWith(
        isLoading: false,
        url: event.url,
        title: event.title,
        canGoBack: event.canGoBack,
        canGoForward: event.canGoForward,
      );
      final updatedTabs = List<BrowserTab>.from(state.tabs);
      updatedTabs[tabIndex] = updatedTab;
      emit(state.copyWith(tabs: updatedTabs));

      // Save history
      if (event.url.isNotEmpty && event.url != 'about:blank') {
        await _offlineService.saveHistory(event.url, event.title);
      }

      // Cache page content if online
      if (!(await _offlineService.isOffline())) {
        final controller = state.tabs[tabIndex].controller;
        if (controller != null) {
          try {
            // Get HTML content. Note: getting full HTML via JS might be heavy or restricted.
            // document.documentElement.outerHTML is a common way.
            final html = await controller.runJavaScriptReturningResult(
              'document.documentElement.outerHTML',
            );
            String htmlString = html.toString();
            // Cleanup quotes if needed (runJavaScriptReturningResult returns JSON encoded string)
            if (htmlString.startsWith('"') && htmlString.endsWith('"')) {
              htmlString = htmlString.substring(1, htmlString.length - 1);
            }
            // Unescape standard JSON escapes
            htmlString = htmlString
                .replaceAll('\\n', '\n')
                .replaceAll('\\"', '"')
                .replaceAll('\\t', '\t');

            await _offlineService.savePageContent(event.url, htmlString);
          } catch (e) {
            print('Failed to cache page: $e');
          }
        }
      }
    }
  }

  void _onGoBack(BrowserGoBack event, Emitter<BrowserState> emit) {
    final tab = state.tabs.firstWhere((t) => t.id == event.id);
    tab.controller?.goBack();
  }

  void _onGoForward(BrowserGoForward event, Emitter<BrowserState> emit) {
    final tab = state.tabs.firstWhere((t) => t.id == event.id);
    tab.controller?.goForward();
  }

  void _onRefresh(BrowserRefresh event, Emitter<BrowserState> emit) {
    final tab = state.tabs.firstWhere((t) => t.id == event.id);
    tab.controller?.reload();
  }

  Future<void> _onDownloadFile(
    BrowserDownloadFile event,
    Emitter<BrowserState> emit,
  ) async {
    emit(state.copyWith(message: 'Downloading ${event.suggestedFilename}...'));

    final path = await _fileRepository.downloadFile(
      event.url,
      event.suggestedFilename,
    );

    if (path != null) {
      emit(
        state.copyWith(
          message: 'Download complete: ${event.suggestedFilename}',
        ),
      );
    } else {
      emit(state.copyWith(message: 'Download failed'));
    }
  }

  Future<void> _initializeController(BrowserTab tab) async {
    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    final WebViewController controller =
        WebViewController.fromPlatformCreationParams(params);

    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Update loading progress if needed
          },
          onPageStarted: (String url) {
            add(BrowserPageStarted(id: tab.id, url: url));
          },
          onPageFinished: (String url) async {
            final title = await controller.getTitle() ?? 'New Tab';
            final canGoBack = await controller.canGoBack();
            final canGoForward = await controller.canGoForward();
            add(
              BrowserPageFinished(
                id: tab.id,
                url: url,
                title: title,
                canGoBack: canGoBack,
                canGoForward: canGoForward,
              ),
            );
          },
          onWebResourceError: (WebResourceError error) {
            // Handle error
          },
          onNavigationRequest: (NavigationRequest request) {
            final uri = Uri.parse(request.url);
            final path = uri.path.toLowerCase();

            if (path.endsWith('.mp4') ||
                path.endsWith('.mp3') ||
                path.endsWith('.pdf') ||
                path.endsWith('.zip') ||
                path.endsWith('.apk') ||
                path.endsWith('.png') ||
                path.endsWith('.jpg') ||
                path.endsWith('.jpeg')) {
              add(
                BrowserDownloadFile(
                  url: request.url,
                  suggestedFilename: path.split('/').last,
                ),
              );
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(tab.url));

    if (controller.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(true);
      (controller.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
    }

    tab.controller = controller;
  }
}
