import 'package:flutter_test/flutter_test.dart';

import 'package:ofrivo_mobile/app.dart';

void main() {
  testWidgets('Ofrivo onboarding renders', (tester) async {
    await tester.pumpWidget(const OfrivoApp());
    await tester.pumpAndSettle();
    expect(find.text('Post a job.\nCompare offers.\nGet it done.'), findsOneWidget);
    expect(find.text('Explore fake-data preview'), findsOneWidget);
  });
}

