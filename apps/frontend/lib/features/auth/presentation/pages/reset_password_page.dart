import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/theme/app_pallete.dart';
import 'package:frontend/features/auth/presentation/providers/auth_notifier.dart';
import 'package:frontend/features/auth/presentation/widgets/custom_text_field.dart';

class ResetPasswordPage extends ConsumerStatefulWidget {
  static const String routeName = '/reset-password';

  const ResetPasswordPage({super.key});

  @override
  ConsumerState<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends ConsumerState<ResetPasswordPage> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isUpdating = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleUpdatePassword() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isUpdating = true);

    final error = await ref
        .read(authNotifierProvider.notifier)
        .updatePassword(
          newPassword: _passwordController.text.trim(),
        );

    if (!mounted) return;
    
    setState(() => _isUpdating = false);

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
          content: Text('Password updated successfully!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      // After successful reset, Supabase usually logs the user in.
      // We can redirect to Home.
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPallete.getBackgroundColor(context),
      appBar: AppBar(
        title: const Text('New Password'),
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
                'Create new password',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppPallete.getTextPrimary(context),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Your new password must be different from previous used passwords.',
                style: TextStyle(
                  fontSize: 16,
                  color: AppPallete.getTextSecondary(context),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    CustomTextField(
                      controller: _passwordController,
                      hint: 'New Password',
                      icon: Icons.lock_outline,
                      isPassword: true,
                      obscureText: _obscurePassword,
                      onTogglePassword: () => setState(() => _obscurePassword = !_obscurePassword),
                      validator: (v) {
                        if (v == null || v.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _confirmPasswordController,
                      hint: 'Confirm Password',
                      icon: Icons.lock_reset_outlined,
                      isPassword: true,
                      obscureText: _obscurePassword,
                      onTogglePassword: () => setState(() => _obscurePassword = !_obscurePassword),
                      validator: (v) {
                        if (v != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isUpdating ? null : _handleUpdatePassword,
                  child: _isUpdating
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
                          'Reset Password',
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
