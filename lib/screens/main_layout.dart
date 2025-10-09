import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:lms_publisher/Theme/apptheme.dart';
import 'package:lms_publisher/screens/AcademicsScreen/academics_screen.dart';
import 'package:lms_publisher/screens/HomePage/HomePage.dart';
import 'package:lms_publisher/screens/School/School_manage.dart';
import 'package:lms_publisher/screens/SubscriptionScreen/subscription_dart.dart';

// Enum to identify the active screen for the sidebar
// Removed 'analytics' and 'users' as requested.
enum AppScreen { dashboard, schools, subscriptions, academics, settings }

// State management for the sidebar
final ValueNotifier<bool> isSidebarCollapsed = ValueNotifier(true);

class MainLayout extends StatelessWidget {
  final Widget child;
  final AppScreen activeScreen;

  const MainLayout({
    super.key,
    required this.child,
    required this.activeScreen,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: ValueListenableBuilder<bool>(
        valueListenable: isSidebarCollapsed,
        builder: (context, isCollapsed, _) {
          // Determine the left margin for the main content based on sidebar state
          // and screen width for better responsiveness.
          final double mainContentLeft =
          MediaQuery.of(context).size.width < 1200 && !isCollapsed
              ? 0 // When sidebar is expanded on small screens, content shouldn't move
              : (isCollapsed ? 80 : 280);

          return Stack(
            children: [
              // Main Content Area with proper margin
              AnimatedPositioned(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOutCubic,
                left: mainContentLeft,
                top: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  color: const Color(0xFFF0F2F5),
                  child: SingleChildScrollView(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1400),
                        child: Padding(
                          padding: const EdgeInsets.all(
                              AppTheme.defaultPadding * 1.5),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const _Header(),
                              const SizedBox(
                                  height: AppTheme.defaultPadding * 1.5),
                              child,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Backdrop/Scrim - Only visible when sidebar is expanded on smaller screens
              if (!isCollapsed && MediaQuery.of(context).size.width < 1200) ...[
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () => isSidebarCollapsed.value = true,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      color: Colors.black.withOpacity(0.4),
                    ),
                  ),
                ),
              ],

              // Modern Collapsible Sidebar
              AnimatedPositioned(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOutCubic,
                left: 0,
                top: 0,
                bottom: 0,
                width: isCollapsed ? 80 : 280,
                child: _ModernCollapsibleSidebar(
                  isCollapsed: isCollapsed,
                  activeScreen: activeScreen,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// =================================================================== //
//                   MODERN COLLAPSIBLE SIDEBAR                        //
// =================================================================== //
class _ModernCollapsibleSidebar extends StatelessWidget {
  final bool isCollapsed;
  final AppScreen activeScreen;

  const _ModernCollapsibleSidebar({
    required this.isCollapsed,
    required this.activeScreen,
  });

  @override
  Widget build(BuildContext context) {
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
        // The border radius should only apply when collapsed,
        // otherwise it looks strange when flush with the edge.
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
              mainAxisAlignment: MainAxisAlignment.center, // Center logo when collapsed
              children: [
                // Logo/Icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primaryGreen, AppTheme.mackColor],
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

                // Brand Text - Only visible when expanded
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
                  _CollapsibleMenuItem(
                    icon: Iconsax.home,
                    text: 'Dashboard',
                    isActive: activeScreen == AppScreen.dashboard,
                    isCollapsed: isCollapsed,
                    onTap: () {
                      if (activeScreen != AppScreen.dashboard) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const HomeScreen()),
                        );
                      }
                    },
                  ),
                  _CollapsibleMenuItem(
                    icon: Iconsax.building_4,
                    text: 'Schools',
                    isActive: activeScreen == AppScreen.schools,
                    isCollapsed: isCollapsed,
                    onTap: () {
                      if (activeScreen != AppScreen.schools) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const SchoolsScreen()),
                        );
                      }
                    },
                  ),
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
                  // REMOVED 'Analytics' and 'Users' menu items as requested.
                  // _CollapsibleMenuItem(
                  //   icon: Iconsax.chart_21,
                  //   text: 'Analytics',
                  //   isActive: activeScreen == AppScreen.analytics,
                  //   isCollapsed: isCollapsed,
                  // ),
                  // _CollapsibleMenuItem(
                  //   icon: Iconsax.user,
                  //   text: 'Users',
                  //   isActive: activeScreen == AppScreen.users,
                  //   isCollapsed: isCollapsed,
                  // ),

                  const Spacer(),

                  // Bottom section with divider
                  if (!isCollapsed) ...[
                    const Divider(color: AppTheme.borderGrey),
                    const SizedBox(height: 8),
                  ],

                  _CollapsibleMenuItem(
                    icon: Iconsax.setting_2,
                    text: 'Settings',
                    isActive: activeScreen == AppScreen.settings,
                    isCollapsed: isCollapsed,
                  ),
                  _CollapsibleMenuItem(
                    icon: Iconsax.logout,
                    text: 'Logout',
                    isCollapsed: isCollapsed,
                    textColor: Colors.red.shade400,
                    iconColor: Colors.red.shade400,
                  ),

                  SizedBox(height: isCollapsed ? 16 : 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =================================================================== //
//                    COLLAPSIBLE MENU ITEM                            //
// =================================================================== //
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
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
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
                    color: AppTheme.primaryGreen.withOpacity(0.2),
                  )
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

    // Add tooltip for collapsed state
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

// =================================================================== //
//                      SIDEBAR TOGGLE BUTTON                          //
// =================================================================== //
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
          border: Border.all(
            color: AppTheme.borderGrey.withOpacity(0.2),
          ),
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

// =================================================================== //
//                         ENHANCED HEADER                             //
// =================================================================== //
class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    // Use LayoutBuilder to create a responsive header
    return LayoutBuilder(
      builder: (context, constraints) {
        // A simple breakpoint for switching to a more compact view.
        bool isCompact = constraints.maxWidth < 650;

        return Row(
          children: [
            // Enhanced Search Bar
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
                  border: Border.all(
                    color: AppTheme.borderGrey.withOpacity(0.1),
                  ),
                ),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search anything...',
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

            const SizedBox(width: 16),

            // Notification Button
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

            const SizedBox(width: 16),

            // User Profile Section
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
                        image: NetworkImage(
                            'https://picsum.photos/id/237/200/200'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  // Conditionally show user info based on screen size
                  if (!isCompact) ...[
                    const SizedBox(width: 12),
                    Text(
                      'Admin User',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    // REMOVED EMAIL to make profile section more compact
                    const SizedBox(width: 8),
                  ]
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}