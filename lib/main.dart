// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lms_publisher/AdminScreen/AdminPublish/Publisher_bloc.dart';
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

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => UserProvider(),
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
              )..add(LoadUserGroups()),
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
          ],
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'LMS Publisher',
            navigatorKey: NavigationService.navigatorKey,
            home: Consumer<UserProvider>(
              builder: (context, userProvider, child) {
                return userProvider.isLoggedIn
                    ? const HomeScreen()
                    : const ResponsiveLoginScreen();
              },
            ),
          ),
        ),
      ),
    );
  }
}
