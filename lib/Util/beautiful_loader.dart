import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lms_publisher/Theme/apptheme.dart';

/// A beautiful custom loader widget with various styles
class BeautifulLoader extends StatefulWidget {
  final LoaderType type;
  final double size;
  final Color? color;
  final String? message;

  const BeautifulLoader({
    Key? key,
    this.type = LoaderType.circular,
    this.size = 50,
    this.color,
    this.message,
  }) : super(key: key);

  @override
  State<BeautifulLoader> createState() => _BeautifulLoaderState();
}

class _BeautifulLoaderState extends State<BeautifulLoader>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loaderColor = widget.color ?? AppTheme.primaryGreen;

    Widget loader;
    switch (widget.type) {
      case LoaderType.circular:
        loader = _buildCircularLoader(loaderColor);
        break;
      case LoaderType.dots:
        loader = _buildDotsLoader(loaderColor);
        break;
      case LoaderType.bars:
        loader = _buildBarsLoader(loaderColor);
        break;
      case LoaderType.spinner:
        loader = _buildSpinnerLoader(loaderColor);
        break;
      case LoaderType.pulse:
        loader = _buildPulseLoader(loaderColor);
        break;
    }

    if (widget.message != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          loader,
          const SizedBox(height: 16),
          Text(
            widget.message!,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppTheme.bodyText,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    return loader;
  }

  Widget _buildCircularLoader(Color color) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: CircularProgressIndicator(
        strokeWidth: 3,
        valueColor: AlwaysStoppedAnimation(color),
      ),
    );
  }

  Widget _buildDotsLoader(Color color) {
    return SizedBox(
      width: widget.size * 1.5,
      height: widget.size / 2,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(3, (index) {
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final delay = index * 0.2;
              final value = (_controller.value - delay) % 1.0;
              final scale = value < 0.5 ? value * 2 : (1 - value) * 2;

              return Transform.scale(
                scale: 0.5 + (scale * 0.5),
                child: Container(
                  width: widget.size / 4,
                  height: widget.size / 4,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }

  Widget _buildBarsLoader(Color color) {
    return SizedBox(
      width: widget.size * 1.2,
      height: widget.size,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(4, (index) {
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final delay = index * 0.15;
              final value = (_controller.value - delay) % 1.0;
              final height = (value < 0.5 ? value : 1 - value) * 2;

              return Container(
                width: widget.size / 8,
                height: widget.size * 0.3 + (widget.size * 0.7 * height),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            },
          );
        }),
      ),
    );
  }

  Widget _buildSpinnerLoader(Color color) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.rotate(
          angle: _controller.value * 2 * 3.14159,
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: Stack(
              children: List.generate(8, (index) {
                final angle = (index * 3.14159 / 4);
                final opacity = 1.0 - (index * 0.12);
                return Transform.rotate(
                  angle: angle,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Container(
                      width: widget.size / 8,
                      height: widget.size / 3,
                      decoration: BoxDecoration(
                        color: color.withOpacity(opacity),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPulseLoader(Color color) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final scale = 0.7 + (_pulseController.value * 0.3);
        final opacity = 1.0 - (_pulseController.value * 0.5);

        return Stack(
          alignment: Alignment.center,
          children: [
            // Outer pulse
            Transform.scale(
              scale: scale,
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withOpacity(opacity * 0.3),
                ),
              ),
            ),
            // Inner circle
            Container(
              width: widget.size * 0.6,
              height: widget.size * 0.6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
              ),
            ),
          ],
        );
      },
    );
  }
}

enum LoaderType {
  circular,
  dots,
  bars,
  spinner,
  pulse,
}

/// Overlay loader that covers the entire screen
class OverlayLoader {
  static OverlayEntry? _currentOverlay;

  static void show(
      BuildContext context, {
        String? message,
        LoaderType type = LoaderType.circular,
        Color? backgroundColor,
        Color? loaderColor,
      }) {
    hide(); // Remove any existing overlay

    _currentOverlay = OverlayEntry(
      builder: (context) => Material(
        color: (backgroundColor ?? Colors.black).withOpacity(0.5),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: BeautifulLoader(
              type: type,
              message: message,
              color: loaderColor,
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_currentOverlay!);
  }

  static void hide() {
    _currentOverlay?.remove();
    _currentOverlay = null;
  }
}

/// Button loader for inline loading states
class ButtonLoader extends StatelessWidget {
  final Color? color;
  final double size;

  const ButtonLoader({
    Key? key,
    this.color,
    this.size = 18,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation(color ?? Colors.white),
      ),
    );
  }
}
