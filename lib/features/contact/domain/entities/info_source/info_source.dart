import 'package:equatable/equatable.dart';

class InfoSource extends Equatable {
  final int id;
  final String name;
  final String typeData;
  final int? periodePameranId;
  final bool isPameran;

  const InfoSource({
    required this.id,
    required this.name,
    required this.typeData,
    this.periodePameranId,
    this.isPameran = false,
  });

  @override
  List<Object?> get props => [id, name, typeData, periodePameranId, isPameran];
}