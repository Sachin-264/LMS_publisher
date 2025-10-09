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

    return FadeTransition(
      opacity: fadeAnimation,
      child: SlideTransition(
        position: slideAnimation,
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

            // --- MAIN CONTENT CONTAINER ---
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon with a subtle background plaque
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
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
                          style: AppTheme.buttonText.copyWith(fontSize: 18),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          message,
                          style: AppTheme.bodyText1.copyWith(
                            color: Colors.white.withOpacity(0.9),
                            height: 1.4,
                          ),
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // --- CLOSE BUTTON ---
                  SizedBox(
                    width: 30,
                    height: 30,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.close, color: Colors.white, size: 20),
                      onPressed: () {
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}