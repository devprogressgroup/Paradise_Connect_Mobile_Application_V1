import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:progress_group/features/contact/domain/entities/dropdown_option.dart';
import 'package:progress_group/features/contact/domain/usecases/info_source/get_sales_channel_details_usecase.dart';
import 'package:progress_group/features/contact/domain/usecases/sales_hierarchy/get_sales_executives_usecase.dart';
import 'package:progress_group/features/contact/domain/usecases/sales_hierarchy/get_sales_general_managers_usecase.dart';
import 'package:progress_group/features/contact/domain/usecases/sales_hierarchy/get_sales_managers_usecase.dart';
import 'package:progress_group/features/contact/domain/usecases/sales_hierarchy/get_sales_owners_usecase.dart';
import 'package:progress_group/features/contact/domain/usecases/sales_hierarchy/get_sales_supervisors_usecase.dart';
import 'package:progress_group/features/contact/domain/usecases/sales_hierarchy/get_sales_teams_paginated_usecase.dart';

typedef PaginatedOptions = ({List<DropdownOption> data, int lastPage, int total});

/// Facade cubit (tidak pernah emit state) yang menyatukan usecase dropdown filter
/// contact-list yang butuh pagination — hierarki sales (Owner/Executive/Supervisor/
/// Manager/GM/Team) + Sales Channel Detail (master data) — di satu tempat yang bisa
/// diakses lewat context.read. Semua dedicated endpoint sendiri-sendiri, BUKAN
/// diturunkan dari data /me (profile), sesuai permintaan agar filter tidak dicampur
/// dengan endpoint profile. State pagination-nya sendiri (page/search/dst) dikelola
/// lokal di widget accordion masing-masing, bukan di sini.
class SalesHierarchyService extends Cubit<Object?> {
  final GetSalesOwnersUseCase getSalesOwnersUseCase;
  final GetSalesExecutivesUseCase getSalesExecutivesUseCase;
  final GetSalesSupervisorsUseCase getSalesSupervisorsUseCase;
  final GetSalesManagersUseCase getSalesManagersUseCase;
  final GetSalesGeneralManagersUseCase getSalesGeneralManagersUseCase;
  final GetSalesTeamsPaginatedUseCase getSalesTeamsPaginatedUseCase;
  final GetSalesChannelDetailsUseCase getSalesChannelDetailsUseCase;

  SalesHierarchyService({
    required this.getSalesOwnersUseCase,
    required this.getSalesExecutivesUseCase,
    required this.getSalesSupervisorsUseCase,
    required this.getSalesManagersUseCase,
    required this.getSalesGeneralManagersUseCase,
    required this.getSalesTeamsPaginatedUseCase,
    required this.getSalesChannelDetailsUseCase,
  }) : super(null);

  Future<Either<String, PaginatedOptions>> channelDetail({int page = 1, int perPage = 30, String? search}) =>
      getSalesChannelDetailsUseCase(page: page, perPage: perPage, search: search);

  Future<Either<String, PaginatedOptions>> owners({int page = 1, int perPage = 20, String? search}) =>
      getSalesOwnersUseCase(page: page, perPage: perPage, search: search);

  Future<Either<String, PaginatedOptions>> executives({int page = 1, int perPage = 20, String? search}) =>
      getSalesExecutivesUseCase(page: page, perPage: perPage, search: search);

  Future<Either<String, PaginatedOptions>> supervisors({int page = 1, int perPage = 20, String? search}) =>
      getSalesSupervisorsUseCase(page: page, perPage: perPage, search: search);

  Future<Either<String, PaginatedOptions>> managers({int page = 1, int perPage = 20, String? search}) =>
      getSalesManagersUseCase(page: page, perPage: perPage, search: search);

  Future<Either<String, PaginatedOptions>> generalManagers({int page = 1, int perPage = 20, String? search}) =>
      getSalesGeneralManagersUseCase(page: page, perPage: perPage, search: search);

  Future<Either<String, PaginatedOptions>> teams({int page = 1, int perPage = 20, String? search}) =>
      getSalesTeamsPaginatedUseCase(page: page, perPage: perPage, search: search);
}
