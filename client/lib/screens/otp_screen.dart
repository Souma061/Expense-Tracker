import 'dart:async';

import 'package:expense_tracker/apis/auth_services.dart';
import 'package:expense_tracker/screens/hidden_drawer.dart';
import 'package:expense_tracker/screens/register_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';

class OtpScreen extends StatefulWidget {
  final String email;
  const OtpScreen({super.key, required this.email});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen>
    with SingleTickerProviderStateMixin {
  static const int _otpLength = 6; // Length of the OTP code
  static const int _timerSeconds = 10; // 5 minutes in seconds
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;
  late final AnimationController _errorAnimationController;
  late final Animation<double> _shakeAnimation;
  bool _isError = false;
  Timer? _timer;
  int _secondsRemaining = _timerSeconds;

  bool get _isOtpComplete =>
      _controllers.every((controller) => controller.text.trim().isNotEmpty);

  String get _otpCode =>
      _controllers.map((controller) => controller.text.trim()).join();

  String get _formattedTime {
    final minutes = (_secondsRemaining ~/ 60).toString().padLeft(2, '0');
    final seconds = (_secondsRemaining % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      _otpLength,
      (index) => TextEditingController(),
    );
    _focusNodes = List.generate(_otpLength, (index) => FocusNode());
    _errorAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 720),
    );
    _shakeAnimation =
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 0, end: -8), weight: 1),
          TweenSequenceItem(tween: Tween(begin: -8, end: 8), weight: 2),
          TweenSequenceItem(tween: Tween(begin: 8, end: -6), weight: 2),
          TweenSequenceItem(tween: Tween(begin: -6, end: 6), weight: 2),
          TweenSequenceItem(tween: Tween(begin: 6, end: 0), weight: 1),
        ]).animate(
          CurvedAnimation(
            parent: _errorAnimationController,
            curve: Curves.easeInOut,
          ),
        );
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _errorAnimationController.dispose();
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final emailText = widget.email;
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.fromLTRB(
              15.w,
              0,
              15.w,
              MediaQuery.viewInsetsOf(context).bottom + 24.h,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight:
                    MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom,
              ),
              child:
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 24.h),
                      _BackButton(),
                      SizedBox(height: 10.h),
                      _Header(email: emailText),
                      SizedBox(height: 44.h),
                      _OtpFields(
                        controllers: _controllers,
                        focusNodes: _focusNodes,
                        onChanged: _handleOtpChanged,
                        hasError: _isError,
                        shakeAnimation: _shakeAnimation,
                      ),
                      SizedBox(height: 16.h),
                      Center(
                        child: Text(
                          _secondsRemaining > 0
                              ? "Resend code in $_formattedTime"
                              : "You can request a new code now.",
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: _secondsRemaining > 0
                                    ? Theme.of(
                                        context,
                                      ).textTheme.bodyLarge?.color
                                    : Theme.of(context).colorScheme.primary,
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                      SizedBox(height: 28.h),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isOtpComplete ? _verifyOtp : null,
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 2.h),
                            child: Text(
                              "Verify",
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 18.sp,
                                  ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 18.h),
                      Center(
                        child: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          alignment: WrapAlignment.center,
                          children: [
                            Text(
                              "Didn't receive the code?",
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    fontSize: 15.sp,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                            TextButton(
                              onPressed: _secondsRemaining == 0
                                  ? _resendOtp
                                  : null,
                              child: Text(
                                "Resend",
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(
                                      color: _secondsRemaining == 0
                                          ? Theme.of(
                                              context,
                                            ).colorScheme.primary
                                          : Theme.of(context).disabledColor,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16.sp,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 52.h),
                      _TrustNote(),
                    ],
                  ).animate().fadeIn(
                    curve: Curves.easeOut,
                    duration: const Duration(milliseconds: 360),
                  ),
            ),
          ),
        ),
      ),
    );
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() {
      _secondsRemaining = _timerSeconds;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_secondsRemaining == 0) {
        timer.cancel();
        return;
      }

      setState(() {
        _secondsRemaining--;
      });
    });
  }

  void _handleOtpChanged(String value, int index) {
    if (_isError) {
      setState(() {
        _isError = false;
      });
    }

    if (value.length > 1) {
      _fillOtpFromPaste(value, index);
      return;
    }

    if (value.isNotEmpty && index < _otpLength - 1) {
      _focusNodes[index + 1].requestFocus();
    }

    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }

    setState(() {});
  }

  void _fillOtpFromPaste(String value, int startIndex) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return;

    if (_isError) {
      setState(() {
        _isError = false;
      });
    }

    for (var i = 0; i < digits.length && startIndex + i < _otpLength; i++) {
      final controller = _controllers[startIndex + i];
      controller.text = digits[i];
      controller.selection = TextSelection.fromPosition(
        TextPosition(offset: controller.text.length),
      );
    }

    final nextIndex = (startIndex + digits.length).clamp(0, _otpLength - 1);
    _focusNodes[nextIndex].requestFocus();
    if (_isOtpComplete) FocusScope.of(context).unfocus();
    setState(() {});
  }

  Future<void> _verifyOtp() async {
    FocusScope.of(context).unfocus();
    _showLoadingDialog(context);
    final response = await AuthServices.getVerification(_otpCode);
    print("response: $response");
    if (!mounted) return;
    Navigator.of(context).pop();
    final isSuccess = response['success'] ?? false; // Close the loading dialog
    if (!isSuccess) {
      ScaffoldMessenger.of(context).clearSnackBars();
      _controllers.forEach((controller) => controller.clear());
      _showOtpError(response['message'] ?? "Invalid OTP entered.");
      return;
    } else {
      _showOtpSuccess(
        response['message'] ?? "Email verified successfully.",
        context,
      );
    }
  }

  /// 902321 otp
  void _showLoadingDialog(BuildContext context) {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) {
        return AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              SizedBox(width: 20.w),
              Text(
                'Verifying...',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _resendOtp() {
    _startTimer();
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        dismissDirection: DismissDirection.horizontal,
        padding: EdgeInsets.all(12.w),
        backgroundColor: Theme.of(context).colorScheme.primary.withAlpha(70),
        content: Text(
          "A new OTP has been sent.",
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: Colors.white,
            fontSize: 16.sp,
          ),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showOtpError(String message) {
    setState(() {
      _isError = true;
    });
    _errorAnimationController.forward(from: 0).whenComplete(() {
      if (!mounted) return;
      setState(() {
        _isError = false;
      });
      _focusNodes.first.requestFocus();
    });

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        dismissDirection: DismissDirection.horizontal,
        padding: EdgeInsets.all(12.w),
        backgroundColor: Colors.redAccent,
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: Colors.white,
            fontSize: 16.sp,
          ),
        ),
      ),
    );
  }
}

