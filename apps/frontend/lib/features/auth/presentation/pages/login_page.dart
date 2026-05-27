import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/auth/presentation/providers/auth_notifier.dart';
import 'package:frontend/features/auth/presentation/pages/register_page.dart';
import 'package:frontend/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:frontend/features/home/presentation/pages/home_page.dart';
import 'package:frontend/features/auth/presentation/widgets/custom_text_field.dart';
import 'package:frontend/core/theme/app_pallete.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:frontend/core/common/widgets/page_transitions.dart';
import 'package:frontend/core/common/widgets/app_logo.dart';

class LoginScreen extends ConsumerStatefulWidget {
  static const String routeName = '/login';

  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (_formKey.currentState!.validate()) {
      ref
          .read(authNotifierProvider.notifier)
          .login(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
    }
  }

  void _navigateToForgotPassword() {
    Navigator.of(context).pushNamed(ForgotPasswordPage.routeName);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authNotifierProvider, (previous, next) {
      next.whenOrNull(
        error: (error, stackTrace) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Login failed: $error'),
              backgroundColor: AppPallete.errorColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        data: (user) {
          if (user != null) {
            Navigator.of(context).pushAndRemoveUntil(
              FadeSlidePageRoute(page: const HomeScreen()),
              (route) => false,
            );
          }
        },
      );
    });

    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      backgroundColor: AppPallete.getBackgroundColor(context),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 80),
              const AppLogo(size: 64),
              const SizedBox(height: 32),
              Text(
                'Welcome back',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: AppPallete.getTextPrimary(context),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    'New here? ',
                    style: TextStyle(
                      color: AppPallete.getTextSecondary(context),
                      fontSize: 15,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(
                      context,
                    ).pushNamed(RegisterScreen.routeName),
                    child: Text(
                      'Create an account',
                      style: TextStyle(
                        color: AppPallete.getTextPrimary(context),
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 48),
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomTextField(
                      controller: _emailController,
                      hint: 'Email Address',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _passwordController,
                      hint: 'Password',
                      icon: Icons.lock_outline,
                      isPassword: true,
                      obscureText: _obscurePassword,
                      onTogglePassword: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _navigateToForgotPassword,
                        child: Text(
                          'Forgot password?',
                          style: TextStyle(
                            color: AppPallete.getTextSecondary(context),
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _handleLogin,
                        child: isLoading
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
                                'Sign in',
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
              const SizedBox(height: 40),
              Row(
                children: [
                  Expanded(
                    child: Divider(color: AppPallete.getBorderColor(context)),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'or',
                      style: TextStyle(
                        color: AppPallete.getTextSecondary(context),
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Divider(color: AppPallete.getBorderColor(context)),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: isLoading
                      ? null
                      : () => ref
                          .read(authNotifierProvider.notifier)
                          .loginWithGoogle(),

                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SvgPicture.asset(
                        'assets/icons/google_logo.svg',
                        height: 20,
                        width: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Continue with Google',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppPallete.getTextPrimary(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 60),
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: TextStyle(
                        color: AppPallete.getTextSecondary(context),
                        fontSize: 12,
                        height: 1.6,
                      ),
                      children: [
                        const TextSpan(
                          text: "By signing in, you agree to our ",
                        ),
                        TextSpan(
                          text: 'Terms of Service',
                          style: TextStyle(
                            color: AppPallete.getTextPrimary(context),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const TextSpan(text: ' and '),
                        TextSpan(
                          text: 'Privacy Policy',
                          style: TextStyle(
                            color: AppPallete.getTextPrimary(context),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const TextSpan(text: '.'),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
