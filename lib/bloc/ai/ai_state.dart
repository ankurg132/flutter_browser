import 'package:equatable/equatable.dart';

enum AIStatus { initial, loading, success, failure }

class AIState extends Equatable {
  final AIStatus status;
  final String? result; // Deprecated, use summary or translation
  final String? summary;
  final String? translation;
  final String? selectedLanguage;
  final String? error;

  const AIState({
    this.status = AIStatus.initial,
    this.result,
    this.summary,
    this.translation,
    this.selectedLanguage,
    this.error,
  });

  AIState copyWith({
    AIStatus? status,
    String? result,
    String? summary,
    String? translation,
    String? selectedLanguage,
    String? error,
  }) {
    return AIState(
      status: status ?? this.status,
      result: result ?? this.result,
      summary: summary ?? this.summary,
      translation: translation ?? this.translation,
      selectedLanguage: selectedLanguage ?? this.selectedLanguage,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [
    status,
    result,
    summary,
    translation,
    selectedLanguage,
    error,
  ];
}
