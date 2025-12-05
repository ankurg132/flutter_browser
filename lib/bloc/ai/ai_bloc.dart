import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:magtapp/bloc/ai/ai_event.dart';
import 'package:magtapp/bloc/ai/ai_state.dart';
import 'package:magtapp/services/ai_service.dart';
import 'package:magtapp/services/offline_service.dart';

class AIBloc extends Bloc<AIEvent, AIState> {
  final AIService _aiService;
  final OfflineService _offlineService;

  AIBloc({required AIService aiService, OfflineService? offlineService})
    : _aiService = aiService,
      _offlineService = offlineService ?? OfflineService(),
      super(const AIState()) {
    on<AISummarizePage>(_onSummarizePage);
    on<AITranslatePage>(_onTranslatePage);
    on<AILoadSummary>(_onLoadSummary);
    on<AIClearResult>(_onClearResult);
  }

  Future<void> _onLoadSummary(
    AILoadSummary event,
    Emitter<AIState> emit,
  ) async {
    emit(state.copyWith(status: AIStatus.loading));
    try {
      final cachedSummary = await _offlineService.getAIResult(
        event.url,
        'summary',
      );
      if (cachedSummary != null) {
        emit(
          state.copyWith(
            status: AIStatus.success,
            result: cachedSummary,
            summary: cachedSummary,
            translation: null, // Reset translation when loading new summary
          ),
        );
      } else {
        emit(const AIState(status: AIStatus.initial));
      }
    } catch (e) {
      emit(const AIState(status: AIStatus.initial));
    }
  }

  Future<void> _onSummarizePage(
    AISummarizePage event,
    Emitter<AIState> emit,
  ) async {
    emit(state.copyWith(status: AIStatus.loading));
    try {
      final isOffline = await _offlineService.isOffline();
      if (isOffline) {
        final cachedResult = await _offlineService.getAIResult(
          event.url,
          'summary',
        );
        if (cachedResult != null) {
          emit(
            state.copyWith(
              status: AIStatus.success,
              result: cachedResult,
              summary: cachedResult,
            ),
          );
          return;
        }
        // If offline and no cache, we might want to show an error or just fail
      }

      final result = await _aiService.summarizeText(event.text);
      emit(
        state.copyWith(
          status: AIStatus.success,
          result: result,
          summary: result,
        ),
      );

      // Cache result
      await _offlineService.saveAIResult(event.url, 'summary', result);
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
      final isOffline = await _offlineService.isOffline();
      if (isOffline) {
        final cachedResult = await _offlineService.getAIResult(
          event.url,
          'translation_${event.targetLanguage}',
        );
        if (cachedResult != null) {
          emit(
            state.copyWith(
              status: AIStatus.success,
              translation: cachedResult,
              selectedLanguage: event.targetLanguage,
            ),
          );
          return;
        }
      }

      final result = await _aiService.translateText(
        event.text,
        event.targetLanguage,
      );
      emit(
        state.copyWith(
          status: AIStatus.success,
          translation: result,
          selectedLanguage: event.targetLanguage,
        ),
      );

      // Cache result
      await _offlineService.saveAIResult(
        event.url,
        'translation_${event.targetLanguage}',
        result,
      );
    } catch (e) {
      emit(state.copyWith(status: AIStatus.failure, error: e.toString()));
    }
  }

  void _onClearResult(AIClearResult event, Emitter<AIState> emit) {
    emit(const AIState(status: AIStatus.initial));
  }
}
