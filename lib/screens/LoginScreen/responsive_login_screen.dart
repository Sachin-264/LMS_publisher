import 'package:flutter/material.dart';
import 'dart:ui'; // Import for ImageFilter.
import 'package:flutter/animation.dart'; // Import for Animation.
import 'package:lms_publisher/screens/HomePage/HomePage.dart';

// TODO: Adjust these import paths to match your project structure
import '../../Theme/apptheme.dart';
import '../../Util/custom_snackbar.dart';

class ResponsiveLoginScreen extends StatefulWidget {
  const ResponsiveLoginScreen({Key? key}) : super(key: key);

  @override
  State<ResponsiveLoginScreen> createState() => _ResponsiveLoginScreenState();
}

class _ResponsiveLoginScreenState extends State<ResponsiveLoginScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          // A standard breakpoint for desktop
          bool isDesktop = constraints.maxWidth > 800;
          return isDesktop ? const _DesktopLayout() : const _MobileLayout();
        },
      ),
    );
  }
}

// =========================================================================
// --- ROOT LAYOUT WIDGETS (Desktop & Mobile) ---
// =========================================================================

class _DesktopLayout extends StatelessWidget {
  const _DesktopLayout({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: Container(
            color: Colors.white,
            child: Stack(
              children: [
                const _AbstractBackground(),
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 450),
                    child: const SingleChildScrollView(
                      padding: EdgeInsets.all(40),
                      child: _LoginForm(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const Expanded(
          flex: 6,
          child: _ImagePanel(),
        ),
      ],
    );
  }
}

class _MobileLayout extends StatelessWidget {
  const _MobileLayout({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: _LoginForm(isMobile: true),
          ),
        ),
      ),
    );
  }
}

// =========================================================================
// --- CORE & SHARED UI COMPONENTS ---
// =========================================================================

/// The main login form, used by both mobile and desktop layouts.
class _LoginForm extends StatelessWidget {
  final bool isMobile;
  const _LoginForm({this.isMobile = false, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _BrandLogo(),
        const SizedBox(height: 32),
        Text('Welcome, Publisher', style: AppTheme.headline1),
        const SizedBox(height: 8),
        Text('Sign in to manage your institution.', style: AppTheme.bodyText1),
        const SizedBox(height: 40),

        _CustomTextFormField(
          controller: emailController,
          hintText: 'you@example.com',
          prefixIcon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 24),

        _CustomTextFormField(
          controller: passwordController,
          hintText: 'Enter your password',
          prefixIcon: Icons.lock_outline,
          isPassword: true,
        ),
        const SizedBox(height: 16),

        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {
              CustomSnackbar.showInfo(
                context,
                'Password recovery instructions have been sent to your registered email address.',
                title: 'Check Your Email',
              );
            },
            child: Text(
              'Forgot Password?',
              style: AppTheme.labelText.copyWith(color: AppTheme.primaryGreen),
            ),
          ),
        ),
        const SizedBox(height: 24),

        _LoginButton(onPressed: () {
          // Navigate to HomeScreen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }),
        const SizedBox(height: 24),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Don't have an account? ", style: AppTheme.bodyText1),
            TextButton(
              onPressed: () {
                CustomSnackbar.showSuccess(
                  context,
                  'To create a publisher account, please contact your system administrator for an invitation.',
                  title: 'Admin Contact Required',
                );
              },
              child: Text(
                'Sign Up',
                style: AppTheme.labelText.copyWith(color: AppTheme.primaryGreen),
              ),
            ),
          ],
        ),
      ],
    );
  }
}


class _AbstractBackground extends StatelessWidget {
  const _AbstractBackground({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -100,
          left: -100,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  AppTheme.primaryGreen.withOpacity(0.1),
                  Colors.white.withOpacity(0.1),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -150,
          right: -150,
          child: Container(
            width: 400,
            height: 400,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  AppTheme.cleoBorder.withOpacity(0.15),
                  Colors.white.withOpacity(0.1),
                ],
              ),
            ),
          ),
        ),
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 100.0, sigmaY: 100.0),
          child: Container(
            color: Colors.white.withOpacity(0.1),
          ),
        ),
      ],
    );
  }
}

/// The animated image panel for the desktop layout.
class _ImagePanel extends StatefulWidget {
  const _ImagePanel({Key? key}) : super(key: key);

  @override
  State<_ImagePanel> createState() => _ImagePanelState();
}

class _ImagePanelState extends State<_ImagePanel>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _scaleAnimation = Tween<double>(begin: 1.05, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          margin: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            image: DecorationImage(
              image: const NetworkImage(
                  'https://images.unsplash.com/photo-1543269865-cbf427effbad?ixlib=rb-4.0.3&q=85&fm=jpg&crop=entropy&cs=srgb&w=3600'),
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(
                Colors.black.withOpacity(0.4),
                BlendMode.darken,
              ),
            ),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Welcome to the\nMACK CLEO Publisher Portal',
                    style: AppTheme.headline2,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Empowering educators and institutions with world-class learning management tools.',
                    style: AppTheme.bodyText1.copyWith(color: Colors.white.withOpacity(0.8)),
                    textAlign: TextAlign.center,
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

// =========================================================================
// --- FORM & BUTTON WIDGETS ---
// =========================================================================

/// A custom, interactive text form field with focus animations.
class _CustomTextFormField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData prefixIcon;
  final bool isPassword;
  final TextInputType? keyboardType;

  const _CustomTextFormField({
    required this.controller,
    required this.hintText,
    required this.prefixIcon,
    this.isPassword = false,
    this.keyboardType,
    Key? key,
  }) : super(key: key);

  @override
  _CustomTextFormFieldState createState() => _CustomTextFormFieldState();
}

