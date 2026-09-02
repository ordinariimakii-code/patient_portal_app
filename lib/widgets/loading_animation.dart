import 'package:flutter/material.dart';
import '../utils/colors.dart';

class LoadingAnimation extends StatelessWidget {
  final String? message;
  final bool fullScreen;

  const LoadingAnimation({
    super.key,
    this.message,
    this.fullScreen = true,
  });

  @override
  Widget build(BuildContext context) {
    final content = Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Simple loading spinner
          const SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              strokeWidth: 4,
              color: Color(0xFF1A237E),
            ),
          ),
          const SizedBox(height: 20),
          // Loading text
          Column(
            children: [
              if (message != null) ...[
                Text(
                  message!,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    color: Color(0xFF1A237E),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              // Animated dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildDot(0),
                  const SizedBox(width: 10),
                  _buildDot(1),
                  const SizedBox(width: 10),
                  _buildDot(2),
                ],
              ),
            ],
          ),
        ],
      ),
    );

    if (fullScreen) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: content,
      );
    }

    return content;
  }

  Widget _buildDot(int index) {
    return TweenAnimationBuilder(
      duration: const Duration(milliseconds: 600),
      tween: Tween<double>(begin: 0.3, end: 1.0),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        final delay = index * 200;
        return FutureBuilder(
          future: Future.delayed(Duration(milliseconds: delay)),
          builder: (context, snapshot) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 10 + (value * 6),
              height: 10 + (value * 6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary.withValues(alpha: 0.3 + (value * 0.7)),
                    AppColors.secondary.withValues(alpha: 0.3 + (value * 0.7)),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2 * value),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
            );
          },
        );
      },
      onEnd: () {},
    );
  }
}