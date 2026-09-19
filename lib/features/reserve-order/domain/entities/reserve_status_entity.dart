import 'package:equatable/equatable.dart';

class ReserveStatusEntity extends Equatable {
  final int statusReserveId;
  final String statusReserveName;
  final String displayName;

  const ReserveStatusEntity({
    required this.statusReserveId,
    required this.statusReserveName,
    required this.displayName,
  });

  @override
  List<Object?> get props => [statusReserveId, statusReserveName, displayName];
}