class _CustomTextFormFieldState extends State<_CustomTextFormField>
    with SingleTickerProviderStateMixin {
  final FocusNode _focusNode = FocusNode();
  late AnimationController _animationController;
  late Animation<double> _shadowAnimation;
  bool _obscureText = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _shadowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shadowAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: AppTheme.defaultBorderRadius,
            boxShadow: [
              BoxShadow(
                color: AppTheme.shadowColor.withOpacity(0.1 * _shadowAnimation.value),
                blurRadius: 10 * _shadowAnimation.value,
                offset: Offset(0, 4 * _shadowAnimation.value),
              ),
            ],
          ),
          child: child,
        );
      },
      child: TextFormField(
        focusNode: _focusNode,
        controller: widget.controller,
        obscureText: widget.isPassword ? _obscureText : false,
        keyboardType: widget.keyboardType,
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: AppTheme.bodyText1,
          prefixIcon: Icon(widget.prefixIcon, color: AppTheme.bodyText),
          suffixIcon: widget.isPassword
              ? IconButton(
            onPressed: () => setState(() => _obscureText = !_obscureText),
            icon: Icon(
              _obscureText
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: AppTheme.bodyText,
            ),
          )
              : null,
          filled: true,
          fillColor: AppTheme.lightGrey,
          contentPadding: const EdgeInsets.all(AppTheme.defaultPadding),
          border: OutlineInputBorder(
            borderRadius: AppTheme.defaultBorderRadius,
            borderSide: const BorderSide(color: AppTheme.borderGrey),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: AppTheme.defaultBorderRadius,
            borderSide: const BorderSide(color: AppTheme.borderGrey),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: AppTheme.defaultBorderRadius,
            borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 2),
          ),
        ),
        style: AppTheme.bodyText1.copyWith(color: AppTheme.darkText),
      ),
    );
  }
}

/// A custom login button with hover effects for desktop and navigation to HomeScreen.
class _LoginButton extends StatefulWidget {
  final VoidCallback onPressed;
  const _LoginButton({required this.onPressed, Key? key}) : super(key: key);

  @override
  State<_LoginButton> createState() => _LoginButtonState();
}

class _LoginButtonState extends State<_LoginButton> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.translationValues(0, _isHovering ? -2 : 0, 0),
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: AppTheme.defaultBorderRadius,
          boxShadow: [
            BoxShadow(
              color: _isHovering
                  ? AppTheme.primaryGreen.withOpacity(0.4)
                  : AppTheme.primaryGreen.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: widget.onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 20),
            shape: RoundedRectangleBorder(
              borderRadius: AppTheme.defaultBorderRadius,
            ),
          ),
          child: Text('Log In', style: AppTheme.buttonText),
        ),
      ),
    );
  }
}

// =========================================================================
// --- ENHANCED BRAND LOGO ---
// =========================================================================

/// The enhanced brand logo widget with animated gradient and improved styling.
class _BrandLogo extends StatefulWidget {
  const _BrandLogo({Key? key}) : super(key: key);

  @override
  _BrandLogoState createState() => _BrandLogoState();
}

class _BrandLogoState extends State<_BrandLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _gradientColor1;
  late Animation<Color?> _gradientColor2;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _gradientColor1 = ColorTween(
      begin: AppTheme.primaryGreen,
      end: AppTheme.cleoColor,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _gradientColor2 = ColorTween(
      begin: AppTheme.cleoColor,
      end: AppTheme.primaryGreen,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_gradientColor1.value!, _gradientColor2.value!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: AppTheme.defaultBorderRadius,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryGreen.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.school_rounded,
                color: Colors.white,
                size: 36,
              ),
            );
          },
        ),
        const SizedBox(width: 16),
        Row(
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
      ],
    );
  }
}

/// Helper widget to create text with a stroke effect and shadow for the logo.
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
        // Shadow layer
        Text(
          text,
          style: AppTheme.logoStyle.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.0
              ..color = shadowColor,
          ),
        ),
        // Border layer (stroke)
        Text(
          text,
          style: AppTheme.logoStyle.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.8
              ..color = borderColor,
          ),
        ),
        // Fill layer
        Text(
          text,
          style: AppTheme.logoStyle.copyWith(
            color: color,
            shadows: [
              Shadow(
                color: shadowColor,
                blurRadius: 4,
                offset: const Offset(2, 2),
              ),
            ],
          ),
        ),
      ],
    );
  }
}