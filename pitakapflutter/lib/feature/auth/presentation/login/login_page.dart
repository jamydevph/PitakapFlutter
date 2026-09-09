import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pitakapflutter/core/common/common.dart';
import 'package:pitakapflutter/core/resources/constants.dart';
import 'package:pitakapflutter/core/resources/strings.dart';
import 'package:pitakapflutter/core/router/app_routes.dart';
import 'package:pitakapflutter/core/theme/app_theme.dart';
import 'package:pitakapflutter/core/utils/validators.dart';
import 'package:pitakapflutter/core/widgets/app_logo.dart';
import 'package:pitakapflutter/feature/auth/domain/usecases/login_user_usecase.dart';
import 'package:pitakapflutter/feature/auth/presentation/login/providers/login_controller.dart';
import 'package:pitakapflutter/feature/auth/presentation/login/providers/login_state.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _passwordFocusNode = FocusNode();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  void _onSignIn() {
    FocusScope.of(context).unfocus();

    if (_formKey.currentState?.validate() != true) return;

    ref.read(loginControllerProvider.notifier).submit(
          LoginUseCaseParams(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          ),
        );
  }

  void _onGoogleSignIn() {
    FocusScope.of(context).unfocus();
    ref.read(loginControllerProvider.notifier).submitGoogle();
  }

  void _openSignUp() => context.push(AppRoutes.signUp);

  void _openForgotPassword() {
    final email = _emailController.text.trim();
    final location = Uri(
      path: AppRoutes.forgotPassword,
      queryParameters: email.isEmpty
          ? null
          : {AppRoutes.emailQueryParam: email},
    ).toString();

    context.push(location);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loginState = ref.watch(loginControllerProvider).value;
    final isBusy = loginState is LoginLoadingState ||
        loginState is LoginGoogleLoadingState;

    ref.listen(loginControllerProvider, (previous, next) {
      final state = next.value;
      if (state is LoginFailedState) {
        CommonSnackBar.showError(context, state.message);
        ref.read(loginControllerProvider.notifier).reset();
      }
    });

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppSpacing.xl),
                  const Center(child: AppLogo(size: 72)),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    Strings.appName,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineLarge,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    Strings.loginTagline,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  CommonTextField(
                    controller: _emailController,
                    label: Strings.emailLabel,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    enabled: !isBusy,
                    validator: Validators.email,
                    onFieldSubmitted: (_) => _passwordFocusNode.requestFocus(),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  CommonPasswordField(
                    controller: _passwordController,
                    focusNode: _passwordFocusNode,
                    enabled: !isBusy,
                    validator: Validators.password,
                    onFieldSubmitted: (_) => _onSignIn(),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: isBusy ? null : _openForgotPassword,
                      child: const Text(Strings.loginForgotPassword),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  CommonPrimaryButton(
                    label: Strings.loginSignIn,
                    onPressed: _onSignIn,
                    isLoading: loginState is LoginLoadingState,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const _OrDivider(),
                  const SizedBox(height: AppSpacing.md),
                  _GoogleButton(
                    onPressed: isBusy ? null : _onGoogleSignIn,
                    isLoading: loginState is LoginGoogleLoadingState,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  CommonRichLinkText(
                    text: Strings.loginNoAccount,
                    linkText: Strings.loginSignUpLink,
                    onTap: _openSignUp,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(Strings.loginOr, style: theme.textTheme.bodySmall),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}

class _GoogleButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;

  const _GoogleButton({required this.onPressed, required this.isLoading});

  static const double googleLogoSize = 18;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? const CommonLoader(size: 20)
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  Constants.googleLogoAsset,
                  width: googleLogoSize,
                  height: googleLogoSize,
                  filterQuality: FilterQuality.medium,
                ),
                const SizedBox(width: AppSpacing.sm),
                const Text(Strings.loginContinueWithGoogle),
              ],
            ),
    );
  }
}
