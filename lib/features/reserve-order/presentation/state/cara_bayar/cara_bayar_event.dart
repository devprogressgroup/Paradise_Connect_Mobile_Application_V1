import 'package:equatable/equatable.dart';

abstract class CaraBayarEvent extends Equatable {
  const CaraBayarEvent();

  @override
  List<Object?> get props => [];
}

class FetchCaraBayarEvent extends CaraBayarEvent {
  const FetchCaraBayarEvent();
}
