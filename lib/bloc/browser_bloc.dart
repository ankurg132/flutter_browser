import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:webview_flutter/webview_flutter.dart';
// ignore: avoid_web_libraries_in_flutter
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'package:magtapp/bloc/browser_event.dart';
import 'package:magtapp/bloc/browser_state.dart';
import 'package:magtapp/models/browser_model.dart';

class BrowserBloc extends Bloc<BrowserEvent, BrowserState> {
  BrowserBloc() : super(const BrowserState()) {
    on<BrowserAddTab>(_onAddTab);
    on<BrowserCloseTab>(_onCloseTab);
    on<BrowserSetActiveTab>(_onSetActiveTab);
    on<BrowserLoadUrl>(_onLoadUrl);
    on<BrowserPageStarted>(_onPageStarted);
    on<BrowserPageFinished>(_onPageFinished);
    on<BrowserGoBack>(_onGoBack);
    on<BrowserGoForward>(_onGoForward);
    on<BrowserRefresh>(_onRefresh);

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

  void _onLoadUrl(BrowserLoadUrl event, Emitter<BrowserState> emit) {
    final tab = state.tabs.firstWhere((t) => t.id == event.id);
    String url = event.url;
    if (!url.startsWith('http')) {
      url = 'https://$url';
    }
    tab.controller?.loadRequest(Uri.parse(url));
    // State update will happen via PageStarted/Finished events
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

  void _onPageFinished(BrowserPageFinished event, Emitter<BrowserState> emit) {
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
