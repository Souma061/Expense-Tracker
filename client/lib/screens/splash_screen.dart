import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Pure visual splash screen.
/// Navigation is handled entirely by main.dart's FutureBuilder on getToken().
class Splashscreen extends StatelessWidget {
  const Splashscreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 28.w),
            child: Column(
              children: [
                const Spacer(flex: 2),
                Container(
                      height: 150.w,
                      width: 150.w,
                      padding: EdgeInsets.all(18.w),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.20),
                          width: 1.5,
                        ),
                      ),
                      child: Image.asset(
                        "assets/images/logo.png",
                        fit: BoxFit.contain,
                      ),
                    )
                    .animate()
                    .scale(
                      begin: const Offset(0.86, 0.86),
                      end: const Offset(1, 1),
                      curve: Curves.easeOutBack,
                      duration: const Duration(milliseconds: 650),
                    )
                    .fadeIn(duration: const Duration(milliseconds: 450)),
                SizedBox(height: 26.h),
                Text(
                      "Expense Tracker",
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineLarge
                          ?.copyWith(
                            fontSize: 30.sp,
                            fontWeight: FontWeight.w800,
                          ),
                    )
                    .animate()
                    .fadeIn(
                      delay: const Duration(milliseconds: 180),
                      duration: const Duration(milliseconds: 500),
                    )
                    .slideY(
                      begin: 0.18,
                      end: 0,
                      curve: Curves.easeOut,
                      duration: const Duration(milliseconds: 500),
                    ),
                SizedBox(height: 8.h),
                Text(
                  "Track spending. Plan better.",
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ).animate().fadeIn(
                  delay: const Duration(milliseconds: 320),
                  duration: const Duration(milliseconds: 500),
                ),
                const Spacer(flex: 2),
                SizedBox(
                  width: 34.w,
                  height: 34.w,
                  child: CircularProgressIndicator(
                    strokeWidth: 3.w,
                    color: Theme.of(context).colorScheme.primary,
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.14),
                  ),
                ).animate().fadeIn(
                  delay: const Duration(milliseconds: 420),
                  duration: const Duration(milliseconds: 450),
                ),
                SizedBox(height: 16.h),
                Text(
                  "Loading your wallet...",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ).animate().fadeIn(
                  delay: const Duration(milliseconds: 520),
                  duration: const Duration(milliseconds: 450),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
