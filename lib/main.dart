
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:progress_group/core/network/dio_client.dart';
import 'package:progress_group/core/services/push_notification_service.dart';
import 'package:progress_group/firebase_options.dart';
import 'package:progress_group/features/attandance/data/datasource/attendance_remote_datasource.dart';
import 'package:progress_group/features/attandance/domain/repositories/attandance_repository.dart';
import 'package:progress_group/features/attandance/domain/usecase/get_attendance.dart';
import 'package:progress_group/features/attandance/domain/usecase/get_locations.dart';
import 'package:progress_group/features/attandance/domain/usecase/get_office_locations.dart';
import 'package:progress_group/features/attandance/domain/usecase/get_today_attendance.dart';
import 'package:progress_group/features/attandance/domain/usecase/get_attendance_activity.dart';
import 'package:progress_group/features/attandance/domain/usecase/submit_attendance.dart';
import 'package:progress_group/features/attandance/domain/usecase/submit_attendance_activity.dart';
import 'package:progress_group/features/attandance/presentation/state/attandance/attendance_bloc.dart';
import 'package:progress_group/features/attandance/presentation/state/attendance_activity/attendance_activity_bloc.dart';
import 'package:progress_group/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:progress_group/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:progress_group/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:progress_group/features/auth/domain/usecase/clear_remember_me_usecase.dart';
import 'package:progress_group/features/auth/domain/usecase/forgot_password_usecase.dart';
import 'package:progress_group/features/auth/domain/usecase/get_biometric_enabled_usecase.dart';
import 'package:progress_group/features/auth/domain/usecase/get_remember_me_usecase.dart';
import 'package:progress_group/features/auth/domain/usecase/save_biometric_enabled_usecase.dart';
import 'package:progress_group/features/auth/domain/usecase/save_credentials_usecase.dart';
import 'package:progress_group/features/auth/domain/usecase/update_profile_usecase.dart';
import 'package:progress_group/features/auth/domain/usecase/login_usecase.dart';
import 'package:progress_group/features/auth/domain/usecase/get_profile_usecase.dart';
import 'package:progress_group/features/auth/domain/usecase/logout_usecase.dart';
import 'package:progress_group/features/auth/domain/usecase/reset_password_usecase.dart';
import 'package:progress_group/features/auth/presentation/state/auth/auth_bloc.dart';
import 'package:progress_group/features/auth/presentation/state/auth/auth_state.dart';
import 'package:progress_group/features/auth/presentation/state/profile/profile_bloc.dart';
import 'package:progress_group/features/auth/presentation/state/profile/profile_event.dart';
import 'package:progress_group/features/contact/domain/usecases/activity/create_activity_visit_usecase.dart';
import 'package:progress_group/features/contact/domain/usecases/activity/get_activity_prospect_status_usecase.dart';
import 'package:progress_group/features/contact/domain/usecases/activity/get_whatsapp_activity_usecase.dart';
import 'package:progress_group/features/contact/domain/usecases/attachment/delete_attachment_usecase.dart';
import 'package:progress_group/features/contact/domain/usecases/attachment/get_attachments.dart';
import 'package:progress_group/features/contact/domain/usecases/attachment/update_attachment_usecase.dart';
import 'package:progress_group/features/contact/domain/usecases/contact/delete_contact_usecase.dart';
import 'package:progress_group/features/contact/domain/usecases/contact/update_contact_usecase.dart';
import 'package:progress_group/features/contact/domain/usecases/info_source/get_info_sources_usecase.dart';
import 'package:progress_group/features/contact/domain/usecases/lost_reason/get_lost_reason.dart';
import 'package:progress_group/features/contact/presentation/state/attachment/attachment_cubit.dart';
import 'package:progress_group/features/contact/presentation/state/info_source/info_source_bloc.dart';
import 'package:progress_group/features/contact/presentation/state/lost_reason/lost_reason_block.dart';
import 'package:progress_group/features/contact/presentation/state/whatsapp_activity/whatsapp_unread_summary_bloc.dart';
import 'package:progress_group/core/network/api_constants.dart';
import 'package:progress_group/features/home/domain/usecases/get_report_whatsapp_usecase.dart';
import 'package:progress_group/features/home/domain/usecases/get_prospect_status_summary_usecase.dart';
import 'package:progress_group/features/home/presentation/state/report-whatsapp/report_bloc.dart';
import 'package:progress_group/features/home/presentation/state/prospect-status-summary/prospect_status_summary_bloc.dart';
import 'package:progress_group/features/inbox/data/datasources/inbox_remote_datasource.dart';
import 'package:progress_group/features/inbox/data/datasources/message_remote_datasource.dart';
import 'package:progress_group/features/inbox/domain/repositories/inbox_contact_repo_impl.dart';
import 'package:progress_group/features/inbox/domain/repositories/message_repository.dart';
import 'package:progress_group/features/inbox/domain/usecases/get_messages_usecase.dart';
import 'package:progress_group/features/inbox/domain/usecases/get_qr_session_usecase.dart';
import 'package:progress_group/features/inbox/domain/usecases/get_whatsapp_devices_usecase.dart';
import 'package:progress_group/features/inbox/domain/usecases/inbox_contact_usecase.dart';
import 'package:progress_group/features/inbox/presentation/state/inbox/inbox_block.dart';
import 'package:progress_group/features/inbox/presentation/state/whatsapp_device/whatsapp_device_bloc.dart';
import 'package:progress_group/features/inbox/presentation/state/whatsapp_qr/whatsapp_qr_bloc.dart';
import 'package:progress_group/features/inbox/presentation/state/message/message_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/router.dart';
import 'features/saleskit/data/datasources/saleskit_remote_datasource.dart';
import 'features/site-plan/data/datasources/siteplan_remote_datasource.dart';
import 'features/site-plan/domain/repositories/site_plan_repository_impl.dart';
import 'features/site-plan/presentation/state/siteplan_bloc.dart';
import 'features/site-plan/presentation/state/siteplan_event.dart';
import 'features/saleskit/domain/repositories/saleskit_repository.dart';
import 'features/saleskit/domain/usecase/get_clusters_usecase.dart';
import 'features/saleskit/domain/usecase/get_commercials_usecase.dart';
import 'features/saleskit/domain/usecase/get_townships_usecase.dart';
import 'features/saleskit/presentation/state/saleskit_detail/saleskit_detail_bloc.dart';
import 'features/saleskit/presentation/state/township/township_bloc.dart';
import 'features/saleskit/presentation/state/township/township_event.dart';
import 'core/utils/theme.dart';
import 'features/home/data/datasources/report_remote_datasource.dart';
import 'features/home/domain/repositories/report_whatsapp_repository.dart';
import 'features/contact/data/datasources/contact_remote_datasource.dart';
import 'features/contact/domain/repositories/contact_repository_impl.dart';
import 'features/contact/domain/usecases/contact/get_contacts_usecase.dart';
import 'features/contact/domain/usecases/contact/get_contact_detail_usecase.dart';
import 'features/contact/domain/usecases/contact/create_contact_usecase.dart';
import 'features/contact/presentation/state/contact/contact_bloc.dart';
import 'features/contact/domain/usecases/activity/get_activities_usecase.dart';
import 'features/contact/domain/usecases/activity/create_activity_usecase.dart';
import 'features/contact/domain/usecases/activity/post_status_follow_usecase.dart';
import 'features/contact/presentation/state/activity/activity_bloc.dart';
import 'features/contact/domain/usecases/prospect/get_prospect_statuses_usecase.dart';
import 'features/contact/domain/usecases/contact/get_contact_properties_usecase.dart';
import 'features/contact/presentation/state/contact_properties/contact_properties_bloc.dart';
import 'features/contact/presentation/state/prospect_status/prospect_status_bloc.dart';
import 'features/contact/domain/usecases/attachment/get_attachment_types_usecase.dart';
import 'features/contact/presentation/state/attachment_type/attachment_type_bloc.dart';
import 'features/contact/domain/usecases/attachment/upload_attachment_usecase.dart';
import 'features/contact/presentation/state/attachment/upload_attachment_bloc.dart';
import 'features/contact/domain/usecases/property/get_property_units_usecase.dart';
import 'features/contact/domain/usecases/property/get_property_commercial_units_usecase.dart';
import 'features/contact/presentation/state/property_unit/property_unit_cubit.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // FCM otomatis menampilkan notifikasi saat app di background/terminated
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  final prefs = await SharedPreferences.getInstance();
  ApiConstants.loadFromPrefs(prefs);

  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    if (!kIsWeb) {
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    }
    await PushNotificationService.initialize();
  } catch (e) {
    debugPrint('Firebase init error: $e');
  }

  // Inisialisasi router pertama kali
  AppRouter.init();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.white,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );

  runApp(MyApp(prefs: prefs));
}

