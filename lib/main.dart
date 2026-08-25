
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:ui' show PlatformDispatcher;
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:app_links/app_links.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:progress_group/core/screens/update_screen.dart';
import 'package:progress_group/core/services/old_app_check_service.dart';
import 'core/utils/web_debug_util.dart' as web_debug;
import 'core/utils/web_update.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:progress_group/core/network/dio_client.dart';
import 'package:progress_group/core/services/analytics_service.dart';
import 'package:progress_group/core/services/push_notification_service.dart';
import 'package:progress_group/features/attandance/domain/usecase/get_attendance_approval_today.dart';
import 'package:progress_group/firebase_options.dart';
import 'package:progress_group/features/attandance/data/datasource/attendance_remote_datasource.dart';
import 'package:progress_group/features/attandance/domain/repositories/attandance_repository.dart';
import 'package:progress_group/features/attandance/domain/usecase/get_attendance.dart';
import 'package:progress_group/features/attandance/domain/usecase/get_locations.dart';
import 'package:progress_group/features/attandance/domain/usecase/get_office_locations.dart';
import 'package:progress_group/features/attandance/domain/usecase/get_all_office_locations.dart';
import 'package:progress_group/features/attandance/domain/usecase/get_today_attendance.dart';
import 'package:progress_group/features/attandance/domain/usecase/get_attendance_activity.dart';
import 'package:progress_group/features/attandance/domain/usecase/submit_attendance.dart';
import 'package:progress_group/features/attandance/domain/usecase/submit_attendance_activity.dart';
import 'package:progress_group/features/attandance/domain/usecase/validasi_check_in.dart';
import 'package:progress_group/features/attandance/domain/usecase/post_attendance_approval.dart';
import 'package:progress_group/features/attandance/presentation/state/attandance/attendance_bloc.dart';
import 'package:progress_group/features/attandance/presentation/state/attendance_activity/attendance_activity_bloc.dart';
import 'package:progress_group/features/attandance/presentation/state/attendance_approval/attendance_approval_cubit.dart';
import 'package:progress_group/features/attandance/presentation/state/attendance_excel/attendance_excel_cubit.dart';
import 'package:progress_group/features/notif/presentation/state/received_notif_cubit.dart';
import 'package:progress_group/features/notif/data/datasources/global_notification_remote_datasource.dart';
import 'package:progress_group/features/notif/presentation/state/global_notification/global_notification_cubit.dart';
import 'package:progress_group/features/attandance/presentation/state/pameran_location/pameran_location_cubit.dart';
import 'package:progress_group/features/attandance/presentation/state/office_location/office_location_cubit.dart';
import 'package:progress_group/features/attandance/presentation/state/office_location/all_office_location_cubit.dart';
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
import 'package:progress_group/features/auth/domain/usecase/get_permissions_usecase.dart';
import 'package:progress_group/features/auth/domain/usecase/get_impersonatable_users_usecase.dart';
import 'package:progress_group/features/auth/domain/usecase/impersonate_usecase.dart';
import 'package:progress_group/features/auth/domain/usecase/stop_impersonation_usecase.dart';
import 'package:progress_group/core/utils/helpers/impersonation_manager.dart';
import 'package:progress_group/features/auth/domain/usecase/reset_password_usecase.dart';
import 'package:progress_group/features/auth/presentation/state/auth/auth_bloc.dart';
import 'package:progress_group/features/auth/presentation/state/auth/auth_event.dart';
import 'package:progress_group/features/auth/presentation/state/auth/auth_state.dart';
import 'package:progress_group/features/auth/presentation/state/profile/profile_bloc.dart';
import 'package:progress_group/features/auth/presentation/state/profile/profile_event.dart';
import 'package:progress_group/features/auth/presentation/state/profile/profile_state.dart';
import 'package:progress_group/features/contact/domain/usecases/activity/create_activity_visit_usecase.dart';
import 'package:progress_group/features/contact/domain/usecases/activity/get_activity_prospect_status_usecase.dart';
import 'package:progress_group/features/contact/domain/usecases/activity/get_whatsapp_activity_usecase.dart';
import 'package:progress_group/features/contact/domain/usecases/attachment/delete_attachment_usecase.dart';
import 'package:progress_group/features/contact/domain/usecases/attachment/get_attachments.dart';
import 'package:progress_group/features/contact/domain/usecases/attachment/update_attachment_usecase.dart';
import 'package:progress_group/features/contact/domain/usecases/contact/delete_contact_usecase.dart';
import 'package:progress_group/features/contact/domain/usecases/contact/update_contact_usecase.dart';
import 'package:progress_group/features/contact/domain/usecases/info_source/get_info_sources_usecase.dart';
import 'package:progress_group/features/contact/domain/usecases/info_source/get_sales_channel_details_usecase.dart';
import 'package:progress_group/features/contact/domain/usecases/sales_hierarchy/get_sales_owners_usecase.dart';
import 'package:progress_group/features/contact/domain/usecases/sales_hierarchy/get_sales_executives_usecase.dart';
import 'package:progress_group/features/contact/domain/usecases/sales_hierarchy/get_sales_supervisors_usecase.dart';
import 'package:progress_group/features/contact/domain/usecases/sales_hierarchy/get_sales_managers_usecase.dart';
import 'package:progress_group/features/contact/domain/usecases/sales_hierarchy/get_sales_general_managers_usecase.dart';
import 'package:progress_group/features/contact/domain/usecases/sales_hierarchy/get_sales_teams_paginated_usecase.dart';
import 'package:progress_group/features/contact/domain/usecases/lost_reason/get_lost_reason.dart';
import 'package:progress_group/features/contact/presentation/state/attachment/attachment_cubit.dart';
import 'package:progress_group/features/contact/presentation/state/info_source/info_source_bloc.dart';
import 'package:progress_group/features/contact/presentation/state/sales_hierarchy/sales_hierarchy_service.dart';
import 'package:progress_group/features/contact/presentation/state/lost_reason/lost_reason_block.dart';
import 'package:progress_group/features/contact/domain/usecases/product_type/get_product_types_usecase.dart';
import 'package:progress_group/features/contact/presentation/state/product_type/product_type_bloc.dart';
import 'package:progress_group/features/contact/presentation/state/product_type/product_type_event.dart';
import 'package:progress_group/features/contact/presentation/state/pameran_aktif/pameran_aktif_cubit.dart';
import 'package:progress_group/features/contact/data/datasources/pipeline_remote_datasource.dart';
import 'package:progress_group/features/contact/presentation/state/pipeline/pipeline_cubit.dart';
import 'package:progress_group/features/contact/presentation/state/whatsapp_activity/whatsapp_unread_summary_bloc.dart';
import 'package:progress_group/core/network/api_constants.dart';
import 'package:progress_group/features/home/domain/usecases/get_report_whatsapp_usecase.dart';
import 'package:progress_group/features/home/domain/usecases/get_prospect_status_summary_usecase.dart';
import 'package:progress_group/features/home/domain/usecases/get_sales_channels_summary_usecase.dart';
import 'package:progress_group/features/home/presentation/state/report-whatsapp/report_bloc.dart';
import 'package:progress_group/features/home/presentation/state/prospect-status-summary/prospect_status_summary_bloc.dart';
import 'package:progress_group/features/home/presentation/state/sales-channel-summary/sales_channel_summary_bloc.dart';
import 'package:progress_group/features/inbox/data/datasources/inbox_remote_datasource.dart';
import 'package:progress_group/features/inbox/data/datasources/message_remote_datasource.dart';
import 'package:progress_group/features/inbox/domain/repositories/inbox_contact_repo_impl.dart';
import 'package:progress_group/features/inbox/domain/repositories/message_repository.dart';
import 'package:progress_group/features/inbox/domain/usecases/get_messages_usecase.dart';
import 'package:progress_group/features/inbox/domain/usecases/get_qr_session_usecase.dart';
import 'package:progress_group/features/inbox/domain/usecases/request_pair_code_usecase.dart';
import 'package:progress_group/features/inbox/domain/usecases/get_whatsapp_devices_usecase.dart';
import 'package:progress_group/features/inbox/domain/usecases/inbox_contact_usecase.dart';
import 'package:progress_group/features/inbox/presentation/state/inbox/inbox_block.dart';
import 'package:progress_group/features/inbox/presentation/state/whatsapp_device/whatsapp_device_bloc.dart';
import 'package:progress_group/features/inbox/presentation/state/whatsapp_qr/whatsapp_qr_bloc.dart';
import 'package:progress_group/features/inbox/presentation/state/message/message_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/router.dart';
import 'core/network/settings_remote_datasource.dart';

