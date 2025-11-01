import 'package:flutter/material.dart';
import 'package:lms_publisher/ParentPannel/select_child_screen.dart';
import 'package:lms_publisher/Provider/UserProvider.dart';
import 'package:lms_publisher/Teacher_Panel/teacher_dashboard.dart';
import 'package:lms_publisher/screens/HomePage/HomePage.dart';
import 'package:lms_publisher/screens/School/School_manage.dart';
import 'package:lms_publisher/School_Panel/student_module/student_manage.dart';
import 'package:lms_publisher/School_Panel/teacher_module/teacher_manage.dart';
import 'package:lms_publisher/screens/SubscriptionScreen/subscription_dart.dart';
import 'package:lms_publisher/screens/AcademicsScreen/academics_screen.dart';
import 'package:lms_publisher/AdminScreen/AdminPublish/publisher_screen.dart';
import 'package:lms_publisher/School_Panel/School_panel_dashboard.dart';
import 'package:lms_publisher/School_Panel/class_module/class_manage_screen.dart';
import 'package:lms_publisher/School_Panel/subject_module/subject_module_screen.dart';
import 'package:lms_publisher/StudentPannel/MySubject/my_subject_screen.dart';
import 'package:lms_publisher/StudentPannel/Student_analytics/student_analytics_dashboard.dart';
import 'package:lms_publisher/StudentPannel/MyFavourite/my_favourite_subject.dart';


class NavigationHelper {
  /// ✅ Get the screen widget based on menu code
  static Widget? getScreenByMenuCode(String menuCode, {int? schoolRecNo}) {
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
      case 'M009': // School Panel
        return const SchoolPanelDashboard();
      case 'M012': // Class Module
        return ClassManageScreen(schoolRecNo: schoolRecNo ?? 0);
      case 'M010': // Subject Module
        return SubjectModuleScreen(
          schoolRecNo: schoolRecNo ?? 0,
          academicYear: '2025-26',
        );
      case 'M011': // My Subjects (Student)
        return const MySubjectsScreen();
      case 'M013': // My Analytics
        return const StudentAnalyticsDashboard();
      case 'M014': // My Favourites
        return const MyFavouritesScreen();
      case 'M015': // Teacher Dashboard
        return const TeacherDashboard();
      case 'M000': // Parent - Select Child
        return const SelectChildScreen();
      case 'M006': // Settings
        return const HomeScreen(); // Replace with actual settings screen
      default:
        return null;
    }
  }

  /// ✅ Navigate to the first accessible screen based on lowest sequence number
  static void navigateToFirstScreen(
      BuildContext context,
      UserProvider userProvider, {
        bool excludeM000 = false, // ✅ Option to exclude M000 (Select Child screen)
      }) {
    // ✅ Get the menu with lowest sequence number (optionally excluding M000)
    final firstMenu = userProvider.getLowestSequenceMenu(excludeM000: excludeM000);

    if (firstMenu == null) {
      print('❌ No accessible menus found for user');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
      return;
    }

    print('✅ Navigating to first screen based on SNo');
    print('   MenuCode: ${firstMenu.menuCode}');
    print('   MenuText: ${firstMenu.menuText}');
    print('   SNo: ${firstMenu.sNo}');
    print('   excludeM000: $excludeM000');

    // ✅ If first menu is M000 and we're not excluding it, show child selection
    if (firstMenu.menuCode == 'M000' && !excludeM000) {
      print('   → Navigating to Parent Child Selection Screen');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SelectChildScreen()),
      );
      return;
    }

    // Get schoolRecNo if needed
    final schoolRecNo = int.tryParse(userProvider.userCode ?? '0') ?? 0;

    // Get the screen widget
    final screen = getScreenByMenuCode(firstMenu.menuCode, schoolRecNo: schoolRecNo);

    if (screen != null) {
      print('   → Navigating to ${firstMenu.menuText}');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => screen),
      );
    } else {
      print('⚠️ Screen not found for menu code: ${firstMenu.menuCode}');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }
}
