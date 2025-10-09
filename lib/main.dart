// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lms_publisher/Service/dashboard_service.dart' show DashboardApiService;
import 'package:lms_publisher/screens/HomePage/HomePage.dart';
import 'package:lms_publisher/screens/HomePage/dashboard_bloc.dart';
import 'package:lms_publisher/screens/School/school_managebloc.dart';
import 'package:lms_publisher/service/school_service.dart';
import 'package:lms_publisher/screens/School/add_school_bloc.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<DashboardApiService>(
          create: (context) => DashboardApiService(),
        ),
        RepositoryProvider<SchoolApiService>(
          create: (context) => SchoolApiService(),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<DashboardBloc>(
            create: (context) => DashboardBloc(
              dashboardApiService: context.read<DashboardApiService>(),
            )..add(FetchDashboardData()),
          ),
          BlocProvider<SchoolManageBloc>(
            create: (context) => SchoolManageBloc(
              schoolApiService: context.read<SchoolApiService>(),
            ),
          ),
          BlocProvider<AddEditSchoolBloc>(
            create: (context) => AddEditSchoolBloc(
              schoolApiService: context.read<SchoolApiService>(),
            ),
          ),
        ],
        child: const MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'LMS Publisher',
          home: HomeScreen(),
        ),
      ),
    );
  }
}