void _showOtpSuccess(String message, BuildContext context) {
  ScaffoldMessenger.of(context).clearSnackBars();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      padding: EdgeInsets.all(12.w),
      backgroundColor: Theme.of(context).colorScheme.primary.withAlpha(70),
      content: Text(
        "Email verified successfully! Redirecting...",
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
          color: Colors.white,
          fontSize: 16.sp,
        ),
      ),
    ),
  );
  _nextScreen(context);
}

void _nextScreen(BuildContext context) {
  Navigator.pushReplacement(
    context,
    PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) {
        return Hiddendrawer();
      },
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(parent: animation, curve: Curves.ease);
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
    ),
  );
}

class _Header extends StatelessWidget {
  final String email;
  const _Header({required this.email});

  @override
  Widget build(BuildContext context) {
    final emailText = _makeEmailUnreadable(email);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 12.h),
        Text(
          "Verify your email",
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            fontSize: 30.sp,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 10.h),
        Text(
          "We sent a one-time code to $emailText. Enter it below to confirm it is really you.",
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontSize: 15.sp,
            height: 1.45,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _makeEmailUnreadable(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return email;

    final username = parts[0];
    final domain = parts[1];

    if (username.length <= 2) {
      return '*' * username.length + '@' + domain;
    }
    if (username.length <= 5) {
      return username[0] + '*' * (username.length - 1) + '@' + domain;
    }
    final visibleChars = 3;
    final hiddenChars = username.length - visibleChars;
    final hiddenPart = '*' * hiddenChars;

    return username.substring(0, visibleChars) + hiddenPart + '@' + domain;
  }
}

class _OtpFields extends StatelessWidget {
  final List<TextEditingController> controllers;
  final List<FocusNode> focusNodes;
  final void Function(String value, int index) onChanged;
  final bool hasError;
  final Animation<double> shakeAnimation;

  const _OtpFields({
    required this.controllers,
    required this.focusNodes,
    required this.onChanged,
    required this.hasError,
    required this.shakeAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: shakeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(shakeAnimation.value, 0),
          child: child,
        );
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(controllers.length, (index) {
          final borderColor = hasError
              ? Colors.redAccent
              : Theme.of(context).colorScheme.primary.withValues(alpha: 0.18);
          final focusedBorderColor = hasError
              ? Colors.redAccent
              : Theme.of(context).colorScheme.primary;

          return SizedBox(
            width: 48.w,
            height: 58.h,
            child: TextField(
              controller: controllers[index],
              focusNode: focusNodes[index],
              autofocus: index == 0,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              textInputAction: index == controllers.length - 1
                  ? TextInputAction.done
                  : TextInputAction.next,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 22.sp,
                fontWeight: FontWeight.w800,
              ),
              decoration: InputDecoration(
                counterText: "",
                hintText: "-",
                contentPadding: EdgeInsets.zero,
                filled: true,
                fillColor: hasError
                    ? Colors.redAccent.withValues(alpha: 0.08)
                    : Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.06),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14.r),
                  borderSide: BorderSide(color: borderColor, width: 1.4),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14.r),
                  borderSide: BorderSide(color: focusedBorderColor, width: 2),
                ),
              ),
              onChanged: (value) => onChanged(value, index),
            ),
          );
        }),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {
        Navigator.pushAndRemoveUntil(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const Registerscreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) =>
                    FadeTransition(opacity: animation, child: child),
          ),
          (route) => false,
        );
      },
      icon: Icon(
        Icons.arrow_back,
        size: 26.sp,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}

class _TrustNote extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18.r),
      ),
      child: Row(
        children: [
          Icon(
            Icons.lock_outline_rounded,
            color: Theme.of(context).colorScheme.secondary,
            size: 22.sp,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              "Your code expires soon. Never share it with anyone.",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).textTheme.bodyLarge?.color,
                fontSize: 13.5.sp,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
