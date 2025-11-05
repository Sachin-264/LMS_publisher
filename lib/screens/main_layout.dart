// main_layout.dart

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart'; // Still needed
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:lms_publisher/AdminScreen/AdminPublish/publisher_screen.dart';
import 'package:lms_publisher/ParentPannel/select_child_screen.dart';
import 'package:lms_publisher/Provider/UserProvider.dart';
import 'package:lms_publisher/School_Panel/School_panel_dashboard.dart';
import 'package:lms_publisher/School_Panel/student_module/student_manage.dart';
import 'package:lms_publisher/School_Panel/teacher_module/teacher_manage.dart';
import 'package:lms_publisher/School_Panel/subject_module/subject_module_screen.dart';
import 'package:lms_publisher/StudentPannel/MyFavourite/my_favourite_subject.dart';
import 'package:lms_publisher/StudentPannel/MySubject/my_subject_screen.dart';
import 'package:lms_publisher/StudentPannel/Student_analytics/student_analytics_dashboard.dart';
import 'package:lms_publisher/Teacher_Panel/MyClass/teacher_classes_screen.dart';
import 'package:lms_publisher/Teacher_Panel/teacher_dashboard.dart';
import 'package:lms_publisher/Theme/apptheme.dart';
import 'package:lms_publisher/address_master_screen.dart';
import 'package:lms_publisher/screens/AcademicsScreen/academics_screen.dart';
import 'package:lms_publisher/screens/HomePage/HomePage.dart';
import 'package:lms_publisher/screens/LogOutTransition.dart';
import 'package:lms_publisher/screens/School/School_manage.dart';
import 'package:lms_publisher/screens/SubscriptionScreen/subscription_dart.dart';
import 'package:lms_publisher/screens/LoginScreen/login_bloc.dart';
import 'package:provider/provider.dart';
import '../School_Panel/class_module/class_manage_screen.dart';

// Enum to identify the active screen for the sidebar
enum AppScreen {
  dashboard,
  schools,
  students,
  teachers,
  subscriptions,
  academics,
  publishers,
  schoolPanel,
  subjectModule,
  mySubjects,
  analytics,
  myFavourites,
  classModule,
  teacherDashboard,
  teacherClasses,
  teacherStudents,
  teacherAnalytics,
  settings,
  parentChildren,
  addressMaster,
}

// ✅ State management for sidebar
final ValueNotifier<bool> isSidebarCollapsed = ValueNotifier(true);
final ValueNotifier<bool> isMobileMenuOpen = ValueNotifier(false);

// ✅ UPDATED: MainLayout
class MainLayout extends StatefulWidget {
  final Widget child;
  final AppScreen activeScreen;

