import 'package:equatable/equatable.dart';

abstract class AIEvent extends Equatable {
  const AIEvent();

  @override
  List<Object> get props => [];
}

class AISummarizePage extends AIEvent {
  final String text;
  const AISummarizePage(this.text);

  @override
  List<Object> get props => [text];
}

class AITranslatePage extends AIEvent {
  final String text;
  final String targetLanguage;
  const AITranslatePage(this.text, this.targetLanguage);

  @override
  List<Object> get props => [text, targetLanguage];
}

class AIClearResult extends AIEvent {}
