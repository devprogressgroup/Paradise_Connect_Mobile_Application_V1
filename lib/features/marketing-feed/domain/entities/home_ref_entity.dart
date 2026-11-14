import 'package:equatable/equatable.dart';

/// Satu baris urutan Home dari server: type = "post" atau "fame", id = id kiriman / juara.
class HomeRefEntity extends Equatable {
  final String type;
  final int id;

  const HomeRefEntity({required this.type, required this.id});

  @override
  List<Object?> get props => [type, id];
}
