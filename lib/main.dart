// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:lms_publisher/AdminScreen/AdminPublish/Publisher_bloc.dart';
import 'package:lms_publisher/ParentPannel/select_child_screen.dart';
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
import 'package:lms_publisher/Teacher_Panel/teacher_dashboard.dart';
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

// ✅ Import additional screens needed for routing
import 'package:lms_publisher/screens/School/School_manage.dart';
import 'package:lms_publisher/School_Panel/student_module/student_manage.dart';
import 'package:lms_publisher/School_Panel/teacher_module/teacher_manage.dart';
import 'package:lms_publisher/screens/SubscriptionScreen/subscription_dart.dart';
import 'package:lms_publisher/screens/AcademicsScreen/academics_screen.dart';
import 'package:lms_publisher/AdminScreen/AdminPublish/publisher_screen.dart';
import 'package:lms_publisher/School_Panel/School_panel_dashboard.dart';
import 'package:lms_publisher/School_Panel/subject_module/subject_module_screen.dart';

// ✅ Student Panel Imports
import 'package:lms_publisher/StudentPannel/MySubject/my_subject_screen.dart';
import 'package:lms_publisher/StudentPannel/Student_analytics/student_analytics_dashboard.dart';
import 'package:lms_publisher/StudentPannel/MyFavourite/my_favourite_subject.dart';



// Class Module Imports
import 'package:lms_publisher/School_Panel/class_module/class_manage_screen.dart';
import 'package:lms_publisher/School_Panel/class_module/class_service.dart';
import 'package:lms_publisher/School_Panel/class_module/class_bloc.dart';

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
          // ✅ Class Service
          RepositoryProvider(
            create: (context) => ClassApiService(),
          ),
        ],
        child: MultiBlocProvider(
          providers: [
            // Login BLoC
            BlocProvider(
              create: (context) => LoginBloc(
                userRightsService: context.read<UserRightsService>(),
                userProvider: context.read<UserProvider>(),
              ),
            ),
            // Dashboard BLoC
            BlocProvider(
              create: (context) => DashboardBloc(
                dashboardApiService: context.read<DashboardApiService>(),
              ),
            ),
            // School Management BLoC
            BlocProvider(
              create: (context) => SchoolManageBloc(
                schoolApiService: context.read<SchoolApiService>(),
              ),
            ),
            // Add/Edit School BLoC
            BlocProvider(
              create: (context) => AddEditSchoolBloc(
                schoolApiService: context.read<SchoolApiService>(),
              ),
            ),
            // Publisher BLoC
            BlocProvider(
              create: (context) => PublisherBloc(
                context.read<PublisherApiService>(),
              ),
            ),
            // Subject Module BLoC
            BlocProvider(
              create: (context) => SubjectModuleBloc(
                context.read<SubjectModuleApiService>(),
              ),
            ),
            // Student BLoC
            BlocProvider(
              create: (context) => StudentBloc(
                apiService: RepositoryProvider.of<StudentApiService>(context),
              ),
            ),
            // Teacher BLoC
            BlocProvider(
              create: (context) => TeacherBloc(
                apiService: RepositoryProvider.of<TeacherApiService>(context),
              ),
            ),
            // ✅ Class BLoC
            BlocProvider(
              create: (context) => ClassBloc(
                apiService: RepositoryProvider.of<ClassApiService>(context),
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
                        ? _getDefaultHomePage(userProvider)
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

  // ✅ UPDATED: Function to get the default homepage based on lowest sequence number
  Widget _getDefaultHomePage(UserProvider userProvider) {
    // Get the menu with the lowest sequence number
    final firstMenu = userProvider.getLowestSequenceMenu();

    if (firstMenu == null) {
      // Fallback to HomeScreen if no menus are available
      print('⚠️ No menus found, falling back to HomeScreen');
      return const HomeScreen();
    }

    print('✅ Default home page based on SNo: ${firstMenu.sNo}');
    print('   MenuCode: ${firstMenu.menuCode}');
    print('   MenuText: ${firstMenu.menuText}');

    // Route to the appropriate screen based on menuCode
    return _getScreenByMenuCode(firstMenu.menuCode, userProvider);
  }

  // ✅ UPDATED: Helper function to map menuCode to Widget
  Widget _getScreenByMenuCode(String menuCode, UserProvider userProvider) {
    // Get userCode for screens that need it
    final userCode = userProvider.userCode ?? '';
    final schoolRecNo = int.tryParse(userCode) ?? 1;
    const String defaultAcademicYear = '2025-26';

    switch (menuCode) {
      case 'M001': // Dashboard
        return const HomeScreen();
      case 'M002': // Schools
        return const SchoolsScreen();
      case 'M007': // Students
        return const StudentsScreen();
      case 'M008': // Teachers
        return const TeachersScreen();
      case 'M003': // Subscriptions
        return const SubscriptionsScreen();
      case 'M004': // Academics
        return const AcademicsScreen();
      case 'M005': // Publishers
        return const PublisherScreen();
      case 'M009': // School Panel Dashboard
        return const SchoolPanelDashboard();
      case 'M010': // Subject Module
        return SubjectModuleScreen(
          schoolRecNo: schoolRecNo,
          academicYear: defaultAcademicYear,
        );
      case 'M012': // Class Module
        return ClassManageScreen(
          schoolRecNo: schoolRecNo,
        );
    // ✅ STUDENT PANEL ROUTES
      case 'M011': // My Subjects
        return const MySubjectsScreen();
      case 'M013': // My Analytics
        return const StudentAnalyticsDashboard();
      case 'M014': // My Favourites
        return const MyFavouritesScreen();
    // ✅ TEACHER PANEL ROUTES
      case 'M015': // Teacher Dashboard
        return const TeacherDashboard();
    // ✅ PARENT PANEL ROUTES
      case 'M000': // Select Child (Parent)
        return const SelectChildScreen();
    // ✅ SETTINGS
      case 'M006': // Settings
        return const HomeScreen(); // Replace with actual Settings screen when available
      default:
      // Fallback to Dashboard if menuCode doesn't match
        print('⚠️ Unknown menuCode: $menuCode, falling back to HomeScreen');
        return const HomeScreen();
    }
  }
}