import 'core/services/version_check_service.dart';
import 'features/saleskit/data/datasources/saleskit_remote_datasource.dart';
import 'features/site-plan/data/datasources/siteplan_remote_datasource.dart';
import 'features/site-plan/domain/repositories/site_plan_repository_impl.dart';
import 'features/site-plan/presentation/state/siteplan_bloc.dart';
import 'features/site-plan/presentation/state/siteplan_event.dart';
import 'features/saleskit/domain/repositories/saleskit_repository.dart';
import 'features/saleskit/domain/usecase/get_cluster_media_usecase.dart';
import 'features/saleskit/domain/usecase/get_clusters_usecase.dart';
import 'features/saleskit/domain/usecase/get_commercials_usecase.dart';
import 'features/saleskit/domain/usecase/get_townships_saleskit_usecase.dart';
import 'features/saleskit/domain/usecase/get_townships_usecase.dart';
import 'features/saleskit/domain/usecase/share_caption_usecase.dart';
import 'features/saleskit/presentation/state/saleskit_detail/saleskit_detail_bloc.dart';
import 'features/saleskit/presentation/state/saleskit_township/saleskit_township_bloc.dart';
import 'features/saleskit/presentation/state/saleskit_township/saleskit_township_event.dart';
import 'features/saleskit/presentation/state/cluster_media_overview/cluster_media_overview_bloc.dart';
import 'features/saleskit/presentation/state/cluster_media_list/cluster_media_list_bloc.dart';
import 'features/saleskit/presentation/state/township/township_bloc.dart';
import 'features/saleskit/presentation/state/township/township_event.dart';
import 'core/utils/theme.dart';
import 'features/home/data/datasources/report_remote_datasource.dart';
import 'features/home/domain/repositories/report_whatsapp_repository.dart';
import 'features/contact/data/datasources/contact_remote_datasource.dart';
import 'features/contact/domain/repositories/contact_repository_impl.dart';
import 'features/contact/domain/usecases/contact/get_contacts_usecase.dart';
import 'features/contact/domain/usecases/contact/get_contact_detail_usecase.dart';
import 'features/contact/domain/usecases/contact/get_all_contacts_for_duplicate_check_usecase.dart';
import 'features/contact/domain/usecases/contact/check_duplicate_contact_usecase.dart';
import 'features/contact/domain/usecases/contact/create_contact_usecase.dart';
import 'features/contact/presentation/state/contact/contact_bloc.dart';
import 'features/contact/domain/usecases/activity/get_activities_usecase.dart';
import 'features/contact/domain/usecases/activity/create_activity_usecase.dart';
import 'features/contact/domain/usecases/activity/post_status_follow_usecase.dart';
import 'features/contact/presentation/state/activity/activity_bloc.dart';
import 'features/contact/domain/usecases/prospect/get_prospect_statuses_usecase.dart';
import 'features/contact/domain/usecases/prospect/get_contact_form_prospect_statuses_usecase.dart';
import 'features/contact/domain/usecases/contact/get_contact_properties_usecase.dart';
import 'features/contact/presentation/state/contact_properties/contact_properties_bloc.dart';
import 'features/contact/presentation/state/prospect_status/prospect_status_bloc.dart';
import 'features/contact/presentation/state/prospect_status/contact_form_prospect_status_bloc.dart';
import 'features/contact/domain/usecases/attachment/get_attachment_types_usecase.dart';
import 'features/contact/presentation/state/attachment_type/attachment_type_bloc.dart';
import 'features/contact/domain/usecases/attachment/upload_attachment_usecase.dart';
import 'features/contact/presentation/state/attachment/upload_attachment_bloc.dart';
import 'features/contact/domain/usecases/property/get_property_units_usecase.dart';
import 'features/contact/domain/usecases/property/get_property_commercial_units_usecase.dart';
import 'features/contact/presentation/state/property_unit/property_unit_cubit.dart';
import 'features/contact/domain/usecases/unit/unit_picker_usecase.dart';
import 'features/contact/presentation/state/unit_picker/unit_picker_cubit.dart';
import 'features/landing-page/data/datasources/landing_page_remote_datasource.dart';
import 'features/landing-page/data/repositories/landing_page_repository_impl.dart';
import 'features/landing-page/domain/usecases/get_landing_page_url_usecase.dart';
import 'features/landing-page/presentation/state/landing_page_cubit.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Path URL murni ("/link/{hash}", bukan "/#/link/{hash}") — App Link/PWA butuh ini supaya
  // path-nya kebaca browser & server (bisa di-deep-link langsung), sama seperti perilaku native
  // Android app links. Tanpa ini Flutter web default pakai hash strategy, jadi redirect hash-link
  // di AppRouter (lihat router.dart) tidak akan pernah match saat link dibuka langsung di browser.
  usePathUrlStrategy();

  if (!kIsWeb) {
    // Native only: raise Flutter's in-memory image cache ceiling (default 100MB/1000
    // images) so photos already viewed (e.g. attendance activity cards) survive scroll
    // and don't get re-fetched from Google Drive every time they scroll back into view.
    // Left untouched on web/PWA — iOS Safari has previously killed this app's tab under
    // memory pressure on the attendance page (see project_attendance_crash memory note).
    PaintingBinding.instance.imageCache.maximumSize = 2000;
    PaintingBinding.instance.imageCache.maximumSizeBytes = 200 << 20;
  }

  if (kIsWeb) {
    // Deliberately more conservative than Flutter's own default (100MB/1000 images) —
    // iOS Safari has previously killed this app's tab under memory pressure on the
    // attendance page (see project_attendance_crash memory note). Trading a bit more
    // re-fetching for a smaller peak memory footprint on the fragile platform.
    PaintingBinding.instance.imageCache.maximumSize = 300;
    PaintingBinding.instance.imageCache.maximumSizeBytes = 60 << 20;

    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      web_debug.logDebugError('Flutter: ${details.exceptionAsString()}');
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      web_debug.logDebugError('Uncaught: $error\n$stack');
      return false;
    };
  }

  await initializeDateFormatting('id_ID', null);
  final prefs = await SharedPreferences.getInstance();
  ApiConstants.loadFromPrefs(prefs);
  AnalyticsService.loadFromPrefs(prefs);
  ImpersonationManager.bind(prefs);


  try {
    final localDs = AuthLocalDataSourceImpl(prefs);
    final dio = DioClient(localDs).dio;
    final settings = await SettingsRemoteDataSource(dio).getSettings();
    if (settings.isNotEmpty) ApiConstants.applySettings(settings);
    await AnalyticsService.refreshEnabledEvents(dio);
  } catch (_) {}

  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    if (!kIsWeb) {
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    }
    // Timeout jaga-jaga: init ini jalan sebelum runApp(), jadi kalau ada panggilan di
    // dalamnya yang menggantung (mis. permission/service-worker API browser yang tidak
    // pernah resolve di Safari), seluruh app ikut macet di splash bawaan browser tanpa
    // batas waktu. Lebih baik lanjut tanpa push notification daripada app tidak bisa dibuka.
    await PushNotificationService.initialize().timeout(
      const Duration(seconds: 8),
      onTimeout: () => debugPrint('[Firebase] PushNotificationService.initialize() timeout, lanjut tanpa push notification'),
    );
  } catch (e) {
    debugPrint('[Firebase] Init error: $e');
  }

  AppRouter.init();

  if (!kIsWeb) {
    // App Link COLD START (app belum jalan) sudah otomatis kebaca lewat initial route Android
    // -> go_router, TAPI kalau app sudah jalan di background, Android cuma "bring existing task
    // to front" (MainActivity.kt tidak override onNewIntent) — intent barunya tidak pernah
    // sampai ke Flutter/go_router sama sekali, jadi kelihatan "linknya tidak ngapa-ngapain".
    // app_links nangkep intent susulan itu lewat plugin registry (auto, tanpa perlu ubah native
    // code) dan kita teruskan ke go_router secara manual di sini.
    AppLinks().uriLinkStream.listen((uri) {
      final location = '${uri.path}${uri.hasQuery ? '?${uri.query}' : ''}';
      debugPrint('[AppLinks] uriLinkStream: $location');
      AppRouter.router.go(location.isEmpty ? '/' : location);
    }, onError: (e) => debugPrint('[AppLinks] error: $e'));
  }

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Color(greySplash),
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

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  Key _blocKey = UniqueKey();
  VersionCheckResult? _updateResult;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ApiConstants.envNotifier.addListener(_resetApp);
    PushNotificationService.otaTrigger.addListener(_onOtaTrigger);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      PushNotificationService.processPendingMessage();
      _checkVersion();
      PushNotificationService.checkAndShowUpdateBanner();
      OldAppCheckService.check();
    });
  }

  void _onOtaTrigger() {
    final result = PushNotificationService.otaTrigger.value;
    if (result != null && mounted) {
      setState(() => _updateResult = result);
      PushNotificationService.otaTrigger.value = null;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_updateResult == null) _checkVersion();
      PushNotificationService.checkAndShowUpdateBanner();
      OldAppCheckService.check();

      _refreshAccessSilently();
    }
  }

  
  void _refreshAccessSilently() {
    if (!AppRouter.authNotifier.value) return; 
    final ctx = AppRouter.rootNavigatorKey.currentContext;
    if (ctx == null) return;
    try {
      ctx.read<AuthBloc>().add(FetchPermissionsEvent(silent: true));
      ctx.read<ProfileBloc>().add(GetProfileEvent(forceRefresh: true, silent: true));
    } catch (_) {}
  }

  Future<void> _checkVersion() async {
    try {
      final result = await VersionCheckService.check();
      if (!mounted || !result.requiresUpdate) return;
      if (kIsWeb) {
        
        
        forcePwaUpdate();
        return;
      }
      setState(() => _updateResult = result);
    } catch (_) {}
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ApiConstants.envNotifier.removeListener(_resetApp);
    PushNotificationService.otaTrigger.removeListener(_onOtaTrigger);
    super.dispose();
  }

  void _resetApp() {
    DioClient.resetSession();
    setState(() {
      
      AppRouter.authNotifier.value = false;
      
      AppRouter.init();
      
      _blocKey = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    
    final localDataSource = AuthLocalDataSourceImpl(widget.prefs);
    final dioClient = DioClient(localDataSource);
    final settingsDs = SettingsRemoteDataSource(dioClient.dio);
    PushNotificationService.setDio(dioClient.dio);
    PushNotificationService.setAuthLocalDataSource(localDataSource);

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
    final getPermissionsUseCase = GetPermissionsUseCase(repository);
    final getImpersonatableUsersUseCase = GetImpersonatableUsersUseCase(repository);
    final impersonateUseCase = ImpersonateUseCase(repository);
    final stopImpersonationUseCase = StopImpersonationUseCase(repository);

    
    final inboxRemoteDataSource = InboxContactRemoteDataSourceImpl(dioClient.dio);
    final inboxRepository = InboxContactRepositoryImpl(inboxRemoteDataSource);
    final getInboxContactsUsecase = GetInboxContactsUsecase(inboxRepository);
    final getWhatsappDevicesUsecase = GetWhatsappDevicesUsecase(inboxRepository);
    final getQrSessionUsecase = GetQrSessionUsecase(inboxRepository);
    final requestPairCodeUsecase = RequestPairCodeUsecase(inboxRepository);
    final messageRemoteDataSource = MessageRemoteDataSourceImpl(dioClient.dio);
    final messageRepository = MessageRepositoryImpl(messageRemoteDataSource);
    final getMessagesUseCase = GetMessagesUseCase(messageRepository);

    
    final reportRemoteDataSource = ReportRemoteDataSourceImpl(dioClient.dio);
    final reportRepository = ReportRepositoryImpl(reportRemoteDataSource);
    final getVolumeReportUseCase = GetVolumeReportUseCase(reportRepository);
    final getProspectStatusSummaryUseCase = GetProspectStatusSummaryUseCase(reportRepository);
    final getSalesChannelsSummaryUseCase = GetSalesChannelsSummaryUseCase(reportRepository);

    
    final contactRemoteDataSource = ContactRemoteDataSourceImpl(dioClient.dio);
    final contactRepository = ContactRepositoryImpl(contactRemoteDataSource);
    
    final pipelineRemoteDataSource = PipelineRemoteDataSourceImpl(dioClient.dio);
    final globalNotificationRemoteDataSource = GlobalNotificationRemoteDataSourceImpl(dioClient.dio);
    final getContactsUseCase = GetContactsUseCase(contactRepository);
    final getContactDetailUseCase = GetContactDetailUseCase(contactRepository);
    final getAllContactsForDuplicateCheckUseCase = GetAllContactsForDuplicateCheckUseCase(contactRepository);
    final checkDuplicateContactUseCase = CheckDuplicateContactUseCase(contactRepository);
    final getProspectStatusesUseCase = GetProspectStatusesUseCase(contactRepository);
    final getContactFormProspectStatusesUseCase = GetContactFormProspectStatusesUseCase(contactRepository);
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
    final getSalesChannelDetailsUseCase = GetSalesChannelDetailsUseCase(contactRepository);
    final getSalesOwnersUseCase = GetSalesOwnersUseCase(contactRepository);
    final getSalesExecutivesUseCase = GetSalesExecutivesUseCase(contactRepository);
    final getSalesSupervisorsUseCase = GetSalesSupervisorsUseCase(contactRepository);
    final getSalesManagersUseCase = GetSalesManagersUseCase(contactRepository);
    final getSalesGeneralManagersUseCase = GetSalesGeneralManagersUseCase(contactRepository);
    final getSalesTeamsPaginatedUseCase = GetSalesTeamsPaginatedUseCase(contactRepository);
    final getLostReasonsUseCase = GetLostReasonsUseCase(contactRepository);
    final getProductTypesUseCase = GetProductTypesUseCase(contactRepository);
    final getPropertyUnitsUseCase = GetPropertyUnitsUseCase(contactRepository);
    final getPropertyCommercialUnitsUseCase = GetPropertyCommercialUnitsUseCase(contactRepository);
    final getUnitHierarchyUseCase = GetUnitHierarchyUseCase(contactRepository);
    final getUnitLotsUseCase = GetUnitLotsUseCase(contactRepository);
    
    
    final siteplanRemoteDataSource = SiteplanRemoteDataSourceImpl(dioClient.dio);
    final siteplanRepository = SitePlanRepositoryImpl(siteplanRemoteDataSource, localDataSource);

    
    final landingPageRemoteDataSource = LandingPageRemoteDataSourceImpl();
    final landingPageRepository = LandingPageRepositoryImpl(landingPageRemoteDataSource);
    final getLandingPageUrlUseCase = GetLandingPageUrlUseCase(landingPageRepository);

    
    final salesKitRemoteDataSource = SalesKitRemoteDataSourceImpl(dioClient.dio);
    final salesKitRepository = SalesKitRepositoryImpl(salesKitRemoteDataSource);
    final getTownshipsUseCase = GetTownshipsUseCase(salesKitRepository);
    final getTownshipsSalesKitUseCase = GetTownshipsSalesKitUseCase(salesKitRepository);
    final getClustersUseCase = GetClustersUseCase(salesKitRepository);
    final getCommercialsUseCase = GetCommercialsUseCase(salesKitRepository);
    final getClusterMediaUseCase = GetClusterMediaUseCase(salesKitRepository);
    final shareCaptionUseCase = ShareCaptionUseCase(salesKitRepository);

    
    final attendanceRemoteDataSource = AttendanceRemoteDataSourceImpl(dioClient.dio);
    final attendanceRepository = AttendanceRepositoryImpl(attendanceRemoteDataSource);
    final getAttendanceUseCase = GetAttendanceUseCase(attendanceRepository);
    final getTodayAttendanceUseCase = GetTodayAttendanceUseCase(attendanceRepository);
    final getLocationsUseCase = GetLocationsUseCase(attendanceRepository);
    final getOfficeLocationsUseCase = GetOfficeLocationsUseCase(attendanceRepository);
    final getAllOfficeLocationsUseCase = GetAllOfficeLocationsUseCase(attendanceRepository);
    final submitAttendanceUseCase = SubmitAttendanceUseCase(attendanceRepository);
    final submitAttendanceActivityUseCase = SubmitAttendanceActivityUseCase(attendanceRepository);
    final getAttendanceActivityUseCase = GetAttendanceActivityUseCase(attendanceRepository);
    final validasiCheckInUseCase = ValidasiCheckInUseCase(attendanceRepository);
    final getAttendanceApprovalTodayUseCase = GetAttendanceApprovalTodayUseCase(attendanceRepository);
    final postAttendanceApprovalUseCase = PostAttendanceApprovalUseCase(attendanceRepository);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: PushNotificationService.scaffoldMessengerKey,
      theme: AppTheme.lightTheme,
      scrollBehavior: AppScrollBehavior(),
      routerConfig: AppRouter.router,
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        return MediaQuery(
          data: mq.copyWith(
            textScaler: mq.textScaler.clamp(minScaleFactor: 0.85, maxScaleFactor: 1.15),
          ),
          child: MultiBlocProvider(
          key: _blocKey,
          providers: [
            BlocProvider(create: (_) => AuthBloc(loginUseCase: loginUseCase, forgotPasswordUseCase: forgotPasswordUseCase, getRememberMeUseCase: getRememberMeUseCase, clearRememberMeUseCase: clearRememberMeUseCase, getBiometricEnabledUseCase: getBiometricEnabledUseCase, saveBiometricEnabledUseCase: saveBiometricEnabledUseCase, saveCredentialsUseCase: saveCredentialsUseCase, updateProfileUseCase: updateProfileUseCase, resetPasswordUsecase: resetPasswordUsecase, logoutUseCase: logoutUseCase, getPermissionsUseCase: getPermissionsUseCase, getImpersonatableUsersUseCase: getImpersonatableUsersUseCase, impersonateUseCase: impersonateUseCase, stopImpersonationUseCase: stopImpersonationUseCase)),
            BlocProvider(create: (_) => InboxContactBloc(getInboxContactsUsecase)),
            BlocProvider(create: (_) => WhatsappDeviceBloc(getWhatsappDevicesUsecase)),
            BlocProvider(create: (_) => WhatsappQrBloc(getQrSessionUsecase, requestPairCodeUsecase)),
            BlocProvider(create: (_) => ProfileBloc(getProfileUseCase: getProfileUseCase)),
            BlocProvider(create: (_) => MessageBloc(getMessagesUseCase)),
            BlocProvider(create: (_) => ReportBloc(getVolumeReportUseCase)),
            BlocProvider(create: (_) => ProspectStatusSummaryBloc(getProspectStatusSummaryUseCase: getProspectStatusSummaryUseCase)),
            BlocProvider(create: (_) => SalesChannelSummaryBloc(getSalesChannelsSummaryUseCase: getSalesChannelsSummaryUseCase)),
            BlocProvider(create: (_) => ContactBloc(getContactsUseCase: getContactsUseCase, createContactUseCase: createContactUseCase, updateContactUseCase: updateContactUseCase, deleteContactUseCase: deleteContactUseCase, getContactDetailUseCase: getContactDetailUseCase, getAllContactsForDuplicateCheckUseCase: getAllContactsForDuplicateCheckUseCase, checkDuplicateContactUseCase: checkDuplicateContactUseCase)),
            BlocProvider(create: (_) => ProspectStatusBloc(getProspectStatusesUseCase: getProspectStatusesUseCase)),
            BlocProvider(create: (_) => ContactFormProspectStatusBloc(getContactFormProspectStatusesUseCase: getContactFormProspectStatusesUseCase)),
            BlocProvider(create: (_) => ContactPropertiesBloc(getContactPropertiesUseCase: getContactPropertiesUseCase)),
            BlocProvider(create: (_) => PipelineCubit(pipelineRemoteDataSource)),
            BlocProvider(create: (_) => ActivityBloc(getActivitiesUseCase: getActivitiesUseCase, createActivityUseCase: createActivityUseCase, postStatusFollowUseCase: postStatusFollowUseCase)),
            BlocProvider(create: (_) => NotifActivityBloc(getActivitiesUseCase: getActivitiesUseCase, createActivityUseCase: createActivityUseCase, postStatusFollowUseCase: postStatusFollowUseCase)),
            BlocProvider(create: (_) => ContactDetailActivityBloc(getActivitiesUseCase: getActivitiesUseCase, createActivityUseCase: createActivityUseCase, postStatusFollowUseCase: postStatusFollowUseCase)),
            BlocProvider(create: (_) => ActivityVisitBloc(createActivityVisitUseCase)),
            BlocProvider(create: (_) => AttachmentTypeBloc(getAttachmentTypesUseCase)),
            BlocProvider(create: (_) => UploadAttachmentBloc(uploadAttachmentUseCase, updateAttachmentUseCase)),
            BlocProvider(create: (_) => AttachmentCubit(getAttachmentsUseCase, deleteAttachmentUseCase)),
            BlocProvider(create: (_) => ActivityProspectStatusBloc(getActivityProspectStatusUseCase)),
            BlocProvider(create: (_) => AttendanceBloc(getAttendanceUseCase: getAttendanceUseCase, getTodayAttendanceUseCase: getTodayAttendanceUseCase, getLocationsUseCase: getLocationsUseCase, getOfficeLocationsUseCase: getOfficeLocationsUseCase, submitAttendanceUseCase: submitAttendanceUseCase, submitAttendanceActivityUseCase: submitAttendanceActivityUseCase)),
            BlocProvider(create: (_) => PameranLocationCubit(getLocationsUseCase)),
            BlocProvider(create: (_) => OfficeLocationCubit(getOfficeLocationsUseCase)),
            BlocProvider(create: (_) => AllOfficeLocationCubit(getAllOfficeLocationsUseCase)),
            BlocProvider(create: (_) => AttendanceActivityBloc(getAttendanceActivityUseCase: getAttendanceActivityUseCase, validasiCheckInUseCase: validasiCheckInUseCase)),
            BlocProvider(create: (_) => AttendanceApprovalCubit(getAttendanceApprovalTodayUseCase, postAttendanceApprovalUseCase)),
            BlocProvider(create: (_) => AttendanceExcelCubit(attendanceRepository)),
            BlocProvider(create: (_) => ReceivedNotifCubit()),
            BlocProvider(create: (_) => GlobalNotificationCubit(globalNotificationRemoteDataSource)),
            BlocProvider(create: (_) => WhatsappActivityBloc(getWhatsappActivityUseCase)),
            BlocProvider(create: (_) => InfoSourceBloc(getInfoSourcesUseCase: getInfoSourcesUseCase)),
            BlocProvider(create: (_) => SalesHierarchyService(
              getSalesOwnersUseCase: getSalesOwnersUseCase,
              getSalesExecutivesUseCase: getSalesExecutivesUseCase,
              getSalesSupervisorsUseCase: getSalesSupervisorsUseCase,
              getSalesManagersUseCase: getSalesManagersUseCase,
              getSalesGeneralManagersUseCase: getSalesGeneralManagersUseCase,
              getSalesTeamsPaginatedUseCase: getSalesTeamsPaginatedUseCase,
              getSalesChannelDetailsUseCase: getSalesChannelDetailsUseCase,
            )),
            BlocProvider(create: (_) => LostReasonBloc(getLostReasonsUseCase: getLostReasonsUseCase)),
            BlocProvider(create: (_) => ProductTypeBloc(getProductTypesUseCase: getProductTypesUseCase)..add(const FetchProductTypesEvent())),
            BlocProvider(create: (_) => PropertyUnitCubit(getPropertyUnitsUseCase, getPropertyCommercialUnitsUseCase)),
            BlocProvider(create: (_) => UnitPickerCubit(getUnitHierarchyUseCase, getUnitLotsUseCase)),
            BlocProvider(create: (_) => PameranAktifCubit(contactRepository)),
            BlocProvider(create: (_) => LandingPageCubit(getLandingPageUrlUseCase)..fetchUrl()),
            BlocProvider(create: (_) => SiteplanBloc(siteplanRepository)..add(LoadSiteplanEvent())),
            BlocProvider(create: (_) => TownshipBloc(getTownshipsUseCase)..add(GetTownshipsEvent())),
            BlocProvider(create: (_) => SalesKitTownshipBloc(getTownshipsSalesKitUseCase)..add(GetSalesKitTownshipsEvent())),
            BlocProvider(create: (_) => SalesKitDetailBloc(getClustersUseCase: getClustersUseCase, getCommercialsUseCase: getCommercialsUseCase)),
            BlocProvider(create: (_) => ClusterMediaOverviewBloc(getClusterMediaUseCase, shareCaptionUseCase)),
            BlocProvider(create: (_) => ClusterMediaListBloc(getClusterMediaUseCase, shareCaptionUseCase)),
          ],
          child: MultiBlocListener(
            listeners: [
              BlocListener<AuthBloc, AuthState>(
                listener: (context, state) {
                  if (state is LoginSuccess) {
                    context.read<ProfileBloc>().add(GetProfileEvent());
                    context.read<AuthBloc>().add(FetchPermissionsEvent());
                    AppRouter.authNotifier.value = true;
                    
                    PushNotificationService.setDio(dioClient.dio);
                    PushNotificationService.sendTokenAfterLogin();
                    PushNotificationService.checkAndShowUpdateBanner();
                    AnalyticsService.logLogin();
                  } else if (state is AuthLoggedOut) {
                    debugPrint('[App] AuthLoggedOut — _resetApp dipanggil (keluar dari semua halaman)');
                    web_debug.logDebugError('App: AuthLoggedOut — _resetApp dipanggil (keluar dari semua halaman)');
                    AnalyticsService.clearUser();
                    _resetApp();
                  } else if (state is ImpersonationStarted || state is ImpersonationStopped) {
                    
                    
                    debugPrint('[App] ImpersonationStarted/Stopped — go /splash');
                    web_debug.logDebugError('App: ImpersonationStarted/Stopped — go /splash');
                    AppRouter.router.go('/splash');
                  }
                },
              ),
              
              BlocListener<ProfileBloc, ProfileState>(
                listener: (context, state) {
                  if (state is ProfileLoaded) {
                    AnalyticsService.setUserProperties(
                      userId: state.profile.userId.toString(),
                      role: state.profile.userRoleName,
                    );
                    settingsDs.getSettings().then((s) {
                      if (s.isNotEmpty) ApiConstants.applySettings(s);
                      _checkVersion();
                    });
                  }
                },
              ),
            ],
            child: Stack(
              children: [
                child!,
                if (_updateResult != null)
                  
                   UpdateScreen(
                    downloadUrl: _updateResult!.downloadUrl,
                    currentVersion: _updateResult!.currentVersion,
                    latestVersion: _updateResult!.latestVersion,
                  ),
              ],
            ),
          ),
          ),
        );
      },
    );
  }
}


