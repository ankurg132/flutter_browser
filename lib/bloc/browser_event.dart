import 'package:equatable/equatable.dart';

abstract class BrowserEvent extends Equatable {
  const BrowserEvent();

  @override
  List<Object> get props => [];
}

class BrowserAddTab extends BrowserEvent {
  final String? url;
  const BrowserAddTab({this.url});
}

class BrowserCloseTab extends BrowserEvent {
  final String id;
  const BrowserCloseTab(this.id);

  @override
  List<Object> get props => [id];
}

class BrowserSetActiveTab extends BrowserEvent {
  final String id;
  const BrowserSetActiveTab(this.id);

  @override
  List<Object> get props => [id];
}

class BrowserLoadUrl extends BrowserEvent {
  final String id;
  final String url;
  const BrowserLoadUrl({required this.id, required this.url});

  @override
  List<Object> get props => [id, url];
}

class BrowserPageStarted extends BrowserEvent {
  final String id;
  final String url;
  const BrowserPageStarted({required this.id, required this.url});

  @override
  List<Object> get props => [id, url];
}

class BrowserPageFinished extends BrowserEvent {
  final String id;
  final String url;
  final String title;
  final bool canGoBack;
  final bool canGoForward;

  const BrowserPageFinished({
    required this.id,
    required this.url,
    required this.title,
    required this.canGoBack,
    required this.canGoForward,
  });

  @override
  List<Object> get props => [id, url, title, canGoBack, canGoForward];
}

class BrowserGoBack extends BrowserEvent {
  final String id;
  const BrowserGoBack(this.id);

  @override
  List<Object> get props => [id];
}

class BrowserGoForward extends BrowserEvent {
  final String id;
  const BrowserGoForward(this.id);

  @override
  List<Object> get props => [id];
}

class BrowserRefresh extends BrowserEvent {
  final String id;
  const BrowserRefresh(this.id);

  @override
  List<Object> get props => [id];
}
