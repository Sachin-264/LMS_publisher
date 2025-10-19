// lib/widgets/custom_snackbar.dart

import 'dart:math';
import 'package:flutter/material.dart';
import '../Theme/apptheme.dart';

class CustomSnackbar {
  /// Shows a beautifully styled success snackbar.
  static void showSuccess(BuildContext context, String message,
      {String title = 'Success'}) {
    _show(
      context,
      title: title,
      message: message,
      icon: Icons.check_circle_rounded,
      gradient: AppTheme.primaryGradient,
    );
  }

  /// Shows a beautifully styled informational snackbar.
  static void showInfo(BuildContext context, String message,
      {String title = 'Information'}) {
    _show(
      context,
      title: title,
      message: message,
      icon: Icons.info_rounded,
      gradient: const LinearGradient(
        colors: [Color(0xFF007BFF), Color(0xFF0056b3)], // Blue gradient
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    );
  }

  /// Shows a beautifully styled warning snackbar.
  static void showWarning(BuildContext context, String message,
      {String title = 'Warning'}) {
    _show(
      context,
      title: title,
      message: message,
      icon: Icons.warning_rounded,
      gradient: const LinearGradient(
        colors: [Color(0xFFFF9800), Color(0xFFF57C00)], // Orange gradient
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    );
  }

  /// Shows a beautifully styled error snackbar.
  static void showError(BuildContext context, String message,
      {String title = 'Error'}) {
    _show(
      context,
      title: title,
      message: message,
      icon: Icons.error_rounded,
      gradient: const LinearGradient(
        colors: [Color(0xFFD32F2F), Color(0xFFB71C1C)], // Red gradient
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    );
  }

  /// The private method that builds and displays the snackbar.
  static void _show(
      BuildContext context, {
        required String title,
        required String message,
        required IconData icon,
        required Gradient gradient,
      }) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.hideCurrentSnackBar();

    // Get the animation from the SnackBar controller
    final animation = scaffoldMessenger.showSnackBar(
      SnackBar(
        // The snackbar itself is transparent, we animate our custom content
        backgroundColor: Colors.transparent,
        elevation: 0,
        // Make it float with a consistent margin
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        duration: const Duration(seconds: 4), // Longer duration for readability
        // The custom content with its own animations
        content: _SnackbarContent(
          title: title,
          message: message,
          icon: icon,
          gradient: gradient,
          // We get the animation from the snackbar itself
          animation: ModalRoute.of(context)!.animation!,
        ),
      ),
    );
  }
}

/// The internal widget that holds the snackbar's content and animations.
class _SnackbarContent extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final Gradient gradient;
  final Animation<double> animation;

  const _SnackbarContent({
    required this.title,
    required this.message,
    required this.icon,
    required this.gradient,
    required this.animation,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Entrance animation for the content
    final slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));

    final fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));

    final scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutBack));

    return FadeTransition(
      opacity: fadeAnimation,
      child: SlideTransition(
        position: slideAnimation,
        child: ScaleTransition(
          scale: scaleAnimation,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // --- DECORATIVE BACKGROUND ELEMENTS ---
              Positioned(
                top: -15,
                left: -15,
                child: Transform.rotate(
                  angle: -pi / 6,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
              ),

              // Animated dots decoration
              Positioned(
                bottom: 10,
                right: 10,
                child: Row(
                  children: List.generate(
                    3,
                        (index) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),

              // --- MAIN CONTENT CONTAINER ---
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon with a subtle background plaque and pulse effect
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(icon, color: Colors.white, size: 32),
                    ),
                    const SizedBox(width: 16),

                    // Title and message
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            style: AppTheme.buttonText.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            message,
                            style: AppTheme.bodyText1.copyWith(
                              color: Colors.white.withOpacity(0.95),
                              height: 1.5,
                              fontSize: 14,
                            ),
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 8),

                    // --- CLOSE BUTTON with hover effect ---
                    _CloseButton(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom close button with hover effect
class _CloseButton extends StatefulWidget {
  @override
  State<_CloseButton> createState() => _CloseButtonState();
}

class _CloseButtonState extends State<_CloseButton> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: _isHovering
              ? Colors.white.withOpacity(0.3)
              : Colors.white.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          padding: EdgeInsets.zero,
          iconSize: 18,
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }
}
