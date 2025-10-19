// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:lms_publisher/AdminScreen/AdminPublish/Publisher_bloc.dart';
import 'package:lms_publisher/Provider/ConnectivityProvider.dart';
import 'package:lms_publisher/Provider/UserProvider.dart';
import 'package:lms_publisher/School_Panel/student_module/student_bloc.dart';
import 'package:lms_publisher/School_Panel/student_module/student_service.dart';
import 'package:lms_publisher/School_Panel/teacher_module/teacher_bloc.dart';
import 'package:lms_publisher/School_Panel/teacher_module/teacher_service.dart';
import 'package:lms_publisher/Service/dashboard_service.dart' show DashboardApiService;
import 'package:lms_publisher/Service/publisher_api_service.dart';
import 'package:lms_publisher/Service/user_right_service.dart';
import 'package:lms_publisher/Service/navigation_service.dart';
import 'package:lms_publisher/screens/HomePage/HomePage.dart';
import 'package:lms_publisher/screens/HomePage/dashboard_bloc.dart';
import 'package:lms_publisher/screens/LoginScreen/login_bloc.dart';
import 'package:lms_publisher/screens/LoginScreen/responsive_login_screen.dart';
import 'package:lms_publisher/screens/School/school_managebloc.dart';
import 'package:lms_publisher/service/school_service.dart';
import 'package:lms_publisher/screens/School/add_school_bloc.dart';
import 'package:lms_publisher/School_Panel/school_panel_dashboard_bloc.dart';
import 'package:lms_publisher/School_Panel/subject_module/subject_module_api_service.dart';
import 'package:lms_publisher/School_Panel/subject_module/subject_module_bloc.dart';
import 'package:provider/provider.dart';
import 'Util/custom_snackbar.dart';
import 'Theme/apptheme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // User Provider
        ChangeNotifierProvider(
          create: (context) => UserProvider(),
        ),
        // Connectivity Provider (App-wide network monitoring)
        ChangeNotifierProvider(
          create: (context) => ConnectivityProvider(),
        ),
      ],
      child: MultiRepositoryProvider(
        providers: [
          // Authentication Service
          RepositoryProvider(
            create: (context) => UserRightsService(),
          ),
          // Dashboard Service
          RepositoryProvider(
            create: (context) => DashboardApiService(),
          ),
          // School Service
          RepositoryProvider(
            create: (context) => SchoolApiService(),
          ),
          // Publisher Service
          RepositoryProvider(
            create: (context) => PublisherApiService(),
          ),
          // Subject Module Service
          RepositoryProvider(
            create: (context) => SubjectModuleApiService(),
          ),
          // Student Service
          RepositoryProvider(
            create: (context) => StudentApiService(),
          ),
          // Teacher Service
          RepositoryProvider(
            create: (context) => TeacherApiService(),
          ),
        ],
        child: MultiBlocProvider(
          providers: [
            // Login BLoC
            BlocProvider(
              create: (context) => LoginBloc(
                userRightsService: context.read(),
                userProvider: context.read(),
              ),
            ),
            // Dashboard BLoC
            BlocProvider(
              create: (context) => DashboardBloc(
                dashboardApiService: context.read(),
              ),
            ),
            // School Management BLoC
            BlocProvider(
              create: (context) => SchoolManageBloc(
                schoolApiService: context.read(),
              ),
            ),
            // Add/Edit School BLoC
            BlocProvider(
              create: (context) => AddEditSchoolBloc(
                schoolApiService: context.read(),
              ),
            ),
            // Publisher BLoC
            BlocProvider(
              create: (context) => PublisherBloc(
                context.read(),
              ),
            ),
            // Subject Module BLoC
            BlocProvider(
              create: (context) => SubjectModuleBloc(
                context.read(),
              ),
            ),
            // Student BLoC
            BlocProvider(
              create: (context) => StudentBloc(
                apiService: RepositoryProvider.of(context),
              ),
            ),
            // Teacher BLoC
            BlocProvider(
              create: (context) => TeacherBloc(
                apiService: RepositoryProvider.of(context),
              ),
            ),
          ],
          child: Consumer<ConnectivityProvider>(
            builder: (context, connectivity, child) {
              return MaterialApp(
                debugShowCheckedModeBanner: false,
                title: 'LMS Publisher',
                navigatorKey: NavigationService.navigatorKey,
                builder: (context, widget) {
                  return Stack(
                    children: [
                      widget!,
                      // Global connectivity banner
                      if (!connectivity.isOnline)
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: Material(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              color: Colors.red.shade600,
                              child: SafeArea(
                                bottom: false,
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.wifi_off,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'No Internet Connection',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
                home: Consumer<UserProvider>(
                  builder: (context, userProvider, child) {
                    return userProvider.isLoggedIn
                        ? const HomeScreen()
                        : const ResponsiveLoginScreen();
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
