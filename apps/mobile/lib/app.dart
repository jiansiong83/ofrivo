import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/localization/app_localization.dart';

class OfrivoApp extends ConsumerWidget {
  const OfrivoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(appLanguageProvider);
    return MaterialApp.router(
      title: 'Ofrivo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: language.locale,
      routerConfig: appRouter,
    );
  }
}
