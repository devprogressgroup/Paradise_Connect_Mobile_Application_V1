import 'package:progress_group/features/auth/data/models/permissions_model.dart';

class PermissionsHelper {
  static PermissionsModel? _model;

  static void init(PermissionsModel model) => _model = model;

  static void clear() => _model = null;

  static bool get isSuperadmin => _model?.isSuperadmin ?? false;

  static bool check(String formName, String featureName) {
    if (_model == null) return false;
    if (_model!.isSuperadmin) return true;
    for (final software in _model!.permissions) {
      for (final module in software.modules) {
        for (final form in module.forms) {
          if (form.formName == formName) {
            for (final feature in form.features) {
              if (feature.featureName == featureName) return feature.active;
            }
          }
        }
      }
    }
    return false;
  }

  // Returns raw API value: 1, 0, or null (not found / superadmin returns 1)
  static int? checkRaw(String formName, String featureName) {
    if (_model == null) return null;
    if (_model!.isSuperadmin) return 1;
    for (final software in _model!.permissions) {
      for (final module in software.modules) {
        for (final form in module.forms) {
          if (form.formName == formName) {
            for (final feature in form.features) {
              if (feature.featureName == featureName) return feature.activeRaw;
            }
          }
        }
      }
    }
    return null;
  }

  // Attendance
  static bool get canReadAttendance       => check('Attendance', 'ReadOnly');
  static bool get canClockInOffice                    => check('Attendance', 'ClockInOffice');
  static bool get canClockInPameran                   => check('Attendance', 'ClockInPameran');
  static bool get canClockOutOffice                   => check('Attendance', 'ClockOutOffice');
  static bool get canClockOutPameran                  => check('Attendance', 'ClockOutPameran');
  static bool get canApproveRejectAttendance          => check('Attendance', 'ApproveReject');

  static bool get canClockInLuarLokasi                => check('Attendance', 'ClockInLuarLokasi');
  static bool get canClockOutLuarLokasi               => check('Attendance', 'ClockOutLuarLokasi');
  static bool get canClockInLuarLokasiRequestApprove  => check('Attendance', 'ClockInLuarLokasiRequestApprove');
  static bool get canClockOutLuarLokasiRequestApprove => check('Attendance', 'ClockOuLuarLokasiRequestApprove');

  // Composite attendance permissions
  static bool get canClockIn  => canClockInOffice || canClockInPameran || canClockInLuarLokasi;
  static bool get canClockOut => canClockOutOffice || canClockOutPameran || canClockOutLuarLokasi;

  // true jika minimal satu fitur attendance aktif
  static bool get canAccessAttendance => canReadAttendance || canClockInOffice || canClockInPameran || canClockOutOffice || canClockOutPameran || canApproveRejectAttendance || canClockInLuarLokasi || canClockOutLuarLokasi || canClockInLuarLokasiRequestApprove || canClockOutLuarLokasiRequestApprove;

  // Attendance raw values
  static int? get rawReadAttendance                       => checkRaw('Attendance', 'ReadOnly');
  static int? get rawClockInOffice                        => checkRaw('Attendance', 'ClockInOffice');
  static int? get rawClockInPameran                       => checkRaw('Attendance', 'ClockInPameran');
  static int? get rawClockOutOffice                       => checkRaw('Attendance', 'ClockOutOffice');
  static int? get rawClockOutPameran                      => checkRaw('Attendance', 'ClockOutPameran');
  static int? get rawApproveAttendance                    => checkRaw('Attendance', 'ApproveReject');
  static int? get rawClockInLuarLokasi                    => checkRaw('Attendance', 'ClockInLuarLokasi');
  static int? get rawClockOutLuarLokasi                   => checkRaw('Attendance', 'ClockOutLuarLokasi');
  static int? get rawClockInLuarLokasiRequestApprove      => checkRaw('Attendance', 'ClockInLuarLokasiRequestApprove');
  static int? get rawClockOutLuarLokasiRequestApprove     => checkRaw('Attendance', 'ClockOuLuarLokasiRequestApprove');

  // Contacts
  static bool get canModifyContacts       => check('Contacts', 'Modify');
  static bool get canReadContacts         => check('Contacts', 'ReadOnly');
  static bool get canDeleteContacts       => check('Contacts', 'Delete');
  static bool get canModifyAttachment     => check('Contacts', 'ModifyAttachment');
  static bool get canDeleteAttachment     => check('Contacts', 'DeleteAttachment');

  // true jika minimal satu fitur contacts aktif
  static bool get canAccessContacts => canReadContacts || canModifyContacts || canDeleteContacts || canModifyAttachment || canDeleteAttachment;

  // Sales Kit
  static bool get canModifySalesKit       => check('Sales Kit', 'Modify');
  static bool get canReadSalesKit         => check('Sales Kit', 'ReadOnly');

  // true jika minimal satu fitur sales kit aktif
  static bool get canAccessSalesKit => canReadSalesKit || canModifySalesKit;

  // Site Plan
  static bool get canReadSitePlan         => check('Site Plan', 'ReadOnly');
  static bool get canAccessSitePlan       => canReadSitePlan;

  // Inbox
  static bool get canReadInbox            => check('Inbox', 'ReadOnly');
  static bool get canAccessInbox          => canReadInbox;
}
