import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'auth_controller.dart';
import '../../shared/widgets/app_widgets.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) => _AuthScreen(
      title: 'Welcome back',
      buttonLabel: 'Log in',
      footer: 'New to Ofrivo?',
      footerAction: 'Create an account',
      onFooter: () => context.go('/register'));
}

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) => _AuthScreen(
      title: 'Create your account',
      buttonLabel: 'Register',
      footer: 'Already have an account?',
      footerAction: 'Log in',
      onFooter: () => context.go('/login'),
      includeName: true);
}

class _AuthScreen extends ConsumerStatefulWidget {
  const _AuthScreen(
      {required this.title,
      required this.buttonLabel,
      required this.footer,
      required this.footerAction,
      required this.onFooter,
      this.includeName = false});

  final String title;
  final String buttonLabel;
  final String footer;
  final String footerAction;
  final VoidCallback onFooter;
  final bool includeName;

  @override
  ConsumerState<_AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<_AuthScreen> {
  late final TextEditingController nameController;
  late final TextEditingController emailController;
  late final TextEditingController passwordController;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController();
    emailController = TextEditingController();
    passwordController = TextEditingController();
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final controller = ref.read(authControllerProvider.notifier);
    final success = widget.includeName
        ? await controller.register(
            fullName: nameController.text,
            email: emailController.text,
            password: passwordController.text)
        : await controller.signIn(
            email: emailController.text, password: passwordController.text);
    if (!mounted) return;
    final auth = ref.read(authControllerProvider);
    if (success) {
      context.go('/customer/home');
    } else if (auth.info != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(auth.info!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    return Scaffold(
      appBar: AppBar(),
      body: ListView(padding: const EdgeInsets.all(24), children: [
        const SizedBox(height: 18),
        const CircleAvatar(
            radius: 32, child: Icon(Icons.handyman_outlined, size: 32)),
        const SizedBox(height: 24),
        Text(widget.title,
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        const Text('A clear way to get local jobs done.',
            style: TextStyle(color: Color(0xFF5B6870))),
        const SizedBox(height: 28),
        if (widget.includeName) ...[
          TextField(
              controller: nameController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Full name')),
          const SizedBox(height: 14)
        ],
        TextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(labelText: 'Email address')),
        const SizedBox(height: 14),
        TextField(
            controller: passwordController,
            obscureText: true,
            onSubmitted: (_) => _submit(),
            decoration: const InputDecoration(labelText: 'Password')),
        if (auth.error != null) ...[
          const SizedBox(height: 12),
          Text(auth.error!, style: const TextStyle(color: Color(0xFFB42318)))
        ],
        const SizedBox(height: 22),
        PrimaryButton(
            label: auth.isLoading ? 'Please wait…' : widget.buttonLabel,
            onPressed: auth.isLoading ? null : _submit),
        if (!widget.includeName)
          Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                  onPressed: auth.isLoading
                      ? null
                      : () => context.push('/forgot-password'),
                  child: const Text('Forgot password?'))),
        if (!widget.includeName)
          Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                  onPressed: auth.isLoading
                      ? null
                      : () => context.push('/phone-login'),
                  child: const Text('Use phone OTP instead'))),
        const SizedBox(height: 20),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(widget.footer),
          TextButton(
              onPressed: auth.isLoading ? null : widget.onFooter,
              child: Text(widget.footerAction))
        ]),
        const SizedBox(height: 12),
        const Text(
            'No Supabase keys? This build uses local demo mode and does not contact a backend.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF5B6870), fontSize: 12)),
      ]),
    );
  }
}

class PhoneOtpScreen extends ConsumerStatefulWidget {
  const PhoneOtpScreen({super.key});

  @override
  ConsumerState<PhoneOtpScreen> createState() => _PhoneOtpScreenState();
}

class _PhoneOtpScreenState extends ConsumerState<PhoneOtpScreen> {
  final phoneController = TextEditingController();
  final codeController = TextEditingController();
  bool codeRequested = false;

  @override
  void dispose() {
    phoneController.dispose();
    codeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final controller = ref.read(authControllerProvider.notifier);
    if (!codeRequested) {
      final error = await controller.requestPhoneOtp(phoneController.text);
      if (!mounted) return;
      if (error == null) setState(() => codeRequested = true);
      return;
    }
    final success = await controller.verifyPhoneOtp(
        phone: phoneController.text, token: codeController.text);
    if (!mounted) return;
    if (success) context.go('/customer/home');
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    return AppScaffold(
      title: 'Phone sign in',
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
              'Use your phone number to receive a one-time verification code.'),
          const SizedBox(height: 20),
          TextField(
            controller: phoneController,
            enabled: !codeRequested && !auth.isLoading,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
                labelText: 'Phone number', hintText: '+60120000101'),
          ),
          if (codeRequested) ...[
            const SizedBox(height: 14),
            TextField(
              controller: codeController,
              enabled: !auth.isLoading,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              decoration: const InputDecoration(labelText: 'Verification code'),
            ),
          ],
          if (auth.error != null) ...[
            const SizedBox(height: 4),
            Text(auth.error!, style: const TextStyle(color: Color(0xFFB42318))),
          ],
          if (auth.info != null) ...[
            const SizedBox(height: 4),
            Text(auth.info!, style: const TextStyle(color: Color(0xFF067647))),
          ],
          const SizedBox(height: 20),
          PrimaryButton(
            label: auth.isLoading
                ? 'Please wait…'
                : (codeRequested ? 'Verify code' : 'Send code'),
            onPressed: auth.isLoading ? null : _submit,
          ),
          if (codeRequested)
            Align(
              alignment: Alignment.center,
              child: TextButton(
                onPressed: auth.isLoading
                    ? null
                    : () => setState(() {
                          codeRequested = false;
                          codeController.clear();
                        }),
                child: const Text('Change phone number'),
              ),
            ),
          const SizedBox(height: 14),
          Text(
            ref.read(authRepositoryProvider).isDemoMode
                ? 'Demo mode code: 123456'
                : 'The code expires according to your Supabase Auth settings.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF5B6870), fontSize: 12),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Prefer email?'),
              TextButton(
                  onPressed: auth.isLoading ? null : () => context.go('/login'),
                  child: const Text('Log in')),
            ],
          ),
        ],
      ),
    );
  }
}

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final emailController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    await ref
        .read(authControllerProvider.notifier)
        .resetPassword(emailController.text);
    if (!mounted) return;
    final auth = ref.read(authControllerProvider);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(auth.error ?? auth.info ?? 'Reset instructions sent.')));
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    return AppScaffold(
        title: 'Reset password',
        body: ListView(padding: const EdgeInsets.all(24), children: [
          const Text('Enter your email and we will send reset instructions.'),
          const SizedBox(height: 20),
          TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email address')),
          const SizedBox(height: 20),
          PrimaryButton(
              label: auth.isLoading ? 'Please wait…' : 'Send instructions',
              onPressed: auth.isLoading ? null : _submit)
        ]));
  }
}
