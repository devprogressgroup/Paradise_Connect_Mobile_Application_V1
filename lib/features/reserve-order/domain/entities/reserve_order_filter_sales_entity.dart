import 'package:progress_group/features/contact/domain/entities/dropdown_option.dart';

/// Pilihan filter Sales untuk list Reserve Order — hasil `GET /reserve-order/filter-sales`
/// (data langsung, BUKAN paginasi). Setiap key = satu dropdown di ContactFilterSheet.
class ReserveOrderFilterSalesEntity {
  final List<DropdownOption> owner;
  final List<DropdownOption> salesExecutive;
  final List<DropdownOption> salesSupervisor;
  final List<DropdownOption> salesManager;
  final List<DropdownOption> generalManager;
  final List<DropdownOption> salesTeam;

  const ReserveOrderFilterSalesEntity({
    required this.owner,
    required this.salesExecutive,
    required this.salesSupervisor,
    required this.salesManager,
    required this.generalManager,
    required this.salesTeam,
  });
}
