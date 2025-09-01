// lib/features/result/widgets/result_header.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ResultHeader extends StatefulWidget {
  const ResultHeader({
    super.key,
    required this.siteCode,
    required this.siteName,
    required this.timestamp,
    required this.totalScore,
    required this.maxScore,
    required this.percent,
    required this.percentLabel,
  });

  final String siteCode;
  final String? siteName;
  final DateTime timestamp;
  final int totalScore;
  final int maxScore;
  final double percent;
  final String percentLabel;

  @override
  State<ResultHeader> createState() => _ResultHeaderState();
}

class _ResultHeaderState extends State<ResultHeader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _animation =
        Tween<double>(begin: 0.0, end: widget.percent.clamp(0.0, 1.0)).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
        )..addListener(() {
          setState(() {});
        });

    // Start animation after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final date = DateFormat('MMMM d, y • h:mm a').format(widget.timestamp);
    final animatedPercent = _animation.value * 100;
    final animatedPercentLabel = '${animatedPercent.toStringAsFixed(1)}%';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.grey[50]!, Colors.grey[100]!],
        ),
        border: Border(bottom: BorderSide(color: Colors.grey[300]!, width: 1)),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Title
            Text(
              'SURVEY COMPLETED',
              style: theme.textTheme.labelSmall?.copyWith(
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 16),

            // Main Content Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Site Information
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Site Code and Name
                      Text(
                        widget.siteCode,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.siteName ?? 'Unknown Site',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Date and Time
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 18,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            date,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Score Display
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey[200]!,
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Score',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '${widget.totalScore}/${widget.maxScore}',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: Colors.grey[800],
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 24),

                // Animated Score Circle
                _buildAnimatedScoreCircle(theme, animatedPercentLabel),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedScoreCircle(ThemeData theme, String percentLabel) {
    final scoreColor = _getScoreColor(_animation.value);

    return SizedBox(
      width: 100,
      height: 100,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background Circle
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
          ),

          // Progress Background
          SizedBox(
            width: 84,
            height: 84,
            child: CircularProgressIndicator(
              value: 1.0,
              strokeWidth: 6,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[200]!),
            ),
          ),

          // Animated Progress
          SizedBox(
            width: 84,
            height: 84,
            child: CircularProgressIndicator(
              value: _animation.value.clamp(0.0, 1.0),
              strokeWidth: 6,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
            ),
          ),

          // Percentage Text
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                percentLabel,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: scoreColor,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Completed',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          // Outer Ring
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: scoreColor.withOpacity(0.2), width: 2),
            ),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(double percent) {
    if (percent >= 0.8) return const Color(0xFF10B981); // Emerald Green
    if (percent >= 0.6) return const Color(0xFFF59E0B); // Amber
    if (percent >= 0.4) return const Color(0xFFEF4444); // Red
    return const Color(0xFF6B7280); // Gray
  }
}
