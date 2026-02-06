import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class ModernStatCard extends StatefulWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final double? trend;

  const ModernStatCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle = '',
    required this.icon,
    this.accentColor = AppColors.earthyCoral,
    this.trend,
  });

  @override
  State<ModernStatCard> createState() => _ModernStatCardState();
}

class _ModernStatCardState extends State<ModernStatCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.03,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onHover(bool hovering) {
    if (hovering) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _onHover(true),
      onExit: (_) => _onHover(false),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.white, Colors.white.withOpacity(0.95)],
                ),
                border: Border.all(
                  color: widget.accentColor.withOpacity(
                    0.1 + (_glowAnimation.value * 0.15),
                  ),
                  width: 1.5,
                ),
                boxShadow: [
                  // Main shadow
                  BoxShadow(
                    color: widget.accentColor.withOpacity(
                      0.08 + (_glowAnimation.value * 0.12),
                    ),
                    blurRadius: 20 + (_glowAnimation.value * 15),
                    offset: Offset(0, 8 + (_glowAnimation.value * 4)),
                    spreadRadius: -2,
                  ),
                  // Soft ambient shadow
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  children: [
                    // Gradient accent overlay
                    Positioned(
                      right: -30,
                      top: -30,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              widget.accentColor.withOpacity(0.15),
                              widget.accentColor.withOpacity(0.0),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Bottom accent line
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 3,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              widget.accentColor.withOpacity(0.0),
                              widget.accentColor.withOpacity(
                                0.4 + (_glowAnimation.value * 0.3),
                              ),
                              widget.accentColor.withOpacity(0.0),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Main content
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header row with icon and trend
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Icon with gradient background
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      widget.accentColor.withOpacity(0.15),
                                      widget.accentColor.withOpacity(0.08),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  widget.icon,
                                  color: widget.accentColor,
                                  size: 22,
                                ),
                              ),

                              // Trend badge
                              if (widget.trend != null) _buildTrendBadge(),
                            ],
                          ),

                          const Spacer(),

                          // Value with animated styling
                          ShaderMask(
                            shaderCallback: (bounds) => LinearGradient(
                              colors: [
                                AppColors.darkCharcoal,
                                AppColors.darkCharcoal.withOpacity(0.85),
                              ],
                            ).createShader(bounds),
                            child: Text(
                              widget.value,
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -1.2,
                                height: 1.0,
                              ),
                            ),
                          ),

                          const SizedBox(height: 6),

                          // Title
                          Text(
                            widget.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.slateGray,
                              letterSpacing: 0.2,
                            ),
                          ),

                          // Subtitle
                          if (widget.subtitle.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              widget.subtitle,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.slateGray.withOpacity(0.7),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTrendBadge() {
    final isPositive = widget.trend! >= 0;
    final bgColor = isPositive
        ? const Color(0xFF10B981).withOpacity(0.12)
        : AppColors.error.withOpacity(0.12);
    final textColor = isPositive ? const Color(0xFF059669) : AppColors.error;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive
                ? Icons.trending_up_rounded
                : Icons.trending_down_rounded,
            size: 14,
            color: textColor,
          ),
          const SizedBox(width: 3),
          Text(
            '${widget.trend!.abs().toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
