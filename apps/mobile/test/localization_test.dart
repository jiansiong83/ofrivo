import 'package:flutter_test/flutter_test.dart';

import 'package:ofrivo_mobile/core/localization/app_localization.dart';

void main() {
  test('the three supported languages expose translated onboarding copy', () {
    const english = AppLocalizations(AppLanguage.english);
    const malay = AppLocalizations(AppLanguage.malay);
    const chinese = AppLocalizations(AppLanguage.chinese);

    expect(english.text('onboarding_title'), contains('Post a job'));
    expect(malay.text('onboarding_title'), contains('Siarkan kerja'));
    expect(chinese.text('onboarding_title'), contains('发布任务'));
    expect(AppLanguage.fromCode('ms'), AppLanguage.malay);
    expect(AppLanguage.fromCode('unknown'), isNull);
  });

  test('localization falls back to English for an unknown copy key', () {
    const strings = AppLocalizations(AppLanguage.chinese);
    expect(strings.text('missing_key'), 'missing_key');
  });

  test('business pages expose three-language copy with safe fallback', () {
    const english = AppLocalizations(AppLanguage.english);
    const malay = AppLocalizations(AppLanguage.malay);
    const chinese = AppLocalizations(AppLanguage.chinese);

    expect(english.business('received_bids'), 'Received bids');
    expect(malay.business('received_bids'), 'Tawaran diterima');
    expect(chinese.business('received_bids'), '收到的报价');
    expect(chinese.business('unknown_business_key'), 'unknown_business_key');
  });
}
