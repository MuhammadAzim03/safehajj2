import 'dart:ui';

import 'package:flutter/material.dart';

class GlassSliderItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;
  final LinearGradient? gradient; // Optional per-card gradient

  const GlassSliderItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.onTap,
    this.gradient,
  });
}

class GlassMorphismSlider extends StatefulWidget {
  final List<GlassSliderItem> items;
  final double height;
  final double viewportFraction;
  final BorderRadiusGeometry borderRadius;

  const GlassMorphismSlider({
    super.key,
    required this.items,
    this.height = 220,
    this.viewportFraction = 0.85,
    this.borderRadius = const BorderRadius.all(Radius.circular(28)),
  });

  @override
  State<GlassMorphismSlider> createState() => _GlassMorphismSliderState();
}

class _GlassMorphismSliderState extends State<GlassMorphismSlider> {
  late final PageController _pageController;
  int _currentPage = 0;

  // SafeHajj blue-ish default gradient
  LinearGradient get _defaultGradient => const LinearGradient(
        colors: [Color(0xFF67A9D5), Color(0xFF1A4363)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: widget.viewportFraction);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: widget.height,
      child: PageView.builder(
        controller: _pageController,
        onPageChanged: (i) => setState(() => _currentPage = i),
        itemCount: widget.items.length,
        itemBuilder: (context, index) {
          return AnimatedBuilder(
            animation: _pageController,
            builder: (context, child) {
              double t = 1.0;
              if (_pageController.position.haveDimensions) {
                final page = _pageController.page ?? _currentPage.toDouble();
                t = (1 - ((page - index).abs() * 0.25)).clamp(0.88, 1.0);
              }
              return Transform.scale(
                scale: Curves.easeOut.transform(t),
                child: child,
              );
            },
            child: _GlassCard(
              item: widget.items[index],
              borderRadius: widget.borderRadius,
              background: widget.items[index].gradient ?? _defaultGradient,
            ),
          );
        },
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final GlassSliderItem item;
  final LinearGradient background;
  final BorderRadiusGeometry borderRadius;

  const _GlassCard({
    required this.item,
    required this.background,
    required this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: GestureDetector(
        onTap: item.onTap,
        child: ClipRRect(
          borderRadius: borderRadius,
          child: Container(
            decoration: BoxDecoration(gradient: background),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Frosted overlay layer
                Container(color: Colors.white.withOpacity(0.08)),
                BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(color: Colors.white.withOpacity(0.05)),
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.white.withOpacity(0.25), width: 1.2),
                        ),
                        child: Icon(item.icon, size: 48, color: Colors.white),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        item.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.subtitle,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
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
    );
  }
}
