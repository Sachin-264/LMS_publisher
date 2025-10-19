// lib/Service/navigation_service.dart
import 'package:flutter/material.dart';

class NavigationService {
  // Global Navigator Key - This is accessible anywhere
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  // Helper method to get BuildContext
  static BuildContext? get context => navigatorKey.currentContext;
}
