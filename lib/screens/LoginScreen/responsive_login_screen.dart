import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lms_publisher/Provider/UserProvider.dart';
import 'package:lms_publisher/Service/user_right_service.dart';
import 'package:lms_publisher/screens/HomePage/HomePage.dart';
import 'package:lms_publisher/screens/LoginScreen/login_bloc.dart';
import '../../Theme/apptheme.dart';
import '../../Util/custom_snackbar.dart';
import '../../Util/beautiful_loader.dart';

class ResponsiveLoginScreen extends StatelessWidget {
  const ResponsiveLoginScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => LoginBloc(
        userRightsService: UserRightsService(),
        userProvider: context.read<UserProvider>(),
      )..add(LoadUserGroups()),
      child: const _ResponsiveLoginScreenContent(),
    );
  }
}

class _ResponsiveLoginScreenContent extends StatelessWidget {
  const _ResponsiveLoginScreenContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocListener<LoginBloc, LoginState>(
      listener: (context, state) {
        // Hide loader when not loading
        if (state is! LoginLoading) {
          OverlayLoader.hide();
        }

        // Show loader when loading
        if (state is LoginLoading) {
          OverlayLoader.show(
            context,
            message: 'Authenticating your credentials...',
            type: LoaderType.spinner,
          );
        }

        if (state is LoginSuccess) {
          OverlayLoader.hide();
          CustomSnackbar.showSuccess(
            context,
            'Welcome back! You have successfully logged in.',
            title: 'Login Successful',
          );
          Future.delayed(const Duration(milliseconds: 500), () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          });
        } else if (state is LoginFailure) {
          OverlayLoader.hide();
          CustomSnackbar.showError(
            context,
            state.error,
            title: 'Login Failed',
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.background,
        body: LayoutBuilder(
          builder: (context, constraints) {
            bool isDesktop = constraints.maxWidth > 800;
            return isDesktop
                ? const _DesktopLayout()
                : const _MobileLayout();
          },
        ),
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
                    constraints: const BoxConstraints(maxWidth: 480),
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
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: _LoginForm(isMobile: true),
          ),
        ),
      ),
    );
  }
}

// =========================================================================
// --- CORE LOGIN FORM ---
// =========================================================================

class _LoginForm extends StatelessWidget {
  final bool isMobile;
  const _LoginForm({this.isMobile = false, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LoginBloc, LoginState>(
      builder: (context, state) {
        // Show beautiful loader while initializing
        if (state is LoginInitial) {
          return Center(
            child: BeautifulLoader(
              type: LoaderType.dots,
              message: 'Loading...',
              color: AppTheme.primaryGreen,
            ),
          );
        }

        final isLoaded = state is UserGroupsLoaded;
        final userGroups = isLoaded ? (state as UserGroupsLoaded).userGroups : <UserGroup>[];
        final defaultRole = userGroups.isNotEmpty ? userGroups.first : null;

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _BrandLogo(),
            const SizedBox(height: 32),
            Text(
              'Welcome Back',
              style: AppTheme.headline1,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Sign in to access your LMS account',
              style: AppTheme.bodyText1,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),

            // User ID Field
            _CustomTextFormField(
              hintText: 'Enter User ID',
              prefixIcon: Icons.person_outline,
              onChanged: (value) {
                context.read<LoginBloc>().add(UserIdChanged(value));
              },
            ),
            const SizedBox(height: 24),

            // Password Field
            _CustomTextFormField(
              hintText: 'Enter your password',
              prefixIcon: Icons.lock_outline,
              isPassword: true,
              onChanged: (value) {
                context.read<LoginBloc>().add(PasswordChanged(value));
              },
            ),
            const SizedBox(height: 16),

            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  CustomSnackbar.showInfo(
                    context,
                    'Password recovery instructions have been sent to your registered email.',
                    title: 'Check Your Email',
                  );
                },
                child: Text(
                  'Forgot Password?',
                  style: AppTheme.labelText.copyWith(
                    color: AppTheme.primaryGreen,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Login button with loading state
            _LoginButton(
              onPressed: () {
                if (defaultRole != null) {
                  context.read<LoginBloc>().add(RoleSelected(defaultRole));
                }
                context.read<LoginBloc>().add(LoginSubmitted());
              },
              isLoading: state is LoginLoading,
            ),
            const SizedBox(height: 24),

            _SignUpSection(),
          ],
        );
      },
    );
  }
}

