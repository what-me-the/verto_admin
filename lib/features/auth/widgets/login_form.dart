import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../viewmodels/auth_viewmodel.dart';
import 'custom_text_field.dart';
import 'primary_button.dart';

/// Login form widget with validation and state management
class LoginForm extends StatefulWidget {
  final VoidCallback? onForgotPassword;
  final VoidCallback? onLoginSuccess;

  const LoginForm({super.key, this.onForgotPassword, this.onLoginSuccess});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Load saved email if remember me was checked
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authViewModel = context.read<AuthViewModel>();
      if (authViewModel.savedEmail != null) {
        _emailController.text = authViewModel.savedEmail!;
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    if (!EmailValidator.validate(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authViewModel = context.read<AuthViewModel>();
    final success = await authViewModel.signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (success && mounted) {
      widget.onLoginSuccess?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthViewModel>(
      builder: (context, authViewModel, child) {
        return Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Error message
              if (authViewModel.errorMessage != null) ...[
                _buildErrorMessage(authViewModel.errorMessage!),
                const SizedBox(height: 24),
              ],

              // Email field
              CustomTextField(
                label: 'Email Address',
                hintText: 'Enter your email',
                controller: _emailController,
                validator: _validateEmail,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                focusNode: _emailFocusNode,
                autofocus: authViewModel.savedEmail == null,
                prefixIcon: const Icon(
                  Icons.email_outlined,
                  color: AppColors.slateGray,
                ),
              ),
              const SizedBox(height: 20),

              // Password field
              CustomTextField(
                label: 'Password',
                hintText: 'Enter your password',
                controller: _passwordController,
                validator: _validatePassword,
                obscureText: true,
                textInputAction: TextInputAction.done,
                focusNode: _passwordFocusNode,
                autofocus: authViewModel.savedEmail != null,
                onSubmitted: _handleLogin,
                prefixIcon: const Icon(
                  Icons.lock_outline,
                  color: AppColors.slateGray,
                ),
              ),
              const SizedBox(height: 16),

              // Remember me and Forgot password row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Remember me checkbox
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: authViewModel.rememberMe,
                          onChanged: (value) {
                            authViewModel.setRememberMe(value ?? false);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('Remember me', style: AppTypography.bodySmall),
                    ],
                  ),

                  // Forgot password link
                  TextButton(
                    onPressed: widget.onForgotPassword,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text('Forgot Password?', style: AppTypography.link),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Login button
              PrimaryButton(
                text: 'Sign In',
                onPressed: _handleLogin,
                isLoading: authViewModel.isLoading,
                icon: Icons.login_rounded,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildErrorMessage(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.errorBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodySmall.copyWith(color: AppColors.error),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18, color: AppColors.error),
            onPressed: () {
              context.read<AuthViewModel>().clearError();
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}
