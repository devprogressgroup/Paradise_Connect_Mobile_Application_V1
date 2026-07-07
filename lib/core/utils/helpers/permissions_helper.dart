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

  static bool checkScoped(String formName, String action) {
    return check(formName, '${action}Own') ||
        check(formName, '${action}Team') ||
        check(formName, '${action}Any');
  }

  static bool checkScopedAttachment(String action) {
    return check('Contacts', '${action}OwnAttachment') ||
        check('Contacts', '${action}TeamAttachment') ||
        check('Contacts', '${action}AnyAttachment');
  }

  static String scopeLevel(String formName, String action) {
    if (isSuperadmin) return 'any';
    if (check(formName, '${action}Any')) return 'any';
    if (check(formName, '${action}Team')) return 'team';
    if (check(formName, '${action}Own')) return 'own';
    return 'none';
  }

  static bool get canReadAttendance       => checkScoped('Attendance', 'ReadOnly');
  static bool get canClockInOffice                    => check('Attendance', 'ClockInOffice');
  static bool get canClockInPameran                   => check('Attendance', 'ClockInPameran');
  static bool get canClockOutOffice                   => check('Attendance', 'ClockOutOffice');
  static bool get canClockOutPameran                  => check('Attendance', 'ClockOutPameran');
  static bool get canApproveRejectAttendance          => check('Attendance', 'ApproveReject');
  static bool get canCheckInVerify                    => check('Attendance', 'CheckInVerify');

  static bool get canClockInLuarLokasi                => check('Attendance', 'ClockInLuarLokasi');
  static bool get canClockOutLuarLokasi               => check('Attendance', 'ClockOutLuarLokasi');
  static bool get canClockInLuarLokasiRequestApprove  => check('Attendance', 'ClockInLuarLokasiRequestApprove');
  static bool get canClockOutLuarLokasiRequestApprove => check('Attendance', 'ClockOutLuarLokasiRequestApprove');

  static bool get canClockIn  => canClockInOffice || canClockInPameran || canClockInLuarLokasi;
  static bool get canClockOut => canClockOutOffice || canClockOutPameran || canClockOutLuarLokasi;

  static bool get canAccessAttendance => canReadAttendance || canClockInOffice || canClockInPameran || canClockOutOffice || canClockOutPameran || canApproveRejectAttendance || canCheckInVerify || canClockInLuarLokasi || canClockOutLuarLokasi || canClockInLuarLokasiRequestApprove || canClockOutLuarLokasiRequestApprove;

  static int? get rawReadAttendance                       => canReadAttendance ? 1 : 0;
  static int? get rawClockInOffice                        => checkRaw('Attendance', 'ClockInOffice');
  static int? get rawClockInPameran                       => checkRaw('Attendance', 'ClockInPameran');
  static int? get rawClockOutOffice                       => checkRaw('Attendance', 'ClockOutOffice');
  static int? get rawClockOutPameran                      => checkRaw('Attendance', 'ClockOutPameran');
  static int? get rawApproveAttendance                    => checkRaw('Attendance', 'ApproveReject');
  static int? get rawClockInLuarLokasi                    => checkRaw('Attendance', 'ClockInLuarLokasi');
  static int? get rawClockOutLuarLokasi                   => checkRaw('Attendance', 'ClockOutLuarLokasi');
  static int? get rawClockInLuarLokasiRequestApprove      => checkRaw('Attendance', 'ClockInLuarLokasiRequestApprove');
  static int? get rawClockOutLuarLokasiRequestApprove     => checkRaw('Attendance', 'ClockOutLuarLokasiRequestApprove');

  static bool get canModifyContacts       => checkScoped('Contacts', 'Modify');
  static bool get canDeleteContacts       => checkScoped('Contacts', 'Delete');
  static bool get canReadContacts         => checkScoped('Contacts', 'ReadOnly') || canModifyContacts || canDeleteContacts;
  static bool get canModifyAttachment     => checkScopedAttachment('Modify');
  static bool get canDeleteAttachment     => checkScopedAttachment('Delete');

  static bool get canAccessContacts => canReadContacts || canModifyContacts || canDeleteContacts || canModifyAttachment || canDeleteAttachment;

  static bool get canCreateContact => canModifyContacts;
  static bool get canEditContact   => canModifyContacts;
  static bool get canDeleteContact => canDeleteContacts;

  static bool get canUploadAttachment     => canModifyContacts || canModifyAttachment;
  static bool get canEditAttachmentItem   => canModifyContacts || canModifyAttachment;
  static bool get canDeleteAttachmentItem => canModifyContacts || canDeleteAttachment;
  static bool get canViewAttachment       => canModifyContacts || canModifyAttachment || canDeleteAttachment || canReadContacts;

  static bool get canModifySalesKit       => check('Sales Kit', 'Modify');
  static bool get canReadSalesKit         => check('Sales Kit', 'ReadOnly');

  static bool get canAccessSalesKit => canReadSalesKit || canModifySalesKit;

  static bool get canReadSitePlan         => check('Site Plan', 'ReadOnly');
  static bool get canAccessSitePlan       => canReadSitePlan;

  static bool get canReadSiapHuni         => check('Siap Huni', 'ReadOnly');
  static bool get canAccessSiapHuni       => canReadSiapHuni;

  static bool get canReadInbox            => checkScoped('Inbox', 'ReadOnly');
  static bool get canAccessInbox          => canReadInbox;
}