// =========================================================================
// --- SIGN UP SECTION ---
// =========================================================================

class _SignUpSection extends StatelessWidget {
  const _SignUpSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text("Don't have an account? ", style: AppTheme.bodyText1),
        TextButton(
          onPressed: () {
            CustomSnackbar.showInfo(
              context,
              'Please contact your administrator for account registration.',
              title: '📞 Contact Admin',
            );
          },
          child: Text(
            'Sign Up',
            style: AppTheme.labelText.copyWith(
              color: AppTheme.primaryGreen,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

// =========================================================================
// --- FORM WIDGETS ---
// =========================================================================

class _CustomTextFormField extends StatefulWidget {
  final String hintText;
  final IconData prefixIcon;
  final bool isPassword;
  final ValueChanged<String>? onChanged;

  const _CustomTextFormField({
    required this.hintText,
    required this.prefixIcon,
    this.isPassword = false,
    this.onChanged,
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
                color: AppTheme.shadowColor
                    .withOpacity(0.1 * _shadowAnimation.value),
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
        obscureText: widget.isPassword ? _obscureText : false,
        onChanged: widget.onChanged,
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

// =========================================================================
// --- ENHANCED LOGIN BUTTON ---
// =========================================================================

class _LoginButton extends StatefulWidget {
  final VoidCallback onPressed;
  final bool isLoading;

  const _LoginButton({
    required this.onPressed,
    this.isLoading = false,
    Key? key,
  }) : super(key: key);

  @override
  State<_LoginButton> createState() => _LoginButtonState();
}

class _LoginButtonState extends State<_LoginButton>
    with SingleTickerProviderStateMixin {
  bool _isHovering = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    if (widget.isLoading) {
      _pulseController.repeat();
    }
  }

  @override
  void didUpdateWidget(_LoginButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoading && !oldWidget.isLoading) {
      _pulseController.repeat();
    } else if (!widget.isLoading && oldWidget.isLoading) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.translationValues(0, _isHovering && !widget.isLoading ? -2 : 0, 0),
        decoration: BoxDecoration(
          gradient: widget.isLoading
              ? LinearGradient(
            colors: [
              AppTheme.primaryGreen.withOpacity(0.7),
              AppTheme.primaryGreen.withOpacity(0.5),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
              : AppTheme.primaryGradient,
          borderRadius: AppTheme.defaultBorderRadius,
          boxShadow: [
            BoxShadow(
              color: _isHovering && !widget.isLoading
                  ? AppTheme.primaryGreen.withOpacity(0.4)
                  : AppTheme.primaryGreen.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: widget.isLoading ? null : widget.onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 20),
            shape: RoundedRectangleBorder(
              borderRadius: AppTheme.defaultBorderRadius,
            ),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                  scale: animation,
                  child: child,
                ),
              );
            },
            child: widget.isLoading
                ? Row(
              key: const ValueKey('loading'),
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Signing in...',
                  style: AppTheme.buttonText,
                ),
              ],
            )
                : Row(
              key: const ValueKey('login'),
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.login_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text('Log In', style: AppTheme.buttonText),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =========================================================================
// --- BACKGROUND & DECORATIVE ELEMENTS ---
// =========================================================================

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
                'https://images.unsplash.com/photo-1543269865-cbf427effbad?ixlib=rb-4.0.3&q=85&fm=jpg&crop=entropy&cs=srgb&w=3600',
              ),
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
                    'Welcome to\nMACK CLEO LMS',
                    style: AppTheme.headline2,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Empowering educators and institutions with world-class learning management tools.',
                    style: AppTheme.bodyText1.copyWith(
                      color: Colors.white.withOpacity(0.8),
                    ),
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
// --- BRAND LOGO ---
// =========================================================================

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
        Text(
          text,
          style: AppTheme.logoStyle.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.0
              ..color = shadowColor,
          ),
        ),
        Text(
          text,
          style: AppTheme.logoStyle.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.8
              ..color = borderColor,
          ),
        ),
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
