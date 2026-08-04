import 'package:flutter_test/flutter_test.dart';

import 'package:ofrivo_mobile/core/diagnostics/app_crash_reporter.dart';

void main() {
  tearDown(AppCrashReporter.clear);

  test('crash reporter keeps the last error for a safe diagnostic handoff', () {
    final error = StateError('simulated crash');
    final stack = StackTrace.current;

    AppCrashReporter.record(error, stack);

    expect(AppCrashReporter.lastError, same(error));
    expect(AppCrashReporter.lastStackTrace, same(stack));
    AppCrashReporter.clear();
    expect(AppCrashReporter.lastError, isNull);
  });
}
