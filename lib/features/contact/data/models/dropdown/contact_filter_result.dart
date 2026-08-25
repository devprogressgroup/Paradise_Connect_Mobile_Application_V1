import 'package:dartz/dartz.dart';
import 'package:progress_group/features/contact/data/arguments/contact_dropdown_args.dart';
import 'package:progress_group/features/contact/domain/entities/dropdown_option.dart';

typedef PaginatedOptions = ({List<DropdownOption> data, int lastPage, int total});
typedef PaginatedFetch = Future<Either<String, PaginatedOptions>> Function({required int page, int perPage, String? search});

/// Grup checkbox filter yang datanya diambil bertahap (infinite scroll + search
/// di server), bukan dimuat penuh di depan — dipakai untuk daftar besar (mis.
/// Sales Channel Detail 600+ baris, atau hierarki sales Owner/Executive/dst yang
/// scope-nya dari backend, bukan diturunkan dari data /me profile).
class PaginatedCheckGroup {
  final String key;
  final String label;
  final String section;
  final PaginatedFetch fetchPage;
  const PaginatedCheckGroup({
    required this.key,
    required this.label,
    required this.section,
    required this.fetchPage,
  });
}

class DateRangeValue {
  final String label;
  final String start;
  final String end;
  const DateRangeValue({required this.label, required this.start, required this.end});
}

class ContactCheckGroup {
  final String key;
  final String label;
  final String? section;
  final bool searchable;
  final List<OwnerDropdownItem> items;
  const ContactCheckGroup({
    required this.key,
    required this.label,
    required this.section,
    required this.searchable,
    required this.items,
  });
}

class ContactFilterResult {
  final Set<int> statusIds;
  final Set<int> channelIds;
  final Set<int> channelDetailIds;
  final Set<int> ownerIds;
  final Set<int> executiveIds;
  final Set<int> supervisorIds;
  final Set<int> managerIds;
  final Set<int> generalManagerIds;
  final Set<int> teamIds;
  final DateRangeValue? createDate;
  final DateRangeValue? apptDate;
  final DateRangeValue? visitDate;
  final DateRangeValue? reserveDate;
  final DateRangeValue? spDate;
  final DateRangeValue? lostDate;
  final String? project;

  const ContactFilterResult({
    required this.statusIds,
    required this.channelIds,
    required this.channelDetailIds,
    required this.ownerIds,
    required this.executiveIds,
    required this.supervisorIds,
    required this.managerIds,
    required this.generalManagerIds,
    required this.teamIds,
    required this.createDate,
    required this.apptDate,
    required this.visitDate,
    required this.reserveDate,
    required this.spDate,
    required this.lostDate,
    required this.project,
  });
}

const kContactProjectOptions = [
  'Paradise Resort City',
  'Paradise Serpong City',
  'Paradise Serpong City 2',
];
