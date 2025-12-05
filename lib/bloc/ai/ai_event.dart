import 'package:equatable/equatable.dart';

abstract class AIEvent extends Equatable {
  const AIEvent();

  @override
  List<Object> get props => [];
}

class AISummarizePage extends AIEvent {
  final String text;
  final String url;
  const AISummarizePage(this.text, this.url);

  @override
  List<Object> get props => [text, url];
}

class AITranslatePage extends AIEvent {
  final String text;
  final String targetLanguage;
  final String url;
  const AITranslatePage(this.text, this.targetLanguage, this.url);

  @override
  List<Object> get props => [text, targetLanguage, url];
}

class AILoadSummary extends AIEvent {
  final String url;
  const AILoadSummary(this.url);

  @override
  List<Object> get props => [url];
}

class AIClearResult extends AIEvent {}
