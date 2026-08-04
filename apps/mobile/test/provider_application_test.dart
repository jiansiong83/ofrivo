import 'package:flutter_test/flutter_test.dart';

import 'package:ofrivo_mobile/features/provider/provider_application_models.dart';
import 'package:ofrivo_mobile/features/provider/provider_application_repository.dart';

void main() {
  test('provider application draft validates profile, services, and documents', () {
    final draft = ProviderApplicationDraft.demo();
    expect(draft.validate(), isNull);
    expect(draft.categoryIds, hasLength(2));
    expect(draft.areaIds, hasLength(2));
  });

  test('provider application draft requires identity evidence', () {
    const draft = ProviderApplicationDraft(
      displayName: 'Local Fix',
      bio: 'A local home repair service.',
      categories: [],
      areas: [],
      icFrontPath: null,
      icBackPath: null,
      selfiePath: null,
    );
    expect(draft.validate(), isNotNull);
  });

  test('fake repository moves a submitted application to pending', () async {
    final repository = FakeProviderApplicationRepository(initialStatus: ProviderApplicationStatus.notApplied);
    expect(await repository.load(), isNull);
    final application = await repository.submit(ProviderApplicationDraft.demo());
    expect(application.status, ProviderApplicationStatus.pending);
    expect((await repository.load())?.displayName, 'Ahmad Plumbing');
  });
}
