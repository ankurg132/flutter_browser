import 'package:equatable/equatable.dart';

enum AIStatus { initial, loading, success, failure }

class AIState extends Equatable {
  final AIStatus status;
  final String? result;
  final String? error;

  const AIState({this.status = AIStatus.initial, this.result, this.error});

  AIState copyWith({AIStatus? status, String? result, String? error}) {
    return AIState(
      status: status ?? this.status,
      result: result ?? this.result,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [status, result, error];
}
