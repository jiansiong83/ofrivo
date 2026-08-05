import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/localization/app_localization.dart';
import '../../shared/widgets/app_widgets.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircleAvatar(
                  radius: 42, child: Icon(Icons.handyman_outlined, size: 42)),
              const SizedBox(height: 20),
              Text(
                'Ofrivo',
                style: Theme.of(context)
                    .textTheme
                    .displaySmall
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              const Text('Offers for every job'),
              const SizedBox(height: 32),
              PrimaryButton(
                  label: 'Start', onPressed: () => context.go('/onboarding')),
            ],
          ),
        ),
      ),
    );
  }
}

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _LocalizedOnboardingScreen();
  }
}

class _LocalizedOnboardingScreen extends ConsumerWidget {
  const _LocalizedOnboardingScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations(ref.watch(appLanguageProvider));
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Align(
                alignment: Alignment.topRight,
                child: LanguagePicker(showLabel: true),
              ),
              const Spacer(),
              const Icon(Icons.compare_arrows_rounded, size: 64),
              const SizedBox(height: 24),
              Text(
                strings.text('onboarding_title'),
                style: Theme.of(context)
                    .textTheme
                    .displaySmall
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 16),
              Text(
                strings.text('onboarding_description'),
                style: const TextStyle(fontSize: 17, color: Color(0xFF5B6870)),
              ),
              const Spacer(),
              PrimaryButton(
                  label: strings.text('login'),
                  onPressed: () => context.go('/login')),
              const SizedBox(height: 12),
              SecondaryButton(
                label: strings.text('create_account'),
                icon: Icons.person_add_outlined,
                onPressed: () => context.go('/register'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.go('/customer/home'),
                child: Text(strings.text('explore_preview')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
