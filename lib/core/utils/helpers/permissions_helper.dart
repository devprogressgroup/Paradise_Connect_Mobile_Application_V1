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

  // ── Feature ber-scope (Own/Team/Any) ──────────────────────────────
  // Backend menyimpan feature sebagai {Action}Own/{Action}Team/{Action}Any
  // (mis. ModifyOwn/ModifyTeam/ModifyAny). Helper ini = true bila SALAH SATU aktif.
  // Visibilitas DATA (Own vs Team vs Any) ditegakkan server-side; di sini cukup boolean kapabilitas.
  static bool checkScoped(String formName, String action) {
    return check(formName, '${action}Own') ||
        check(formName, '${action}Team') ||
        check(formName, '${action}Any');
  }

  // Feature lampiran ber-scope: {Action}{Own/Team/Any}Attachment.
  static bool checkScopedAttachment(String action) {
    return check('Contacts', '${action}OwnAttachment') ||
        check('Contacts', '${action}TeamAttachment') ||
        check('Contacts', '${action}AnyAttachment');
  }

  // Level scope tertinggi: 'any' | 'team' | 'own' | 'none' (untuk kebutuhan UI lanjutan).
  static String scopeLevel(String formName, String action) {
    if (isSuperadmin) return 'any';
    if (check(formName, '${action}Any')) return 'any';
    if (check(formName, '${action}Team')) return 'team';
    if (check(formName, '${action}Own')) return 'own';
    return 'none';
  }

  // Attendance
  static bool get canReadAttendance       => checkScoped('Attendance', 'ReadOnly');
  static bool get canClockInOffice                    => check('Attendance', 'ClockInOffice');
  static bool get canClockInPameran                   => check('Attendance', 'ClockInPameran');
  static bool get canClockOutOffice                   => check('Attendance', 'ClockOutOffice');
  static bool get canClockOutPameran                  => check('Attendance', 'ClockOutPameran');
  static bool get canApproveRejectAttendance          => check('Attendance', 'ApproveReject');
  // Like/Dislike check-in activity (validasi flag 6) — sejajar dgn ApproveReject, gate terpisah.
  static bool get canCheckInVerify                    => check('Attendance', 'CheckInVerify');

  static bool get canClockInLuarLokasi                => check('Attendance', 'ClockInLuarLokasi');
  static bool get canClockOutLuarLokasi               => check('Attendance', 'ClockOutLuarLokasi');
  static bool get canClockInLuarLokasiRequestApprove  => check('Attendance', 'ClockInLuarLokasiRequestApprove');
  static bool get canClockOutLuarLokasiRequestApprove => check('Attendance', 'ClockOutLuarLokasiRequestApprove');

  // Composite attendance permissions
  static bool get canClockIn  => canClockInOffice || canClockInPameran || canClockInLuarLokasi;
  static bool get canClockOut => canClockOutOffice || canClockOutPameran || canClockOutLuarLokasi;

  // true jika minimal satu fitur attendance aktif
  static bool get canAccessAttendance => canReadAttendance || canClockInOffice || canClockInPameran || canClockOutOffice || canClockOutPameran || canApproveRejectAttendance || canCheckInVerify || canClockInLuarLokasi || canClockOutLuarLokasi || canClockInLuarLokasiRequestApprove || canClockOutLuarLokasiRequestApprove;

  // Attendance raw values
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

  // Contacts (feature ber-scope; kumulatif Modify/Delete ⇒ Read)
  static bool get canModifyContacts       => checkScoped('Contacts', 'Modify');
  static bool get canDeleteContacts       => checkScoped('Contacts', 'Delete');
  static bool get canReadContacts         => checkScoped('Contacts', 'ReadOnly') || canModifyContacts || canDeleteContacts;
  static bool get canModifyAttachment     => checkScopedAttachment('Modify');
  static bool get canDeleteAttachment     => checkScopedAttachment('Delete');

  // true jika minimal satu fitur contacts aktif
  static bool get canAccessContacts => canReadContacts || canModifyContacts || canDeleteContacts || canModifyAttachment || canDeleteAttachment;

  // Contact action-level helpers — DISELARASKAN dgn backend (per-aksi):
  //   Create/Edit = Modify. Delete = Delete (Modify TIDAK memberi hapus; backend menolak 403).
  static bool get canCreateContact => canModifyContacts;
  static bool get canEditContact   => canModifyContacts;
  static bool get canDeleteContact => canDeleteContacts;

  // Attachment action-level helpers (selaras backend isAttachmentInScope):
  //   FLOOR = Modify kontak. Upload/Edit = Modify kontak ATAU Modify*Attachment.
  //   Delete = Modify kontak ATAU Delete*Attachment (Modify*Attachment TIDAK memberi hapus).
  static bool get canUploadAttachment     => canModifyContacts || canModifyAttachment;
  static bool get canEditAttachmentItem   => canModifyContacts || canModifyAttachment;
  static bool get canDeleteAttachmentItem => canModifyContacts || canDeleteAttachment;
  static bool get canViewAttachment       => canModifyContacts || canModifyAttachment || canDeleteAttachment || canReadContacts;

  // Sales Kit
  static bool get canModifySalesKit       => check('Sales Kit', 'Modify');
  static bool get canReadSalesKit         => check('Sales Kit', 'ReadOnly');

  // true jika minimal satu fitur sales kit aktif
  static bool get canAccessSalesKit => canReadSalesKit || canModifySalesKit;

  // Site Plan
  static bool get canReadSitePlan         => check('Site Plan', 'ReadOnly');
  static bool get canAccessSitePlan       => canReadSitePlan;

  // Siap Huni (webview; satu ReadOnly — pola sama dengan Site Plan)
  static bool get canReadSiapHuni         => check('Siap Huni', 'ReadOnly');
  static bool get canAccessSiapHuni       => canReadSiapHuni;

  // Inbox (read-only ber-scope)
  static bool get canReadInbox            => checkScoped('Inbox', 'ReadOnly');
  static bool get canAccessInbox          => canReadInbox;
}
