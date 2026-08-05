import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ofrivo_mobile/core/data/fake_data.dart';
import 'package:ofrivo_mobile/shared/widgets/app_widgets.dart';

void main() {
  test('approved demo providers expose portfolio items', () {
    expect(fakeProvider.portfolioUrls, hasLength(2));
    expect(
        fakeProviderProfiles
            .every((profile) => profile.verification.name == 'approved'),
        isTrue);
  });

  testWidgets('portfolio gallery renders safe local placeholders',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: PortfolioGallery(urls: ['demo/work-1.jpg', 'demo/work-2.jpg']),
      ),
    ));

    expect(find.text('Portfolio'), findsOneWidget);
    expect(find.text('Work photo 1'), findsOneWidget);
    expect(find.text('Work photo 2'), findsOneWidget);
  });
}
