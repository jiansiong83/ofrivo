import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../shared/widgets/app_widgets.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) => _AuthScreen(title: 'Welcome back', buttonLabel: 'Log in', footer: 'New to Ofrivo?', footerAction: 'Create an account', onFooter: () => context.go('/register'));
}

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) => _AuthScreen(title: 'Create your account', buttonLabel: 'Register', footer: 'Already have an account?', footerAction: 'Log in', onFooter: () => context.go('/login'), includeName: true);
}

class _AuthScreen extends StatelessWidget {
  const _AuthScreen({required this.title, required this.buttonLabel, required this.footer, required this.footerAction, required this.onFooter, this.includeName = false});

  final String title;
  final String buttonLabel;
  final String footer;
  final String footerAction;
  final VoidCallback onFooter;
  final bool includeName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: ListView(padding: const EdgeInsets.all(24), children: [
        const SizedBox(height: 18),
        const CircleAvatar(radius: 32, child: Icon(Icons.handyman_outlined, size: 32)),
        const SizedBox(height: 24),
        Text(title, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        const Text('A clear way to get local jobs done.', style: TextStyle(color: Color(0xFF5B6870))),
        const SizedBox(height: 28),
        if (includeName) ...[const TextField(decoration: InputDecoration(labelText: 'Full name')), const SizedBox(height: 14)],
        const TextField(decoration: InputDecoration(labelText: 'Email address'), keyboardType: TextInputType.emailAddress),
        const SizedBox(height: 14),
        const TextField(decoration: InputDecoration(labelText: 'Password'), obscureText: true),
        const SizedBox(height: 22),
        PrimaryButton(label: buttonLabel, onPressed: () => context.go('/customer/home')),
        if (!includeName) Align(alignment: Alignment.centerRight, child: TextButton(onPressed: () => context.push('/forgot-password'), child: const Text('Forgot password?'))),
        const SizedBox(height: 20),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text(footer), TextButton(onPressed: onFooter, child: Text(footerAction))]),
      ]),
    );
  }
}

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) => AppScaffold(title: 'Reset password', body: ListView(padding: const EdgeInsets.all(24), children: [const Text('Enter your email and we will send reset instructions.'), const SizedBox(height: 20), const TextField(decoration: InputDecoration(labelText: 'Email address')), const SizedBox(height: 20), PrimaryButton(label: 'Send instructions', onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fake-data flow: email not sent.')))]));
}

