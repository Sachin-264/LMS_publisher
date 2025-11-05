import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:lms_publisher/Theme/apptheme.dart';
import 'package:lms_publisher/screens/LoginScreen/responsive_login_screen.dart';


class LogoutTransitionScreen extends StatefulWidget {
  const LogoutTransitionScreen({super.key});

  @override
  State<LogoutTransitionScreen> createState() => _LogoutTransitionScreenState();
}

class _LogoutTransitionScreenState extends State<LogoutTransitionScreen>
    with SingleTickerProviderStateMixin {
  bool showAction = false;
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeIn,
      ),
    );

    _controller.forward();

    // Show button after 2 seconds
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) setState(() => showAction = true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void goToLogin() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const ResponsiveLoginScreen()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Simple logout image
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.borderGrey.withOpacity(0.3),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/logout.png',
                        height: 140,
                        width: 140,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 140,
                            width: 140,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryGreen.withOpacity(0.1),
                            ),
                            child: Icon(
                              Iconsax.logout,
                              size: 70,
                              color: AppTheme.primaryGreen,
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // MACK CLEO branding
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _StyledText(
                        text: 'MACK',
                        color: AppTheme.mackColor,
                        borderColor: AppTheme.mackBorder,
                        shadowColor: AppTheme.mackColor.withOpacity(0.3),
                      ),
                      const SizedBox(width: 12),
                      _StyledText(
                        text: 'CLEO',
                        color: AppTheme.cleoColor,
                        borderColor: AppTheme.cleoBorder,
                        shadowColor: AppTheme.cleoColor.withOpacity(0.3),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Simple text
                  Text(
                    'See You Soon!',
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.darkText,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    'You have been successfully logged out',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppTheme.bodyText,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 40),

                  // Simple progress indicator
                  if (!showAction)
                    SizedBox(
                      height: 4,
                      width: 200,
                      child: LinearProgressIndicator(
                        backgroundColor: AppTheme.borderGrey.withOpacity(0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppTheme.primaryGreen,
                        ),
                      ),
                    ),

                  // Button with fixed width
                  if (showAction)
                    ElevatedButton(
                      onPressed: goToLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 24,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: AppTheme.defaultBorderRadius,
                        ),
                        elevation: 2,
                        fixedSize: const Size(250, 50), // Fixed width and height
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.login_rounded, size: 20),
                          const SizedBox(width: 12),
                          Text(
                            'Back to Login',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Simple _StyledText Widget
class _StyledText extends StatelessWidget {
  final String text;
  final Color color;
  final Color borderColor;
  final Color shadowColor;

  const _StyledText({
    required this.text,
    required this.color,
    required this.borderColor,
    required this.shadowColor,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Border stroke
        Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 4
              ..color = borderColor,
          ),
        ),
        // Fill
        Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
            color: color,
            shadows: [
              Shadow(
                offset: const Offset(0, 3),
                blurRadius: 8,
                color: shadowColor,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
