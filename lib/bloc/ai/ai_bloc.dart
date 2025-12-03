import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:magtapp/bloc/ai/ai_event.dart';
import 'package:magtapp/bloc/ai/ai_state.dart';
import 'package:magtapp/services/ai_service.dart';

class AIBloc extends Bloc<AIEvent, AIState> {
  final AIService _aiService;

  AIBloc({required AIService aiService})
    : _aiService = aiService,
      super(const AIState()) {
    on<AISummarizePage>(_onSummarizePage);
    on<AITranslatePage>(_onTranslatePage);
    on<AIClearResult>(_onClearResult);
  }

  Future<void> _onSummarizePage(
    AISummarizePage event,
    Emitter<AIState> emit,
  ) async {
    emit(state.copyWith(status: AIStatus.loading));
    try {
      final result = await _aiService.summarizeText(event.text);
      emit(state.copyWith(status: AIStatus.success, result: result));
    } catch (e) {
      emit(state.copyWith(status: AIStatus.failure, error: e.toString()));
    }
  }

  Future<void> _onTranslatePage(
    AITranslatePage event,
    Emitter<AIState> emit,
  ) async {
    emit(state.copyWith(status: AIStatus.loading));
    try {
      final result = await _aiService.translateText(
        event.text,
        event.targetLanguage,
      );
      emit(state.copyWith(status: AIStatus.success, result: result));
    } catch (e) {
      emit(state.copyWith(status: AIStatus.failure, error: e.toString()));
    }
  }

  void _onClearResult(AIClearResult event, Emitter<AIState> emit) {
    emit(const AIState(status: AIStatus.initial));
  }
}
