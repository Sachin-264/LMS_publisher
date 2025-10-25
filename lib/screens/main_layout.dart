// main_layout.dart
import 'package:flutter/material.dart'; // Import flutter/material.dart for SystemMouseCursors
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:lms_publisher/AdminScreen/AdminPublish/publisher_screen.dart';
import 'package:lms_publisher/Provider/UserProvider.dart';
import 'package:lms_publisher/School_Panel/School_panel_dashboard.dart';
import 'package:lms_publisher/School_Panel/student_module/student_manage.dart';
import 'package:lms_publisher/School_Panel/teacher_module/teacher_manage.dart';
import 'package:lms_publisher/School_Panel/subject_module/subject_module_screen.dart';
import 'package:lms_publisher/StudentPannel/MySubject/my_subject_screen.dart';
import 'package:lms_publisher/Theme/apptheme.dart';
import 'package:lms_publisher/screens/AcademicsScreen/academics_screen.dart';
import 'package:lms_publisher/screens/HomePage/HomePage.dart';
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
  // ✅ NEW ENTRY: M012 Class Module
  classModule,
  settings
}

// ✅ State management for sidebar
final ValueNotifier<bool> isSidebarCollapsed = ValueNotifier(true);
final ValueNotifier<bool> isMobileMenuOpen = ValueNotifier(false);

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
          _scrollController.position.pixels % 100 < 1) {
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isMobile = screenWidth < 600;
    final padding = MediaQuery.of(context).padding;
    print('🔔 Top Notch: ${padding.top}, 📱 Screen: $screenWidth x $screenHeight');

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      drawer: isMobile ? _MobileDrawer(activeScreen: widget.activeScreen) : null,
      body: SafeArea(
        top: true,
        bottom: true,
        left: true,
        right: true,
        child: ValueListenableBuilder<bool>(
          valueListenable: isSidebarCollapsed,
          builder: (context, isCollapsed, _) {
            final double mainContentLeft = isMobile ? 0 : (isCollapsed ? 80 : 280);

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
                            _Header(isMobile: isMobile),
                            SizedBox(
                                height:
                                isMobile ? 12 : AppTheme.defaultPadding * 1.5),

                            // ✅ FIXED: Proper scrolling with debugging
                            Expanded(
                              child: LayoutBuilder(
                                builder: (context, constraints) {


                                  return NotificationListener<ScrollNotification>(
                                    onNotification:
                                        (ScrollNotification notification) {
                                      if (notification is ScrollStartNotification) {

                                      } else if (notification
                                      is ScrollEndNotification) {
                                        final percent = (_scrollController
                                            .position.pixels /
                                            _scrollController
                                                .position.maxScrollExtent *
                                            100)
                                            .toStringAsFixed(0);
                                      } else if (notification
                                      is OverscrollNotification) {
                                      }
                                      return false;
                                    },
                                    child: SingleChildScrollView(
                                      controller: _scrollController,
                                      physics: const ClampingScrollPhysics(),
                                      child: Builder(
                                        builder: (context) {
                                          // ✅ Measure child height after build
                                          WidgetsBinding.instance
                                              .addPostFrameCallback((_) {
                                            final RenderBox? box = context
                                                .findRenderObject() as RenderBox?;
                                            if (box != null && box.hasSize) {
                                              print(
                                                  '🎯 Child Content Height: ${box.size.height.toStringAsFixed(0)}');
                                              print(
                                                  '🎯 Child Content Width: ${box.size.width.toStringAsFixed(0)}');
                                            }
                                          });

                                          return Container(
                                            width: double.infinity,
                                            constraints: BoxConstraints(
                                              minHeight: constraints.maxHeight,
                                            ),
                                            child: widget.child,
                                          );
                                        },
                                      ),
                                    ),
                                  );
                                },
                              ),
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

// ✅ Mobile Menu Item Widget
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
        color: isActive ? AppTheme.primaryGreen.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border:
              isActive ? Border.all(color: AppTheme.primaryGreen.withOpacity(0.3)) : null,
            ),
            child: Row(
              children: [
                Icon(icon, color: effectiveIconColor, size: 22),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    text,
                    style: GoogleFonts.inter(
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

// ✅ UPDATED: Header with Hamburger Menu
class _Header extends StatelessWidget {
  final bool isMobile;
  const _Header({required this.isMobile});
  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        return LayoutBuilder(
          builder: (context, constraints) {
            bool isCompact = constraints.maxWidth < 650;
            String userName = userProvider.userName ?? 'Admin User';
            return Row(
              children: [
                // ✅ Hamburger Menu Button (Mobile Only)
                if (isMobile)
                  Container(
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Iconsax.menu_1, color: AppTheme.primaryGreen),
                      onPressed: () {
                        Scaffold.of(context).openDrawer();
                      },
                      tooltip: 'Menu',
                    ),
                  ),

                // Search Bar
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 2),
                        ),
                      ],
                      border: Border.all(color: AppTheme.borderGrey.withOpacity(0.1)),
                    ),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search...',
                        hintStyle: GoogleFonts.inter(
                          color: AppTheme.bodyText.withOpacity(0.5),
                          fontSize: 14,
                        ),
                        prefixIcon: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Icon(
                            Iconsax.search_normal_1,
                            size: 18,
                            color: AppTheme.bodyText.withOpacity(0.5),
                          ),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Notification Icon
                if (!isCompact)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        const Icon(
                          Iconsax.notification,
                          size: 20,
                          color: AppTheme.bodyText,
                        ),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(width: 12),

                // User Profile
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          image: const DecorationImage(
                            image: NetworkImage('https://picsum.photos/id/237/200/200'),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      if (!isCompact && !isMobile) ...[
                        const SizedBox(width: 12),
                        Text(
                          userName,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

// ==================== MODERN COLLAPSIBLE SIDEBAR ====================
class _ModernCollapsibleSidebar extends StatelessWidget {
  final bool isCollapsed;
  final AppScreen activeScreen;
  const _ModernCollapsibleSidebar({
    required this.isCollapsed,
    required this.activeScreen,
  });
  @override
  Widget build(BuildContext context) {
    // 🆕 ADDED: Consumer wrapper for UserProvider access
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        // Get schoolRecNo from UserProvider for passing to screens
        final int schoolRecNo = int.tryParse(userProvider.userCode ?? '0') ?? 0;

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
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
                        gradient: const LinearGradient(
                          colors: [
                            AppTheme.primaryGreen,
                            AppTheme.mackColor,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
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
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
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
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Toggle Button
              Padding(
                padding: EdgeInsets.symmetric(horizontal: isCollapsed ? 16 : 24),
                child: _SidebarToggleButton(isCollapsed: isCollapsed),
              ),
              const SizedBox(height: 16),

              // Navigation Menu
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: isCollapsed ? 8 : 16),
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
                                MaterialPageRoute(builder: (_) => const HomeScreen()),
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
                                MaterialPageRoute(builder: (_) => const SchoolsScreen()),
                              );
                            }
                          },
                        ),
                      ],

                      // Students Menu Item (New Module) - M007
                      // ✅ UPDATED: Wrapped with M007 access check
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
                                MaterialPageRoute(builder: (_) => const StudentsScreen()),
                              );
                            }
                          },
                        ),
                      ],

                      // Teachers Menu Item (New Module) - M008
                      // ✅ UPDATED: Wrapped with M008 access check
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
                                MaterialPageRoute(builder: (_) => const TeachersScreen()),
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
                                MaterialPageRoute(
                                    builder: (_) => const SubscriptionsScreen()),
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
                                MaterialPageRoute(
                                    builder: (_) => const AcademicsScreen()),
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
                                MaterialPageRoute(
                                    builder: (_) => const PublisherScreen()),
                              );
                            }
                          },
                        ),
                      ],

                      // School Panel - M009
                      // ✅ UPDATED: Wrapped with M009 access check
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
                                MaterialPageRoute(
                                    builder: (_) => const SchoolPanelDashboard()),
                              );
                            }
                          },
                        ),
                      ],

                      // ✅ NEW MODULE: Class Module - M012
                      if (userProvider.hasMenuAccess('M012')) ...[
                        _CollapsibleMenuItem(
                          icon: Iconsax.building, // Icon for Class/Structure
                          text: 'Class',
                          isActive: activeScreen == AppScreen.classModule,
                          isCollapsed: isCollapsed,
                          onTap: () {
                            if (activeScreen != AppScreen.classModule) {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ClassManageScreen( // <<< NEW SCREEN
                                    schoolRecNo: schoolRecNo, // Pass the schoolRecNo from UserProvider
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      ],

                      // Subject Module - M010
                      // ✅ UPDATED: Wrapped with M010 access check
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
                                MaterialPageRoute(
                                  builder: (_) => SubjectModuleScreen(
                                    schoolRecNo: schoolRecNo,
                                    academicYear: '2025-26', // Placeholder
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      ],
                      // My Subjects - M00 (Student Panel)
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
                                MaterialPageRoute(builder: (_) => const MySubjectsScreen()),
                              );
                            }
                          },
                        ),
                      ],


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
                        ),
                      ],

                      // 🆕 ADDED: Logout - Always visible for logged in users
                      _CollapsibleMenuItem(
                        icon: Iconsax.logout,
                        text: 'Logout',
                        isCollapsed: isCollapsed,
                        textColor: Colors.red.shade400,
                        iconColor: Colors.red.shade400,
                        onTap: () {
                          // Trigger logout through LoginBloc
                          context.read<LoginBloc>().add(LogoutRequested());
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
                      ? Border.all(color: AppTheme.primaryGreen.withOpacity(0.2))
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
                        style: GoogleFonts.inter(
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
        textStyle: GoogleFonts.inter(
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
                style: GoogleFonts.inter(
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

// ✅ ADD THIS: Smooth Page Transition Helper
class SmoothPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  SmoothPageRoute({required this.page})
      : super(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionDuration: const Duration(milliseconds: 400),
    reverseTransitionDuration: const Duration(milliseconds: 400),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      // ✅ Smooth fade + slide transition
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

// ✅ COMPLETELY REDESIGNED: Ultra-Modern Mobile Drawer
// ✅ CLEAN & PROFESSIONAL Mobile Drawer
class _MobileDrawer extends StatelessWidget {
  final AppScreen activeScreen;
  const _MobileDrawer({required this.activeScreen});
  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.pop(context);
    Future.delayed(const Duration(milliseconds: 250), () {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => screen,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 300),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          // Get schoolRecNo from UserProvider for passing to screens
          final int schoolRecNo = int.tryParse(userProvider.userCode ?? '0') ?? 0;

          return Column(
            children: [
              // ✅ IMPROVED HEADER with better close button
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
                    // ✅ Top Row - Logo Icon + Better Close Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Premium Logo Icon
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
                                        color: AppTheme.mackColor.withOpacity(0.5),
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

                        // ✅ IMPROVED Close Button with better design
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

                    // ✅ IMPROVED LOGO with Space Grotesk font
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'MACK',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              height: 1.1,
                              letterSpacing: -0.5,
                            ),
                          ),
                          TextSpan(
                            text: 'CLEO',
                            style: GoogleFonts.spaceGrotesk(
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

                    // ✅ IMPROVED Subtitle with LMS Badge
                    Row(
                      children: [
                        Container(
                          padding:
                          const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
                                style: GoogleFonts.inter(
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
                            style: GoogleFonts.inter(
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

              // ✅ Menu List (keep as is)
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
                        onTap: () => _navigateTo(context, const SchoolsScreen()),
                      ),

                    // Students - M007
                    // ✅ UPDATED: Wrapped with M007 access check
                    if (userProvider.hasMenuAccess('M007'))
                      _SimpleMenuItem(
                        icon: Iconsax.profile_2user,
                        title: 'Students',
                        isActive: activeScreen == AppScreen.students,
                        onTap: () => _navigateTo(context, const StudentsScreen()),
                      ),

                    // Teachers - M008
                    // ✅ UPDATED: Wrapped with M008 access check
                    if (userProvider.hasMenuAccess('M008'))
                      _SimpleMenuItem(
                        icon: Iconsax.teacher,
                        title: 'Teachers',
                        isActive: activeScreen == AppScreen.teachers,
                        onTap: () => _navigateTo(context, const TeachersScreen()),
                      ),

                    if (userProvider.hasMenuAccess('M003'))
                      _SimpleMenuItem(
                        icon: Iconsax.receipt_text,
                        title: 'Subscriptions',
                        isActive: activeScreen == AppScreen.subscriptions,
                        onTap: () => _navigateTo(context, const SubscriptionsScreen()),
                      ),

                    if (userProvider.hasMenuAccess('M004'))
                      _SimpleMenuItem(
                        icon: Iconsax.book_1,
                        title: 'Academics',
                        isActive: activeScreen == AppScreen.academics,
                        onTap: () => _navigateTo(context, const AcademicsScreen()),
                      ),

                    if (userProvider.hasMenuAccess('M005'))
                      _SimpleMenuItem(
                        icon: Iconsax.user_square,
                        title: 'Publishers',
                        isActive: activeScreen == AppScreen.publishers,
                        onTap: () => _navigateTo(context, const PublisherScreen()),
                      ),

                    // School Panel - M009
                    // ✅ UPDATED: Wrapped with M009 access check
                    if (userProvider.hasMenuAccess('M009'))
                      _SimpleMenuItem(
                        icon: Iconsax.monitor,
                        title: 'School Panel',
                        isActive: activeScreen == AppScreen.schoolPanel,
                        onTap: () => _navigateTo(context, const SchoolPanelDashboard()),
                      ),

                    // ✅ NEW MODULE: Class Module - M012
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

                    // Subject Module - M010
                    // ✅ UPDATED: Wrapped with M010 access check
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
                        onTap: () => _navigateTo(context, const MySubjectsScreen()),
                      ),



                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
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
                      ),

                    _SimpleMenuItem(
                      icon: Iconsax.logout,
                      title: 'Logout',
                      textColor: Colors.red,
                      onTap: () {
                        Navigator.pop(context);
                        context.read<LoginBloc>().add(LogoutRequested());
                      },
                    ),
                  ],
                ),
              ),

              // ✅ IMPROVED Footer with better styling
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
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                          ),
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
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: AppTheme.darkText,
                            ),
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
                                style: GoogleFonts.inter(
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

// ✅ Simple Clean Menu Item
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
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                    color: textColor ??
                        (isActive ? AppTheme.primaryGreen : Colors.grey.shade800),
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

// ✅ Section Header Widget
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});
  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 4),
        child: Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppTheme.bodyText.withOpacity(0.5),
            letterSpacing: 1.2,
          ),
        ));
  }
}

// ✅ Modern Menu Item with gradient and subtitle
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
              color: isActive ? AppTheme.primaryGreen.withOpacity(0.1) : Colors.white,
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
                // Icon with gradient background
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

                // Text content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        text,
                        style: GoogleFonts.inter(
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
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppTheme.bodyText.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Active indicator or arrow
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