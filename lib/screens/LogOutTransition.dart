import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
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

  @override
  void initState() {
    super.initState();
    // Simulate contacting Mackleo
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) setState(() => showAction = true);
    });
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
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
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Stack(
        children: [
          // Optional: replicate your login background (gradients/illustrations)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary.withOpacity(0.06),
                    theme.colorScheme.secondary.withOpacity(0.06),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // App brand/logo area similar to login
                    Icon(Iconsax.logout, // Replace with your brand asset if used in login
                        size: 64, color: theme.colorScheme.primary),
                    const SizedBox(height: 16),
                    Text(
                      'Signing you out',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Contacting Mackleo and securely closing your session…',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),

                    // Loader animation aligned with your login aesthetics
                    SizedBox(
                      height: 56,
                      width: 56,
                      child: AnimatedBuilder(
                        animation: _controller,
                        builder: (_, __) {
                          return CustomPaint(
                            painter: _RingSpinnerPainter(
                              progress: _controller.value,
                              color: theme.colorScheme.primary,
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 28),
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 400),
                      opacity: showAction ? 1.0 : 0.0,
                      child: IgnorePointer(
                        ignoring: !showAction,
                        child: SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: goToLogin,
                            icon: const Icon(Icons.login_rounded),
                            label: const Text('Back to Login'),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 14, horizontal: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Extra hint
                    if (!showAction) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Please wait a moment…',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Simple ring spinner painter to keep dependencies light
class _RingSpinnerPainter extends CustomPainter {
  final double progress;
  final Color color;
  _RingSpinnerPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..color = color;

    final rect = Offset.zero & size;
    final start = progress * 360.0;
    const sweep = 270.0;

    // background arc (subtle)
    final bg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..color = color.withOpacity(0.15);
    canvas.drawArc(rect.deflate(4), 0, 2 * 3.14159, false, bg);

    // foreground rotating arc
    final startRad = start * 3.14159 / 180.0;
    final sweepRad = sweep * 3.14159 / 180.0;
    canvas.drawArc(rect.deflate(4), startRad, sweepRad, false, stroke);
  }

  @override
  bool shouldRepaint(covariant _RingSpinnerPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

// TEMP icon reference if you use iconsax
class IconsaxLogoutCurveBold {
  static const IconData data = Icons.logout_rounded;
}
