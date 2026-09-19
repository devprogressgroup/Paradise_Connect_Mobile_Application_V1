import 'package:equatable/equatable.dart';

abstract class WorkCategoryEvent extends Equatable {
  const WorkCategoryEvent();

  @override
  List<Object?> get props => [];
}

class FetchWorkCategoryEvent extends WorkCategoryEvent {
  const FetchWorkCategoryEvent();
}
