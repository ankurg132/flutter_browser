import 'package:webview_flutter/webview_flutter.dart';

class BrowserTab {
  final String id;
  String url;
  String title;
  WebViewController? controller;
  bool isLoading;
  bool canGoBack;
  bool canGoForward;

  BrowserTab({
    required this.id,
    required this.url,
    this.title = 'New Tab',
    this.controller,
    this.isLoading = true,
    this.canGoBack = false,
    this.canGoForward = false,
  });

  BrowserTab copyWith({
    String? id,
    String? url,
    String? title,
    WebViewController? controller,
    bool? isLoading,
    bool? canGoBack,
    bool? canGoForward,
  }) {
    return BrowserTab(
      id: id ?? this.id,
      url: url ?? this.url,
      title: title ?? this.title,
      controller: controller ?? this.controller,
      isLoading: isLoading ?? this.isLoading,
      canGoBack: canGoBack ?? this.canGoBack,
      canGoForward: canGoForward ?? this.canGoForward,
    );
  }
}
