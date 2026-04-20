import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:progress_group/core/network/dio_client.dart';
import 'package:progress_group/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:progress_group/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:progress_group/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:progress_group/features/auth/domain/usecase/forgot_password_usecase.dart';
import 'package:progress_group/features/auth/domain/usecase/get_remember_me_usecase.dart';
import 'package:progress_group/features/auth/domain/usecase/login_usecase.dart';
import 'package:progress_group/features/auth/domain/usecase/get_profile_usecase.dart';
import 'package:progress_group/features/auth/domain/usecase/reset_password_usecase.dart';
import 'package:progress_group/features/auth/presentation/state/bloc/auth_bloc.dart';
import 'package:progress_group/features/auth/presentation/state/profile/profile_bloc.dart';
import 'package:progress_group/features/inbox/data/datasources/inbox_remote_datasource.dart';
import 'package:progress_group/features/inbox/data/repositories/inbox_contact_repo_impl.dart';
import 'package:progress_group/features/inbox/domain/usecases/inbox_contact_usecase.dart';
import 'package:progress_group/features/inbox/presentation/state/inbox_block.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/router.dart';
import 'core/utils/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  final prefs = await SharedPreferences.getInstance();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.white,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );

  runApp(MyApp(prefs: prefs));
}

class MyApp extends StatelessWidget {
  final SharedPreferences prefs;
  const MyApp({super.key, required this.prefs});

  @override
  Widget build(BuildContext context) {
    final localDataSource = AuthLocalDataSourceImpl(prefs);
    final dioClient = DioClient(localDataSource);
    final remoteDataSource = AuthRemoteDataSourceImpl(dioClient.dio);
    final repository = AuthRepositoryImpl(remoteDataSource, localDataSource);

    final loginUseCase = LoginUseCase(repository);
    final forgotPasswordUseCase = ForgotPasswordUseCase(repository);
    final getRememberMeUseCase = GetRememberMeUseCase(repository);
    final resetPasswordUsecase = ResetPasswordUsecase(repository);
    final getProfileUseCase = GetProfileUseCase(repository);


    final inboxRemoteDataSource = InboxContactRemoteDataSourceImpl(dioClient.dio);
    final inboxRepository = InboxContactRepositoryImpl(inboxRemoteDataSource);
    final getInboxContactsUsecase = GetInboxContactsUsecase(inboxRepository);

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => AuthBloc(
            loginUseCase: loginUseCase,
            forgotPasswordUseCase: forgotPasswordUseCase,
            getRememberMeUseCase: getRememberMeUseCase,
            resetPasswordUsecase: resetPasswordUsecase
          ),
        ),
        BlocProvider(
          create: (_) => InboxContactBloc(getInboxContactsUsecase),
        ),
        BlocProvider(
          create: (_) => ProfileBloc(getProfileUseCase: getProfileUseCase),
        ),
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        routerConfig: AppRouter.router,
      ),
    );
  }
}
