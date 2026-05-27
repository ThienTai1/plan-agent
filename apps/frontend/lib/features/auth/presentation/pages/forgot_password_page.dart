import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/theme/app_pallete.dart';
import 'package:frontend/features/auth/presentation/providers/auth_notifier.dart';
import 'package:frontend/features/auth/presentation/widgets/custom_text_field.dart';

class ForgotPasswordPage extends ConsumerStatefulWidget {
  static const String routeName = '/forgot-password';

  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSending = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSendResetLink() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSending = true);

    final error = await ref
        .read(authNotifierProvider.notifier)
        .sendPasswordResetEmail(
          email: _emailController.text.trim(),
        );

    if (!mounted) return;
    
    setState(() => _isSending = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: AppPallete.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reset link sent! Please check your email.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop(); // Go back to login after success
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPallete.getBackgroundColor(context),
      appBar: AppBar(
        title: const Text('Reset Password'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 48),
              Text(
                'Forgot your password?',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppPallete.getTextPrimary(context),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Enter the email address associated with your account and we\'ll send you a link to reset your password.',
                style: TextStyle(
                  fontSize: 16,
                  color: AppPallete.getTextSecondary(context),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),
              Form(
                key: _formKey,
                child: CustomTextField(
                  controller: _emailController,
                  hint: 'Email Address',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSending ? null : _handleSendResetLink,
                  child: _isSending
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppPallete.isDarkMode(context)
                                ? AppPallete.darkBackgroundColor
                                : Colors.white,
                          ),
                        )
                      : Text(
                          'Send Reset Link',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppPallete.isDarkMode(context)
                                ? AppPallete.darkBackgroundColor
                                : Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
