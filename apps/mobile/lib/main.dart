import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui' as ui;

import 'app.dart';
import 'core/config/app_config.dart';
import 'core/diagnostics/app_crash_reporter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterError.onError = (details) {
    AppCrashReporter.record(details.exception, details.stack);
    FlutterError.presentError(details);
  };
  ui.PlatformDispatcher.instance.onError = (error, stackTrace) {
    AppCrashReporter.record(error, stackTrace);
    return false;
  };
  await AppBootstrap.initialize();
  runApp(const ProviderScope(child: OfrivoApp()));
}
