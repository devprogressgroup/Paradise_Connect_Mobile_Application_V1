import 'package:equatable/equatable.dart';

class CaraBayarEntity extends Equatable {
  final int caraBayarId;
  final String name;

  const CaraBayarEntity({required this.caraBayarId, required this.name});

  @override
  List<Object?> get props => [caraBayarId, name];
}
