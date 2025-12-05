import 'package:equatable/equatable.dart';
import 'package:magtapp/models/browser_model.dart';

class BrowserState extends Equatable {
  final List<BrowserTab> tabs;
  final String activeTabId;
  final String? message;

  const BrowserState({
    this.tabs = const [],
    this.activeTabId = '',
    this.message,
  });

  BrowserTab? get activeTab {
    try {
      return tabs.firstWhere((tab) => tab.id == activeTabId);
    } catch (e) {
      return null;
    }
  }

  BrowserState copyWith({
    List<BrowserTab>? tabs,
    String? activeTabId,
    String? message,
  }) {
    return BrowserState(
      tabs: tabs ?? this.tabs,
      activeTabId: activeTabId ?? this.activeTabId,
      message: message,
    );
  }

  @override
  List<Object?> get props => [tabs, activeTabId, message];
}
