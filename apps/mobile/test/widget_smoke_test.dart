import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ofrivo_mobile/app.dart';
import 'package:ofrivo_mobile/shared/widgets/app_widgets.dart';

void main() {
  testWidgets('Ofrivo onboarding renders', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: OfrivoApp()));
    await tester.pumpAndSettle();
    expect(find.text('Post a job.\nCompare offers.\nGet it done.'), findsOneWidget);
    expect(find.text('Explore fake-data preview'), findsOneWidget);
  });

  testWidgets('error and offline states expose a retry action', (tester) async {
    var retries = 0;
    await tester.pumpWidget(MaterialApp(
      home: ErrorState(onRetry: () => retries++),
    ));
    await tester.tap(find.text('Try again'));
    expect(retries, 1);

    await tester.pumpWidget(const MaterialApp(home: OfflineState()));
    expect(find.text('You are offline'), findsOneWidget);
  });
}
