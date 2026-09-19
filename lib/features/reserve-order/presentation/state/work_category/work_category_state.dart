import 'package:equatable/equatable.dart';

enum WorkCategoryStatus { initial, loading, loaded, error }

class WorkCategoryState extends Equatable {
  final WorkCategoryStatus status;
  final List<String> items;
  final String? errorMessage;

  const WorkCategoryState({
    this.status = WorkCategoryStatus.initial,
    this.items = const [],
    this.errorMessage,
  });

  WorkCategoryState copyWith({
    WorkCategoryStatus? status,
    List<String>? items,
    String? errorMessage,
  }) {
    return WorkCategoryState(
      status: status ?? this.status,
      items: items ?? this.items,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, items, errorMessage];
}