  const MainLayout({
    super.key,
    required this.child,
    required this.activeScreen,
  });

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= 0 &&
          _scrollController.position.pixels % 100 < 1) {}
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // ✅ ADDED: Helper to get the icon for each screen
  IconData _getIconForScreen(AppScreen screen) {
    switch (screen) {
      case AppScreen.dashboard:
        return Iconsax.home;
      case AppScreen.schools:
        return Iconsax.building_4;
      case AppScreen.students:
        return Iconsax.profile_2user;
      case AppScreen.teachers:
        return Iconsax.teacher;
      case AppScreen.subscriptions:
        return Iconsax.receipt_text;
      case AppScreen.academics:
        return Iconsax.book_1;
      case AppScreen.publishers:
        return Iconsax.user_square;
      case AppScreen.schoolPanel:
        return Iconsax.monitor;
      case AppScreen.classModule:
        return Iconsax.building;
      case AppScreen.subjectModule:
        return Iconsax.book_square;
      case AppScreen.mySubjects:
        return Iconsax.book_1;
      case AppScreen.analytics:
        return Iconsax.chart_21;
      case AppScreen.myFavourites:
        return Iconsax.heart;
      case AppScreen.teacherDashboard:
        return Iconsax.teacher;
      case AppScreen.teacherClasses:
        return Iconsax.book_square;
      case AppScreen.addressMaster:
        return Iconsax.location;
      case AppScreen.parentChildren:
        return Iconsax.profile_2user;
      case AppScreen.settings:
        return Iconsax.setting_2;
      default:
        return Iconsax.home;
    }
  }

  // ✅ ADDED: Helper to get the title for each screen
  String _getTitleForScreen(AppScreen screen) {
    switch (screen) {
      case AppScreen.dashboard:
        return 'Dashboard';
      case AppScreen.schools:
        return 'Manage Schools';
      case AppScreen.students:
        return 'Manage Students';
      case AppScreen.teachers:
        return 'Manage Teachers';
      case AppScreen.subscriptions:
        return 'Subscriptions';
      case AppScreen.academics:
        return 'Academics';
      case AppScreen.publishers:
        return 'Publishers';
      case AppScreen.schoolPanel:
        return 'School Panel';
      case AppScreen.classModule:
        return 'Class Management';
      case AppScreen.subjectModule:
        return 'Subject Module';
      case AppScreen.mySubjects:
        return 'My Subjects';
      case AppScreen.analytics:
        return 'My Analytics';
      case AppScreen.myFavourites:
        return 'My Favourites';
      case AppScreen.teacherDashboard:
        return 'Teacher Dashboard';
      case AppScreen.teacherClasses:
        return 'My Classes';
      case AppScreen.addressMaster:
        return 'Address Master';
      case AppScreen.parentChildren:
        return 'My Children';
      case AppScreen.settings:
        return 'Settings';
      default:
        return 'Dashboard';
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    // ✅ Get title and icon here
    final String title = _getTitleForScreen(widget.activeScreen);
    final IconData icon = _getIconForScreen(widget.activeScreen);

    return Scaffold(
      backgroundColor: AppTheme.lightGrey,
      drawer: isMobile
          ? _MobileDrawer(
        activeScreen: widget.activeScreen,
      )
          : null,
      body: SafeArea(
        top: true,
        bottom: true,
        left: true,
        right: true,
        child: ValueListenableBuilder<bool>(
          valueListenable: isSidebarCollapsed,
          builder: (context, isCollapsed, _) {
            final double mainContentLeft =
            isMobile ? 0 : (isCollapsed ? 80 : 280);

            return Stack(
              children: [
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOutCubic,
                  left: mainContentLeft,
                  top: 0,
                  right: 0,
                  bottom: 0,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1400),
                      child: Padding(
                        padding: EdgeInsets.all(
                          isMobile ? 12 : AppTheme.defaultPadding * 1.5,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ✅ UPDATED: Pass title and icon to header
                            _Header(
                              isMobile: isMobile,
                            ),
                            SizedBox(
                                height: isMobile
                                    ? 12
                                    : AppTheme.defaultPadding * 1.5),
                            Expanded(
                              child: widget.child,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                if (!isMobile)
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOutCubic,
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: isCollapsed ? 80 : 280,
                    child: _ModernCollapsibleSidebar(
                      isCollapsed: isCollapsed,
                      activeScreen: widget.activeScreen,
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// (This widget is unchanged)
class _MobileMenuItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isActive;
  final VoidCallback? onTap;
  final Color? textColor;
  final Color? iconColor;

  const _MobileMenuItem({
    required this.icon,
    required this.text,
    this.isActive = false,
    this.onTap,
    this.textColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveTextColor =
        textColor ?? (isActive ? AppTheme.primaryGreen : AppTheme.bodyText);
    final effectiveIconColor =
        iconColor ?? (isActive ? AppTheme.primaryGreen : AppTheme.bodyText);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: isActive
            ? AppTheme.primaryGreen.withOpacity(0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: isActive
                  ? Border.all(color: AppTheme.primaryGreen.withOpacity(0.3))
                  : null,
            ),
            child: Row(
              children: [
                Icon(icon, color: effectiveIconColor, size: 22),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    text,
                    style: AppTheme.bodyText1.copyWith(
                      color: effectiveTextColor,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                      fontSize: 15,
                    ),
                  ),
                ),
                if (isActive)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryGreen,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final bool isMobile;
  // final String title; // REMOVED

  const _Header({
    required this.isMobile,
    // required this.title, // REMOVED
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, _) {
        String userName = userProvider.userName ?? 'Admin User';
        String userInitial = userName.isNotEmpty ? userName[0].toUpperCase() : 'A';

        return LayoutBuilder(
          builder: (context, constraints) {
            bool isCompact = constraints.maxWidth < 750;

            return Container(
              // ✅ 1. THE "TOP-MOST LAYER" (FROSTED GLASS)
              decoration: BoxDecoration(
                color: AppTheme.background.withOpacity(0.85),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  // Soft green glow from your theme
                  BoxShadow(
                    color: AppTheme.shadowColor,
                    blurRadius: 40,
                    offset: const Offset(0, 10),
                    spreadRadius: -10,
                  ),
                  // Tighter shadow for edge definition
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
                border: Border.all(
                  color: AppTheme.background.withOpacity(0.9),
                  width: 1.5,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 12 : 28,
                      vertical: isMobile ? 12 : 18,
                    ),
                    child: isMobile
                        ? _MobileHeaderContent(
                      userName: userName,
                      userInitial: userInitial,
                    )
                        : _DesktopHeaderContent(
                      userName: userName,
                      userInitial: userInitial,
                      isCompact: isCompact,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// =======================================================================
// ✅ NEW MOBILE HEADER (Replaces old _MobileHeaderContent)
// =======================================================================
class _MobileHeaderContent extends StatelessWidget {
  final String userName;
  final String userInitial;

  const _MobileHeaderContent({
    required this.userName,
    required this.userInitial,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Menu Button
        _HeaderMenuButton(
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
        // App Logo (Replaces Title)
        const Expanded(
          child: _AppLogo(size: 18),
        ),
        // Notification Button
        _HeaderNotificationButton(
          onPressed: () {},
          hasBadge: true,
        ),
      ],
    );
  }
}

// =======================================================================
// ✅ NEW DESKTOP HEADER (Replaces old _DesktopHeaderContent)
// =======================================================================
class _DesktopHeaderContent extends StatelessWidget {
  final String userName;
  final String userInitial;
  final bool isCompact;

  const _DesktopHeaderContent({
    required this.userName,
    required this.userInitial,
    required this.isCompact,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // ✅ NEW TEXT LAYOUT (Logo + Welcome)
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. App Logo (Replaces Title)
              const _AppLogo(size: 28),
              const SizedBox(height: 4),
              // 2. Welcome is secondary
              Text(
                'Welcome back, $userName',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.bodyText.withOpacity(0.9),
                ),
              ),
            ],
          ),
        ),

        if (!isCompact) const SizedBox(width: 28),

        // ✅ RIGHT SECTION: "IMPROVED" SOLID ACTIONS
        if (!isCompact)
          Row(
            children: [
              // Improved Notification Button
              _HeaderNotificationButton(
                onPressed: () {},
                hasBadge: true,
              ),
              const SizedBox(width: 16),

              // Improved User Profile Card
              _HeaderUserCard(
                userName: userName,
                userInitial: userInitial,
              ),
            ],
          ),
      ],
    );
  }
}

// =======================================================================
// ✅ NEW: App Logo Widget
// =======================================================================
class _AppLogo extends StatelessWidget {
  final double size;
  const _AppLogo({this.size = 24});

  @override
  Widget build(BuildContext context) {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: AppTheme.logoStyle.copyWith(
          fontSize: size,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
        children: const [
          TextSpan(
            text: 'MACK',
            style: TextStyle(color: AppTheme.mackColor),
          ),
          TextSpan(
            text: 'CLEO',
            style: TextStyle(color: AppTheme.cleoColor),
          ),
        ],
      ),
    );
  }
}

// =======================================================================
// ✅ NEW "IMPROVED" HELPER WIDGETS
// (These sit *on top* of the glass, using solid AppTheme.background)
// =======================================================================

// --- Base Button for solid components ---
class _HeaderSolidButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onPressed;
  final EdgeInsetsGeometry padding;
  final BoxShape shape;

  const _HeaderSolidButton({
    required this.child,
    required this.onPressed,
    this.padding = const EdgeInsets.all(10),
    this.shape = BoxShape.circle,
  });

  @override
  State<_HeaderSolidButton> createState() => _HeaderSolidButtonState();
}

class _HeaderSolidButtonState extends State<_HeaderSolidButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: widget.padding,
          decoration: BoxDecoration(
            // Solid, elevated feel
            color: _isHovered ? AppTheme.lightGrey : AppTheme.background,
            shape: widget.shape,
            borderRadius: widget.shape == BoxShape.circle
                ? null
                : BorderRadius.circular(50), // for pill shape
            border: Border.all(
              color: _isHovered ? AppTheme.borderGrey : AppTheme.borderGrey.withOpacity(0.7),
              width: 1.5,
            ),
            // Shadow makes it pop off the glass
            boxShadow: [
              BoxShadow(
                color: AppTheme.shadowColor.withOpacity(
                  _isHovered ? 0.3 : 0.2,
                ),
                blurRadius: 8,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

// --- Mobile Menu Button ---
class _HeaderMenuButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _HeaderMenuButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return _HeaderSolidButton(
      onPressed: onPressed,
      child: Icon(
        Iconsax.menu_1,
        color: AppTheme.bodyText,
        size: 18,
      ),
    );
  }
}

// --- "IMPROVED" Notification Button ---
class _HeaderNotificationButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool hasBadge;

  const _HeaderNotificationButton({
    required this.onPressed,
    this.hasBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    return _HeaderSolidButton(
      onPressed: onPressed,
      child: Stack(
        children: [
          Icon(
            Iconsax.notification,
            size: 19,
            color: AppTheme.bodyText,
          ),
          if (hasBadge)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.red.shade400, Colors.red.shade600],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.5),
                      blurRadius: 5,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// --- "IMPROVED" User Card (now a pill shape) ---
class _HeaderUserCard extends StatelessWidget {
  final String userName;
  final String userInitial;

  const _HeaderUserCard({
    required this.userName,
    required this.userInitial,
  });

  @override
  Widget build(BuildContext context) {
    return _HeaderSolidButton(
      onPressed: () {
        // TODO: Add profile navigation
      },
      shape: BoxShape.rectangle, // will be rounded by decoration
      padding: const EdgeInsets.fromLTRB(6, 6, 16, 6), // Asymmetrical padding
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(50), // circular avatar
              gradient: AppTheme.primaryGradient,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryGreen.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                userInitial,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                userName,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.darkText,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppTheme.accentGreen,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Online',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.accentGreen,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}



// --- Base Button for Header ---
class _HeaderBaseButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onPressed;

  const _HeaderBaseButton({
    required this.child,
    required this.onPressed,
  });

  @override
  State<_HeaderBaseButton> createState() => _HeaderBaseButtonState();
}

class _HeaderBaseButtonState extends State<_HeaderBaseButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            // Use lightGrey for hover, matching the page background
            color: _isHovered
                ? AppTheme.lightGrey
                : AppTheme.background.withOpacity(0.3),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: _isHovered
                  ? AppTheme.borderGrey
                  : AppTheme.borderGrey.withOpacity(0.4),
              width: 1.5,
            ),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}




class _HeaderActionButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final bool hasBadge;

  const _HeaderActionButton({
    required this.icon,
    required this.onPressed,
    this.hasBadge = false,
  });

  @override
  State<_HeaderActionButton> createState() => _HeaderActionButtonState();
}

class _HeaderActionButtonState extends State<_HeaderActionButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            color: _isHovered
                ? AppTheme.lightGrey
                : AppTheme.background,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: _isHovered
                  ? AppTheme.borderGrey
                  : AppTheme.borderGrey.withOpacity(0.7),
              width: 1.5,
            ),
          ),
          child: Stack(
            children: [
              Icon(
                widget.icon,
                size: 19,
                color: _isHovered
                    ? AppTheme.primaryGreen
                    : AppTheme.bodyText.withOpacity(0.7),
              ),
              if (widget.hasBadge)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.red.shade400, Colors.red.shade600],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.5),
                          blurRadius: 5,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}



// ✅ MOBILE NOTIFICATION BUTTON - THEMED GLASSY
class _MobileNotificationButton extends StatefulWidget {
  const _MobileNotificationButton();

  @override
  State<_MobileNotificationButton> createState() =>
      _MobileNotificationButtonState();
}

class _MobileNotificationButtonState extends State<_MobileNotificationButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () {},
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            // Use AppTheme.background
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _isHovered
                  ? [
                AppTheme.background.withOpacity(0.4),
                AppTheme.background.withOpacity(0.3),
              ]
                  : [
                AppTheme.background.withOpacity(0.25),
                AppTheme.background.withOpacity(0.15),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            // Use AppTheme.borderGrey
            border: Border.all(
              color: AppTheme.borderGrey.withOpacity(_isHovered ? 0.5 : 0.35),
              width: 1.5,
            ),
          ),
          child: Stack(
            children: [
              Icon(
                Iconsax.notification,
                size: 18,
                color: _isHovered
                    ? AppTheme.primaryGreen // Use theme color
                    : AppTheme.bodyText.withOpacity(0.7), // Use theme color
              ),
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.red.shade400,
                        Colors.red.shade600,
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.5),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


// ✅ GLASSY ACTION BUTTON - THEMED
class _GlassyActionButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final bool hasBadge;

  const _GlassyActionButton({
    required this.icon,
    required this.onPressed,
    this.hasBadge = false,
  });

  @override
  State<_GlassyActionButton> createState() => _GlassyActionButtonState();
}

class _GlassyActionButtonState extends State<_GlassyActionButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            // Use AppTheme.background
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _isHovered
                  ? [
                AppTheme.background.withOpacity(0.4),
                AppTheme.background.withOpacity(0.3),
              ]
                  : [
                AppTheme.background.withOpacity(0.2),
                AppTheme.background.withOpacity(0.15),
              ],
            ),
            borderRadius: BorderRadius.circular(13),
            // Use AppTheme.borderGrey
            border: Border.all(
              color: AppTheme.borderGrey.withOpacity(_isHovered ? 0.45 : 0.3),
              width: 1.5,
            ),
          ),
          child: Stack(
            children: [
              Icon(
                widget.icon,
                size: 19,
                color: _isHovered
                    ? AppTheme.primaryGreen // Use theme color
                    : AppTheme.bodyText.withOpacity(0.7), // Use theme color
              ),
              if (widget.hasBadge)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.red.shade400,
                          Colors.red.shade600,
                        ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.5),
                          blurRadius: 5,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ✅ GLASSY USER CARD - THEMED
class _GlassyUserCard extends StatefulWidget {
  final String userName;
  final String userInitial;

  const _GlassyUserCard({
    required this.userName,
    required this.userInitial,
  });

  @override
  State<_GlassyUserCard> createState() => _GlassyUserCardState();
}

class _GlassyUserCardState extends State<_GlassyUserCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          // Use AppTheme.background
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _isHovered
                ? [
              AppTheme.background.withOpacity(0.35),
              AppTheme.background.withOpacity(0.25),
            ]
                : [
              AppTheme.background.withOpacity(0.2),
              AppTheme.background.withOpacity(0.15),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          // Use AppTheme.borderGrey
          border: Border.all(
            color: AppTheme.borderGrey.withOpacity(_isHovered ? 0.45 : 0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                // Use AppTheme.primaryGradient
                gradient: AppTheme.primaryGradient,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryGreen.withOpacity(0.3), // Use theme color
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  widget.userInitial,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.userName,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.darkText, // Use theme color
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: AppTheme.accentGreen, // Use theme color
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Online',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.accentGreen, // Use theme color
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }
}


// ✅ DESKTOP HEADER
class _DesktopHeader extends StatefulWidget {
  final String title;
  final IconData icon;
  final String userName;
  final String userInitial;
  final bool isCompact;

  const _DesktopHeader({
    required this.title,
    required this.icon,
    required this.userName,
    required this.userInitial,
    required this.isCompact,
  });

  @override
  State<_DesktopHeader> createState() => _DesktopHeaderState();
}

class _DesktopHeaderState extends State<_DesktopHeader> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // ✅ LEFT SECTION: Title with Icon
        Expanded(
          child: MouseRegion(
            onEnter: (_) => setState(() => _isHovered = true),
            onExit: (_) => setState(() => _isHovered = false),
            child: Row(
              children: [
                // Icon Container with Gradient - DESKTOP
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: _isHovered
                          ? [
                        AppTheme.primaryGreen,
                        AppTheme.accentGreen,
                      ]
                          : [
                        AppTheme.primaryGreen.withOpacity(0.9),
                        AppTheme.accentGreen.withOpacity(0.85),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryGreen.withOpacity(
                          _isHovered ? 0.4 : 0.25,
                        ),
                        blurRadius: _isHovered ? 16 : 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: AnimatedScale(
                    duration: const Duration(milliseconds: 300),
                    scale: _isHovered ? 1.08 : 1.0,
                    child: Icon(
                      widget.icon,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 18),

                // Title Section
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Breadcrumb
                      Text(
                        'Welcome Back',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.bodyText.withOpacity(0.5),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Main Title
                      Text(
                        widget.title,
                        style: GoogleFonts.inter(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.darkText,
                          letterSpacing: -0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      // Subtitle
                      Text(
                        'Manage your ${widget.title.toLowerCase()}',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: AppTheme.bodyText.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        if (!widget.isCompact) const SizedBox(width: 24),

        // ✅ RIGHT SECTION: Actions
        if (!widget.isCompact)
          Row(
            children: [
              // Notification Button
              _HeaderActionButton(
                icon: Iconsax.notification,
                onPressed: () {},
                hasBadge: true,
              ),
              const SizedBox(width: 12),

              // Settings Button
              _HeaderActionButton(
                icon: Iconsax.setting_2,
                onPressed: () {},
              ),
              const SizedBox(width: 16),

              // User Profile Card
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.borderGrey.withOpacity(0.5),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.shadowColor.withOpacity(0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // User Avatar
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppTheme.primaryGreen,
                            AppTheme.accentGreen,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryGreen.withOpacity(0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          widget.userInitial,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // User Info
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.userName,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.darkText,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                color: AppTheme.accentGreen,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Online',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.accentGreen,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(width: 4),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }
}




// ==================== MODERN COLLAPSIBLE SIDEBAR ====================
// (This widget is unchanged)
class _ModernCollapsibleSidebar extends StatelessWidget {
  final bool isCollapsed;
  final AppScreen activeScreen;

  const _ModernCollapsibleSidebar({
    required this.isCollapsed,
    required this.activeScreen,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final int schoolRecNo = int.tryParse(userProvider.userCode ?? '0') ?? 0;

        return Container(
          decoration: BoxDecoration(
            color: AppTheme.background,
            boxShadow: [
              BoxShadow(
                color: AppTheme.darkText.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(2, 0),
              ),
            ],
            borderRadius: isCollapsed
                ? const BorderRadius.only(
              topRight: Radius.circular(16),
              bottomRight: Radius.circular(16),
            )
                : BorderRadius.zero,
          ),
          child: Column(
            children: [
              // Header Section
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: EdgeInsets.all(isCollapsed ? 16 : 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Iconsax.bezier,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    if (!isCollapsed) ...[
                      const SizedBox(width: 16),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: AppTheme.logoStyle.copyWith(fontSize: 18),
                            children: const [
                              TextSpan(
                                text: 'MACK',
                                style: TextStyle(color: AppTheme.mackColor),
                              ),
                              TextSpan(
                                text: 'CLEO',
                                style: TextStyle(color: AppTheme.cleoColor),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Toggle Button
              Padding(
                padding:
                EdgeInsets.symmetric(horizontal: isCollapsed ? 16 : 24),
                child: _SidebarToggleButton(isCollapsed: isCollapsed),
              ),

              const SizedBox(height: 16),

              // Navigation Menu
              Expanded(
                child: Padding(
                  padding:
                  EdgeInsets.symmetric(horizontal: isCollapsed ? 8 : 16),
                  child: Column(
                    children: [
                      // Dashboard - M001
                      if (userProvider.hasMenuAccess('M001')) ...[
                        _CollapsibleMenuItem(
                          icon: Iconsax.home,
                          text: 'Dashboard',
                          isActive: activeScreen == AppScreen.dashboard,
                          isCollapsed: isCollapsed,
                          onTap: () {
                            if (activeScreen != AppScreen.dashboard) {
                              Navigator.pushReplacement(
                                context,
                                SmoothPageRoute(
                                    page: const HomeScreen()),
                              );
                            }
                          },
                        ),
                      ],

                      // Schools - M002
                      if (userProvider.hasMenuAccess('M002')) ...[
                        _CollapsibleMenuItem(
                          icon: Iconsax.building_4,
                          text: 'Schools',
                          isActive: activeScreen == AppScreen.schools,
                          isCollapsed: isCollapsed,
                          onTap: () {
                            if (activeScreen != AppScreen.schools) {
                              Navigator.pushReplacement(
                                context,
                                SmoothPageRoute(
                                    page: const SchoolsScreen()),
                              );
                            }
                          },
                        ),
                      ],

                      // Students Menu Item (New Module) - M007
                      if (userProvider.hasMenuAccess('M007')) ...[
                        _CollapsibleMenuItem(
                          icon: Iconsax.profile_2user,
                          text: 'Students',
                          isActive: activeScreen == AppScreen.students,
                          isCollapsed: isCollapsed,
                          onTap: () {
                            if (activeScreen != AppScreen.students) {
                              Navigator.pushReplacement(
                                context,
                                SmoothPageRoute(
                                    page: const StudentsScreen()),
                              );
                            }
                          },
                        ),
                      ],

                      // Teachers Menu Item (New Module) - M008
                      if (userProvider.hasMenuAccess('M008')) ...[
                        _CollapsibleMenuItem(
                          icon: Iconsax.teacher,
                          text: 'Teachers',
                          isActive: activeScreen == AppScreen.teachers,
                          isCollapsed: isCollapsed,
                          onTap: () {
                            if (activeScreen != AppScreen.teachers) {
                              Navigator.pushReplacement(
                                context,
                                SmoothPageRoute(
                                    page: const TeachersScreen()),
                              );
                            }
                          },
                        ),
                      ],

                      // Subscriptions - M003
                      if (userProvider.hasMenuAccess('M003')) ...[
                        _CollapsibleMenuItem(
                          icon: Iconsax.receipt_text,
                          text: 'Subscriptions',
                          isActive: activeScreen == AppScreen.subscriptions,
                          isCollapsed: isCollapsed,
                          onTap: () {
                            if (activeScreen != AppScreen.subscriptions) {
                              Navigator.pushReplacement(
                                context,
                                SmoothPageRoute(
                                    page: const SubscriptionsScreen()),
                              );
                            }
                          },
                        ),
                      ],

                      // Academics - M004
                      if (userProvider.hasMenuAccess('M004')) ...[
                        _CollapsibleMenuItem(
                          icon: Iconsax.book_1,
                          text: 'Academics',
                          isActive: activeScreen == AppScreen.academics,
                          isCollapsed: isCollapsed,
                          onTap: () {
                            if (activeScreen != AppScreen.academics) {
                              Navigator.pushReplacement(
                                context,
                                SmoothPageRoute(
                                    page: const AcademicsScreen()),
                              );
                            }
                          },
                        ),
                      ],

                      // 🆕 ADDED: Publishers - M005
                      if (userProvider.hasMenuAccess('M005')) ...[
                        _CollapsibleMenuItem(
                          icon: Iconsax.user_square,
                          text: 'Publishers',
                          isActive: activeScreen == AppScreen.publishers,
                          isCollapsed: isCollapsed,
                          onTap: () {
                            if (activeScreen != AppScreen.publishers) {
                              Navigator.pushReplacement(
                                context,
                                SmoothPageRoute(
                                    page: const PublisherScreen()),
                              );
                            }
                          },
                        ),
                      ],

                      // School Panel - M009
                      if (userProvider.hasMenuAccess('M009')) ...[
                        _CollapsibleMenuItem(
                          icon: Iconsax.monitor,
                          text: 'School Panel',
                          isActive: activeScreen == AppScreen.schoolPanel,
                          isCollapsed: isCollapsed,
                          onTap: () {
                            if (activeScreen != AppScreen.schoolPanel) {
                              Navigator.pushReplacement(
                                context,
                                SmoothPageRoute(
                                    page: const SchoolPanelDashboard()),
                              );
                            }
                          },
                        ),
                      ],

                      // ✅ NEW MODULE: Class Module - M012
                      if (userProvider.hasMenuAccess('M012')) ...[
                        _CollapsibleMenuItem(
                          icon: Iconsax.building,
                          text: 'Class',
                          isActive: activeScreen == AppScreen.classModule,
                          isCollapsed: isCollapsed,
                          onTap: () {
                            if (activeScreen != AppScreen.classModule) {
                              Navigator.pushReplacement(
                                context,
                                SmoothPageRoute(
                                  page: ClassManageScreen(
                                    schoolRecNo: schoolRecNo,
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      ],

                      // Subject Module - M010
                      if (userProvider.hasMenuAccess('M010')) ...[
                        _CollapsibleMenuItem(
                          icon: Iconsax.book_square,
                          text: 'Subject Module',
                          isActive: activeScreen == AppScreen.subjectModule,
                          isCollapsed: isCollapsed,
                          onTap: () {
                            if (activeScreen != AppScreen.subjectModule) {
                              Navigator.pushReplacement(
                                context,
                                SmoothPageRoute(
                                  page: SubjectModuleScreen(
                                    schoolRecNo: schoolRecNo,
                                    academicYear: '2025-26',
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      ],

                      // My Subjects - M011 (Student Panel)
                      if (userProvider.hasMenuAccess('M011')) ...[
                        _CollapsibleMenuItem(
                          icon: Iconsax.book_1,
                          text: 'My Subjects',
                          isActive: activeScreen == AppScreen.mySubjects,
                          isCollapsed: isCollapsed,
                          onTap: () {
                            if (activeScreen != AppScreen.mySubjects) {
                              Navigator.pushReplacement(
                                context,
                                SmoothPageRoute(
                                    page: const MySubjectsScreen()),
                              );
                            }
                          },
                        ),
                      ],

                      if (userProvider.hasMenuAccess('M013')) ...[
                        _CollapsibleMenuItem(
                          icon: Iconsax.chart_21,
                          text: 'My Analytics',
                          isActive: activeScreen == AppScreen.analytics,
                          isCollapsed: isCollapsed,
                          onTap: () {
                            if (activeScreen != AppScreen.analytics) {
                              Navigator.pushReplacement(
                                context,
                                SmoothPageRoute(
                                    page:
                                    const StudentAnalyticsDashboard()),
                              );
                            }
                          },
                        ),
                      ],

                      // My Favourites - M014
                      if (userProvider.hasMenuAccess('M014')) ...[
                        _CollapsibleMenuItem(
                          icon: Iconsax.heart,
                          text: 'My Favourites',
                          isActive: activeScreen == AppScreen.myFavourites,
                          isCollapsed: isCollapsed,
                          onTap: () {
                            if (activeScreen != AppScreen.myFavourites) {
                              Navigator.pushReplacement(
                                context,
                                SmoothPageRoute(
                                    page: const MyFavouritesScreen()),
                              );
                            }
                          },
                        ),
                      ],

                      // ✅ NEW: Teacher Panel - M015 (Teacher Dashboard)
                      if (userProvider.hasMenuAccess('M015')) ...[
                        _CollapsibleMenuItem(
                          icon: Iconsax.teacher,
                          text: 'Teacher Dashboard',
                          isActive: activeScreen == AppScreen.teacherDashboard,
                          isCollapsed: isCollapsed,
                          onTap: () {
                            if (activeScreen != AppScreen.teacherDashboard) {
                              Navigator.pushReplacement(
                                context,
                                SmoothPageRoute(
                                  page: const TeacherDashboard(),
                                ),
                              );
                            }
                          },
                        ),
                      ],

                      // ✅ NEW: My Classes - M016
                      if (userProvider.hasMenuAccess('M016')) ...[
                        _CollapsibleMenuItem(
                          icon: Iconsax.book_square,
                          text: 'My Classes',
                          isActive: activeScreen == AppScreen.teacherClasses,
                          isCollapsed: isCollapsed,
                          onTap: () {
                            if (activeScreen != AppScreen.teacherClasses) {
                              Navigator.pushReplacement(
                                context,
                                SmoothPageRoute(
                                  page: const TeacherClassesScreen(),
                                ),
                              );
                            }
                          },
                        ),
                      ],

                      // Address Master - M017
                      if (userProvider.hasMenuAccess('M017')) ...[
                        _CollapsibleMenuItem(
                          icon: Iconsax.location,
                          text: 'Address Master',
                          isActive: activeScreen == AppScreen.addressMaster,
                          isCollapsed: isCollapsed,
                          onTap: () {
                            if (activeScreen != AppScreen.addressMaster) {
                              Navigator.pushReplacement(
                                context,
                                SmoothPageRoute(
                                    page: const AddressMasterScreen()),
                              );
                            }
                          },
                        ),
                      ],

                      // ✅ UPDATED: Parent Module - M000 (Select Child)
                      if (userProvider.hasMenuAccess('M000')) ...{
                        _CollapsibleMenuItem(
                          icon: Iconsax.profile_2user,
                          text: 'My Children',
                          isActive: activeScreen == AppScreen.parentChildren,
                          isCollapsed: isCollapsed,
                          onTap: () {
                            if (activeScreen != AppScreen.parentChildren) {
                              Navigator.pushReplacement(
                                context,
                                SmoothPageRoute(
                                  page: const SelectChildScreen(),
                                ),
                              );
                            }
                          },
                        ),
                      },

                      const Spacer(),

                      // Bottom section
                      if (!isCollapsed) ...[
                        const Divider(color: AppTheme.borderGrey),
                        const SizedBox(height: 8),
                      ],

                      // Settings - M006
                      if (userProvider.hasMenuAccess('M006')) ...[
                        _CollapsibleMenuItem(
                          icon: Iconsax.setting_2,
                          text: 'Settings',
                          isActive: activeScreen == AppScreen.settings,
                          isCollapsed: isCollapsed,
                          onTap: () {
                            // TODO: Add navigation to SettingsScreen
                          },
                        ),
                      ],

                      // ✅ UPDATED: Logout
                      _CollapsibleMenuItem(
                        icon: Iconsax.logout,
                        text: 'Logout',
                        isCollapsed: isCollapsed,
                        textColor: Colors.red.shade400,
                        iconColor: Colors.red.shade400,
                        onTap: () {
                          // Navigate to logout transition screen
                          Navigator.pushAndRemoveUntil(
                            context,
                            SmoothPageRoute(
                              page: const LogoutTransitionScreen(),
                            ),
                                (route) => false,
                          );
                        },
                      ),

                      SizedBox(height: isCollapsed ? 16 : 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ==================== COLLAPSIBLE MENU ITEM ====================
// (This widget is unchanged)
class _CollapsibleMenuItem extends StatefulWidget {
  final IconData icon;
  final String text;
  final bool isActive;
  final bool isCollapsed;
  final VoidCallback? onTap;
  final Color? textColor;
  final Color? iconColor;

  const _CollapsibleMenuItem({
    required this.icon,
    required this.text,
    this.isActive = false,
    required this.isCollapsed,
    this.onTap,
    this.textColor,
    this.iconColor,
  });

  @override
  _CollapsibleMenuItemState createState() => _CollapsibleMenuItemState();
}

class _CollapsibleMenuItemState extends State<_CollapsibleMenuItem>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveTextColor = widget.textColor ??
        (widget.isActive ? AppTheme.primaryGreen : AppTheme.bodyText);
    final effectiveIconColor = widget.iconColor ??
        (widget.isActive ? AppTheme.primaryGreen : AppTheme.bodyText);

    Widget menuItem = MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => _animationController.forward(),
        onTapUp: (_) => _animationController.reverse(),
        onTapCancel: () => _animationController.reverse(),
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(vertical: 2),
                padding: EdgeInsets.all(widget.isCollapsed ? 12 : 16),
                decoration: BoxDecoration(
                  color: widget.isActive
                      ? AppTheme.primaryGreen.withOpacity(0.1)
                      : (_isHovered
                      ? AppTheme.borderGrey.withOpacity(0.2)
                      : Colors.transparent),
                  borderRadius:
                  BorderRadius.circular(widget.isCollapsed ? 12 : 16),
                  border: widget.isActive
                      ? Border.all(
                      color: AppTheme.primaryGreen.withOpacity(0.2))
                      : null,
                ),
                child: widget.isCollapsed
                    ? Center(
                  child: Icon(
                    widget.icon,
                    color: effectiveIconColor,
                    size: 20,
                  ),
                )
                    : Row(
                  children: [
                    Icon(
                      widget.icon,
                      color: effectiveIconColor,
                      size: 20,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        widget.text,
                        style: AppTheme.bodyText1.copyWith(
                          color: effectiveTextColor,
                          fontWeight: widget.isActive
                              ? FontWeight.w600
                              : FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );

    if (widget.isCollapsed) {
      return Tooltip(
        message: widget.text,
        preferBelow: false,
        verticalOffset: 0,
        decoration: BoxDecoration(
          color: Colors.grey.shade800,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: AppTheme.bodyText1.copyWith(
          color: Colors.white,
          fontSize: 12,
        ),
        child: menuItem,
      );
    }

    return menuItem;
  }
}

// ==================== SIDEBAR TOGGLE BUTTON ====================
// (This widget is unchanged)
class _SidebarToggleButton extends StatelessWidget {
  final bool isCollapsed;

  const _SidebarToggleButton({required this.isCollapsed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => isSidebarCollapsed.value = !isSidebarCollapsed.value,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          vertical: 12,
          horizontal: isCollapsed ? 0 : 16,
        ),
        decoration: BoxDecoration(
          color: AppTheme.borderGrey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderGrey.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisAlignment: isCollapsed
              ? MainAxisAlignment.center
              : MainAxisAlignment.spaceBetween,
          children: [
            if (!isCollapsed) ...[
              Text(
                'Collapse',
                style: AppTheme.bodyText1.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.bodyText.withOpacity(0.7),
                ),
              ),
            ],
            AnimatedRotation(
              duration: const Duration(milliseconds: 300),
              turns: isCollapsed ? 0 : 0.5,
              child: Icon(
                Iconsax.arrow_right_3,
                color: AppTheme.bodyText.withOpacity(0.7),
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== SMOOTH PAGE ROUTE ====================
// (This widget is unchanged)
class SmoothPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  SmoothPageRoute({required this.page})
      : super(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionDuration: const Duration(milliseconds: 400),
    reverseTransitionDuration: const Duration(milliseconds: 400),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeInOutCubic,
      );

      return FadeTransition(
        opacity: curvedAnimation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.05, 0),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: child,
        ),
      );
    },
  );
}

// ==================== MOBILE DRAWER ====================
// (This widget is unchanged)
class _MobileDrawer extends StatelessWidget {
  final AppScreen activeScreen;

  const _MobileDrawer({
    required this.activeScreen,
  });

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.pop(context); // Close the drawer
    Future.delayed(const Duration(milliseconds: 250), () {
      Navigator.pushReplacement(
        context,
        SmoothPageRoute(page: screen), // Use smooth transition
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          final int schoolRecNo =
              int.tryParse(userProvider.userCode ?? '0') ?? 0;

          return Column(
            children: [
              // HEADER
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.12),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              const Icon(
                                Iconsax.book,
                                color: AppTheme.primaryGreen,
                                size: 26,
                              ),
                              Positioned(
                                right: 10,
                                top: 10,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: AppTheme.mackColor,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                        AppTheme.mackColor.withOpacity(0.5),
                                        blurRadius: 4,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => Navigator.pop(context),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                child: const Icon(
                                  Iconsax.close_circle,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'MACK',
                            style: AppTheme.logoStyle.copyWith(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              height: 1.1,
                              letterSpacing: -0.5,
                            ),
                          ),
                          TextSpan(
                            text: 'CLEO',
                            style: AppTheme.logoStyle.copyWith(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.mackColor,
                              height: 1.1,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Iconsax.book_1,
                                size: 12,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'LMS',
                                style: AppTheme.bodyText1.copyWith(
                                  fontSize: 11,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.4),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            'Learning Management',
                            style: AppTheme.bodyText1.copyWith(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.85),
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // MENU LIST
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  children: [
                    if (userProvider.hasMenuAccess('M001'))
                      _SimpleMenuItem(
                        icon: Iconsax.home,
                        title: 'Dashboard',
                        isActive: activeScreen == AppScreen.dashboard,
                        onTap: () => _navigateTo(context, const HomeScreen()),
                      ),

                    if (userProvider.hasMenuAccess('M002'))
                      _SimpleMenuItem(
                        icon: Iconsax.building_4,
                        title: 'Schools',
                        isActive: activeScreen == AppScreen.schools,
                        onTap: () =>
                            _navigateTo(context, const SchoolsScreen()),
                      ),

                    if (userProvider.hasMenuAccess('M007'))
                      _SimpleMenuItem(
                        icon: Iconsax.profile_2user,
                        title: 'Students',
                        isActive: activeScreen == AppScreen.students,
                        onTap: () =>
                            _navigateTo(context, const StudentsScreen()),
                      ),

                    if (userProvider.hasMenuAccess('M008'))
                      _SimpleMenuItem(
                        icon: Iconsax.teacher,
                        title: 'Teachers',
                        isActive: activeScreen == AppScreen.teachers,
                        onTap: () =>
                            _navigateTo(context, const TeachersScreen()),
                      ),

                    if (userProvider.hasMenuAccess('M003'))
                      _SimpleMenuItem(
                        icon: Iconsax.receipt_text,
                        title: 'Subscriptions',
                        isActive: activeScreen == AppScreen.subscriptions,
                        onTap: () =>
                            _navigateTo(context, const SubscriptionsScreen()),
                      ),

                    if (userProvider.hasMenuAccess('M004'))
                      _SimpleMenuItem(
                        icon: Iconsax.book_1,
                        title: 'Academics',
                        isActive: activeScreen == AppScreen.academics,
                        onTap: () =>
                            _navigateTo(context, const AcademicsScreen()),
                      ),

                    if (userProvider.hasMenuAccess('M005'))
                      _SimpleMenuItem(
                        icon: Iconsax.user_square,
                        title: 'Publishers',
                        isActive: activeScreen == AppScreen.publishers,
                        onTap: () =>
                            _navigateTo(context, const PublisherScreen()),
                      ),

                    if (userProvider.hasMenuAccess('M009'))
                      _SimpleMenuItem(
                        icon: Iconsax.monitor,
                        title: 'School Panel',
                        isActive: activeScreen == AppScreen.schoolPanel,
                        onTap: () =>
                            _navigateTo(context, const SchoolPanelDashboard()),
                      ),

                    if (userProvider.hasMenuAccess('M012'))
                      _SimpleMenuItem(
                        icon: Iconsax.building,
                        title: 'Class',
                        isActive: activeScreen == AppScreen.classModule,
                        onTap: () => _navigateTo(
                          context,
                          ClassManageScreen(
                            schoolRecNo: schoolRecNo,
                          ),
                        ),
                      ),

                    if (userProvider.hasMenuAccess('M010'))
                      _SimpleMenuItem(
                        icon: Iconsax.book_square,
                        title: 'Subject Module',
                        isActive: activeScreen == AppScreen.subjectModule,
                        onTap: () => _navigateTo(
                          context,
                          SubjectModuleScreen(
                            schoolRecNo: schoolRecNo,
                            academicYear: '2025-26',
                          ),
                        ),
                      ),

                    if (userProvider.hasMenuAccess('M011'))
                      _SimpleMenuItem(
                        icon: Iconsax.book_1,
                        title: 'My Subjects',
                        isActive: activeScreen == AppScreen.mySubjects,
                        onTap: () =>
                            _navigateTo(context, const MySubjectsScreen()),
                      ),

                    if (userProvider.hasMenuAccess('M013'))
                      _SimpleMenuItem(
                        icon: Iconsax.chart_21,
                        title: 'My Analytics',
                        isActive: activeScreen == AppScreen.analytics,
                        onTap: () => _navigateTo(
                            context, const StudentAnalyticsDashboard()),
                      ),

                    if (userProvider.hasMenuAccess('M014'))
                      _SimpleMenuItem(
                        icon: Iconsax.heart,
                        title: 'My Favourites',
                        isActive: activeScreen == AppScreen.myFavourites,
                        onTap: () =>
                            _navigateTo(context, const MyFavouritesScreen()),
                      ),

                    if (userProvider.hasMenuAccess('M015'))
                      _SimpleMenuItem(
                        icon: Iconsax.teacher,
                        title: 'Teacher Dashboard',
                        isActive: activeScreen == AppScreen.teacherDashboard,
                        onTap: () =>
                            _navigateTo(context, const TeacherDashboard()),
                      ),

                    if (userProvider.hasMenuAccess('M016'))
                      _SimpleMenuItem(
                        icon: Iconsax.book_square,
                        title: 'My Classes',
                        isActive: activeScreen == AppScreen.teacherClasses,
                        onTap: () =>
                            _navigateTo(context, const TeacherClassesScreen()),
                      ),

                    if (userProvider.hasMenuAccess('M017'))
                      _SimpleMenuItem(
                        icon: Iconsax.location,
                        title: 'Address Master',
                        isActive: activeScreen == AppScreen.addressMaster,
                        onTap: () =>
                            _navigateTo(context, const AddressMasterScreen()),
                      ),

                    if (userProvider.hasMenuAccess('M000'))
                      _SimpleMenuItem(
                        icon: Iconsax.profile_2user,
                        title: 'My Children',
                        isActive: activeScreen == AppScreen.parentChildren,
                        onTap: () =>
                            _navigateTo(context, const SelectChildScreen()),
                      ),

                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 8),
                      child: Divider(
                        color: Colors.grey.shade300,
                        thickness: 1,
                      ),
                    ),

                    if (userProvider.hasMenuAccess('M006'))
                      _SimpleMenuItem(
                        icon: Iconsax.setting_2,
                        title: 'Settings',
                        isActive: activeScreen == AppScreen.settings,
                        onTap: () {
                          // TODO: Add navigation to SettingsScreen
                        },
                      ),

                    // LOGOUT
                    _SimpleMenuItem(
                      icon: Iconsax.logout,
                      title: 'Logout',
                      textColor: Colors.red,
                      onTap: () {
                        Navigator.pop(context); // Close drawer first
                        Future.delayed(const Duration(milliseconds: 250), () {
                          Navigator.pushAndRemoveUntil(
                            context,
                            SmoothPageRoute(
                              page: const LogoutTransitionScreen(),
                            ),
                                (route) => false,
                          );
                        });
                      },
                    ),
                  ],
                ),
              ),

              // FOOTER
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: Colors.grey.shade200,
                      width: 1,
                    ),
                  ),
                  color: Colors.grey.shade50,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryGreen.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          (userProvider.userName ?? 'U')[0].toUpperCase(),
                          style: AppTheme.headline2.copyWith(fontSize: 18),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            userProvider.userName ?? 'Admin',
                            style: AppTheme.labelText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: AppTheme.accentGreen,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'v1.0.0',
                                style: AppTheme.bodyText1.copyWith(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ==================== SIMPLE MENU ITEM ====================
// (This widget is unchanged)
class _SimpleMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isActive;
  final VoidCallback? onTap;
  final Color? textColor;

  const _SimpleMenuItem({
    required this.icon,
    required this.title,
    this.isActive = false,
    this.onTap,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          decoration: BoxDecoration(
            color: isActive ? AppTheme.primaryGreen.withOpacity(0.08) : null,
            border: isActive
                ? Border(
              left: BorderSide(
                color: AppTheme.primaryGreen,
                width: 4,
              ),
            )
                : null,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 22,
                color: textColor ??
                    (isActive ? AppTheme.primaryGreen : Colors.grey.shade600),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: AppTheme.bodyText1.copyWith(
                    fontSize: 15,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                    color: textColor ??
                        (isActive
                            ? AppTheme.primaryGreen
                            : Colors.grey.shade800),
                  ),
                ),
              ),
              if (isActive)
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryGreen,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== SECTION HEADER ====================
// (This widget is unchanged)
class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 4),
      child: Text(
        title,
        style: AppTheme.bodyText1.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppTheme.bodyText.withOpacity(0.5),
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

// ==================== MODERN MENU ITEM ====================
// (This widget is unchanged)
class _ModernMenuItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final String? subtitle;
  final bool isActive;
  final VoidCallback? onTap;
  final Color? textColor;
  final Gradient? gradient;

  const _ModernMenuItem({
    required this.icon,
    required this.text,
    this.subtitle,
    this.isActive = false,
    this.onTap,
    this.textColor,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isActive
                  ? AppTheme.primaryGreen.withOpacity(0.1)
                  : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: isActive
                  ? Border.all(color: AppTheme.primaryGreen, width: 2)
                  : Border.all(color: AppTheme.borderGrey.withOpacity(0.2)),
              boxShadow: isActive
                  ? [
                BoxShadow(
                  color: AppTheme.primaryGreen.withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: gradient ??
                        const LinearGradient(
                          colors: [AppTheme.primaryGreen, AppTheme.accentGreen],
                        ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: (gradient?.colors.first ?? AppTheme.primaryGreen)
                            .withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        text,
                        style: AppTheme.bodyText1.copyWith(
                          color: textColor ??
                              (isActive
                                  ? AppTheme.primaryGreen
                                  : AppTheme.darkText),
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: AppTheme.bodyText1.copyWith(
                            fontSize: 11,
                            color: AppTheme.bodyText.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (isActive)
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Iconsax.tick_circle,
                      color: Colors.white,
                      size: 14,
                    ),
                  )
                else
                  Icon(
                    Iconsax.arrow_right_3,
                    size: 16,
                    color: AppTheme.bodyText.withOpacity(0.3),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}