class MyApp extends StatefulWidget {
  final SharedPreferences prefs;
  const MyApp({super.key, required this.prefs});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Key ini digunakan untuk memaksa rebuild seluruh MultiBlocProvider
  Key _blocKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    ApiConstants.envNotifier.addListener(_resetApp);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      PushNotificationService.processPendingMessage();
    });
  }

  @override
  void dispose() {
    ApiConstants.envNotifier.removeListener(_resetApp);
    super.dispose();
  }

  void _resetApp() {
    DioClient.resetSession();
    setState(() {
      // 1. Reset status auth notifier agar GoRouter mengarahkan ke /login
      AppRouter.authNotifier.value = false;
      // 2. Inisialisasi ulang router dengan GlobalKey baru untuk menghindari 'Duplicate GlobalKey' error
      AppRouter.init();
      // 3. Ganti key untuk membuang semua BLoC lama dan membuat yang baru (Initial State)
      _blocKey = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Infrastructure
    final localDataSource = AuthLocalDataSourceImpl(widget.prefs);
    final dioClient = DioClient(localDataSource);
    PushNotificationService.setDio(dioClient.dio);
    
    // Auth
    final remoteDataSource = AuthRemoteDataSourceImpl(dioClient.dio);
    final repository = AuthRepositoryImpl(remoteDataSource, localDataSource);
    final loginUseCase = LoginUseCase(repository);
    final forgotPasswordUseCase = ForgotPasswordUseCase(repository);
    final getRememberMeUseCase = GetRememberMeUseCase(repository);
    final clearRememberMeUseCase = ClearRememberMeUseCase(repository);
    final getBiometricEnabledUseCase = GetBiometricEnabledUseCase(repository);
    final saveBiometricEnabledUseCase = SaveBiometricEnabledUseCase(repository);
    final saveCredentialsUseCase = SaveCredentialsUseCase(repository);
    final updateProfileUseCase = UpdateProfileUseCase(repository);
    final resetPasswordUsecase = ResetPasswordUsecase(repository);
    final logoutUseCase = LogoutUseCase(repository);
    final getProfileUseCase = GetProfileUseCase(repository);

    // Inbox & Messages
    final inboxRemoteDataSource = InboxContactRemoteDataSourceImpl(dioClient.dio);
    final inboxRepository = InboxContactRepositoryImpl(inboxRemoteDataSource);
    final getInboxContactsUsecase = GetInboxContactsUsecase(inboxRepository);
    final getWhatsappDevicesUsecase = GetWhatsappDevicesUsecase(inboxRepository);
    final getQrSessionUsecase = GetQrSessionUsecase(inboxRepository);
    final messageRemoteDataSource = MessageRemoteDataSourceImpl(dioClient.dio);
    final messageRepository = MessageRepositoryImpl(messageRemoteDataSource);
    final getMessagesUseCase = GetMessagesUseCase(messageRepository);

    // Reports
    final reportRemoteDataSource = ReportRemoteDataSourceImpl(dioClient.dio);
    final reportRepository = ReportRepositoryImpl(reportRemoteDataSource);
    final getVolumeReportUseCase = GetVolumeReportUseCase(reportRepository);
    final getProspectStatusSummaryUseCase = GetProspectStatusSummaryUseCase(reportRepository);

    // Contacts & Activities
    final contactRemoteDataSource = ContactRemoteDataSourceImpl(dioClient.dio);
    final contactRepository = ContactRepositoryImpl(contactRemoteDataSource);
    final getContactsUseCase = GetContactsUseCase(contactRepository);
    final getContactDetailUseCase = GetContactDetailUseCase(contactRepository);
    final getProspectStatusesUseCase = GetProspectStatusesUseCase(contactRepository);
    final getActivitiesUseCase = GetActivitiesUseCase(contactRepository);
    final createActivityUseCase = CreateActivityUseCase(contactRepository);
    final postStatusFollowUseCase = PostStatusFollowUseCase(contactRepository);
    final createContactUseCase = CreateContactUseCase(contactRepository);
    final updateContactUseCase = UpdateContactUseCase(contactRepository);
    final deleteContactUseCase = DeleteContactUseCase(contactRepository);
    final getContactPropertiesUseCase = GetContactPropertiesUseCase(contactRepository);
    final getAttachmentTypesUseCase = GetAttachmentTypesUseCase(contactRepository);
    final uploadAttachmentUseCase = UploadAttachmentUseCase(contactRepository);
    final getAttachmentsUseCase = GetAttachments(contactRepository);
    final deleteAttachmentUseCase = DeleteAttachmentUseCase(contactRepository);
    final updateAttachmentUseCase = UpdateAttachmentUseCase(contactRepository);
    final createActivityVisitUseCase = CreateActivityVisitUseCase(contactRepository);
    final getActivityProspectStatusUseCase = GetActivityProspectStatusUseCase(contactRepository);
    final getWhatsappActivityUseCase =  GetWhatsappUnreadSummaryUseCase(contactRepository);
    final getInfoSourcesUseCase = GetInfoSourcesUseCase(contactRepository);
    final getLostReasonsUseCase = GetLostReasonsUseCase(contactRepository);
    final getPropertyUnitsUseCase = GetPropertyUnitsUseCase(contactRepository);
    final getPropertyCommercialUnitsUseCase = GetPropertyCommercialUnitsUseCase(contactRepository);
    
    // SitePlan
    final siteplanRemoteDataSource = SiteplanRemoteDataSourceImpl(dioClient.dio);
    final siteplanRepository = SitePlanRepositoryImpl(siteplanRemoteDataSource);

    // SalesKit / Townships
    final salesKitRemoteDataSource = SalesKitRemoteDataSourceImpl(dioClient.dio);
    final salesKitRepository = SalesKitRepositoryImpl(salesKitRemoteDataSource);
    final getTownshipsUseCase = GetTownshipsUseCase(salesKitRepository);
    final getClustersUseCase = GetClustersUseCase(salesKitRepository);
    final getCommercialsUseCase = GetCommercialsUseCase(salesKitRepository);

    // Attendance
    final attendanceRemoteDataSource = AttendanceRemoteDataSourceImpl(dioClient.dio);
    final attendanceRepository = AttendanceRepositoryImpl(attendanceRemoteDataSource);
    final getAttendanceUseCase = GetAttendanceUseCase(attendanceRepository);
    final getTodayAttendanceUseCase = GetTodayAttendanceUseCase(attendanceRepository);
    final getLocationsUseCase = GetLocationsUseCase(attendanceRepository);
    final getOfficeLocationsUseCase = GetOfficeLocationsUseCase(attendanceRepository);
    final submitAttendanceUseCase = SubmitAttendanceUseCase(attendanceRepository);
    final submitAttendanceActivityUseCase = SubmitAttendanceActivityUseCase(attendanceRepository);
    final getAttendanceActivityUseCase = GetAttendanceActivityUseCase(attendanceRepository);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: PushNotificationService.scaffoldMessengerKey,
      theme: AppTheme.lightTheme,
      routerConfig: AppRouter.router,
      builder: (context, child) {
        return MultiBlocProvider(
          key: _blocKey,
          providers: [
            BlocProvider(create: (_) => AuthBloc(loginUseCase: loginUseCase, forgotPasswordUseCase: forgotPasswordUseCase, getRememberMeUseCase: getRememberMeUseCase, clearRememberMeUseCase: clearRememberMeUseCase, getBiometricEnabledUseCase: getBiometricEnabledUseCase, saveBiometricEnabledUseCase: saveBiometricEnabledUseCase, saveCredentialsUseCase: saveCredentialsUseCase, updateProfileUseCase: updateProfileUseCase, resetPasswordUsecase: resetPasswordUsecase, logoutUseCase: logoutUseCase)),
            BlocProvider(create: (_) => InboxContactBloc(getInboxContactsUsecase)),
            BlocProvider(create: (_) => WhatsappDeviceBloc(getWhatsappDevicesUsecase)),
            BlocProvider(create: (_) => WhatsappQrBloc(getQrSessionUsecase)),
            BlocProvider(create: (_) => ProfileBloc(getProfileUseCase: getProfileUseCase)),
            BlocProvider(create: (_) => MessageBloc(getMessagesUseCase)),
            BlocProvider(create: (_) => ReportBloc(getVolumeReportUseCase)),
            BlocProvider(create: (_) => ProspectStatusSummaryBloc(getProspectStatusSummaryUseCase: getProspectStatusSummaryUseCase)),
            BlocProvider(create: (_) => ContactBloc(getContactsUseCase: getContactsUseCase, createContactUseCase: createContactUseCase, updateContactUseCase: updateContactUseCase, deleteContactUseCase: deleteContactUseCase, getContactDetailUseCase: getContactDetailUseCase)),
            BlocProvider(create: (_) => ProspectStatusBloc(getProspectStatusesUseCase: getProspectStatusesUseCase)),
            BlocProvider(create: (_) => ContactPropertiesBloc(getContactPropertiesUseCase: getContactPropertiesUseCase)),
            BlocProvider(create: (_) => ActivityBloc(getActivitiesUseCase: getActivitiesUseCase, createActivityUseCase: createActivityUseCase, postStatusFollowUseCase: postStatusFollowUseCase)),
            BlocProvider(create: (_) => NotifActivityBloc(getActivitiesUseCase: getActivitiesUseCase, createActivityUseCase: createActivityUseCase, postStatusFollowUseCase: postStatusFollowUseCase)),
            BlocProvider(create: (_) => ContactDetailActivityBloc(getActivitiesUseCase: getActivitiesUseCase, createActivityUseCase: createActivityUseCase, postStatusFollowUseCase: postStatusFollowUseCase)),
            BlocProvider(create: (_) => ActivityVisitBloc(createActivityVisitUseCase)),
            BlocProvider(create: (_) => AttachmentTypeBloc(getAttachmentTypesUseCase)),
            BlocProvider(create: (_) => UploadAttachmentBloc(uploadAttachmentUseCase, updateAttachmentUseCase)),
            BlocProvider(create: (_) => AttachmentCubit(getAttachmentsUseCase, deleteAttachmentUseCase)),
            BlocProvider(create: (_) => ActivityProspectStatusBloc(getActivityProspectStatusUseCase)),
            BlocProvider(create: (_) => AttendanceBloc(getAttendanceUseCase: getAttendanceUseCase, getTodayAttendanceUseCase: getTodayAttendanceUseCase, getLocationsUseCase: getLocationsUseCase, getOfficeLocationsUseCase: getOfficeLocationsUseCase, submitAttendanceUseCase: submitAttendanceUseCase, submitAttendanceActivityUseCase: submitAttendanceActivityUseCase)),
            BlocProvider(create: (_) => AttendanceActivityBloc(getAttendanceActivityUseCase: getAttendanceActivityUseCase)),
            BlocProvider(create: (_) => WhatsappActivityBloc(getWhatsappActivityUseCase)),
            BlocProvider(create: (_) => InfoSourceBloc(getInfoSourcesUseCase: getInfoSourcesUseCase)),
            BlocProvider(create: (_) => LostReasonBloc(getLostReasonsUseCase: getLostReasonsUseCase)),
            BlocProvider(create: (_) => PropertyUnitCubit(getPropertyUnitsUseCase, getPropertyCommercialUnitsUseCase)),
            BlocProvider(create: (_) => SiteplanBloc(siteplanRepository)..add(LoadSiteplanEvent())),
            BlocProvider(create: (_) => TownshipBloc(getTownshipsUseCase)..add(GetTownshipsEvent())),
            BlocProvider(create: (_) => SalesKitDetailBloc(getClustersUseCase: getClustersUseCase, getCommercialsUseCase: getCommercialsUseCase)),
          ],
          child: BlocListener<AuthBloc, AuthState>(
            listener: (context, state) {
              if (state is AuthSuccess) {
                context.read<ProfileBloc>().add(GetProfileEvent());
                AppRouter.authNotifier.value = true;
                // Kirim FCM token setelah login berhasil (dioClient sudah punya auth token)
                PushNotificationService.setDio(dioClient.dio);
              } else if (state is AuthLoggedOut) {
                // Restart aplikasi total seolah-olah baru dibuka pertama kali
                _resetApp();
              }
            },
            child: child!,
          ),
        );
      },
    );
  }
}
