import 'package:flutter_test/flutter_test.dart';

import 'package:ofrivo_mobile/features/provider/provider_application_models.dart';
import 'package:ofrivo_mobile/features/provider/provider_application_repository.dart';
import 'package:ofrivo_mobile/core/models/service_options.dart';

void main() {
  test('provider application draft validates profile, services, and documents',
      () {
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
    final repository = FakeProviderApplicationRepository(
        initialStatus: ProviderApplicationStatus.notApplied);
    expect(await repository.load(), isNull);
    final application =
        await repository.submit(ProviderApplicationDraft.demo());
    expect(application.status, ProviderApplicationStatus.pending);
    expect((await repository.load())?.displayName, 'Ahmad Plumbing');
  });
  test('approved categories stay approved while new categories remain pending',
      () async {
    final repository = FakeProviderApplicationRepository();
    final electrical = serviceCategoryOptions.firstWhere(
        (item) => item.id == '00000000-0000-0000-0000-000000000202');
    final application = await repository.submitCategoryChanges([
      serviceCategoryOptions.first,
      serviceCategoryOptions.last,
      electrical,
    ]);
    final byId = {
      for (final item in application.categorySelections) item.category.id: item,
    };
    expect(byId['00000000-0000-0000-0000-000000000201']?.status,
        ProviderCategoryStatus.approved);
    expect(byId['00000000-0000-0000-0000-000000000206']?.status,
        ProviderCategoryStatus.approved);
    expect(byId['00000000-0000-0000-0000-000000000202']?.status,
        ProviderCategoryStatus.pending);
  });

  test('profile edits and availability are persisted in fake mode', () async {
    final repository = FakeProviderApplicationRepository();
    final area = serviceAreaOptions.last;
    final updated = await repository.updateProfile(
      displayName: 'Updated Fixers',
      bio: 'A longer profile for local home repairs.',
      phone: '+60123456789',
      whatsapp: '+60123456789',
      areas: [area],
      workPhotoPaths: const ['demo/work-3.jpg'],
    );
    expect(updated.displayName, 'Updated Fixers');
    expect(updated.phone, '+60123456789');
    expect(updated.areas.single.id, area.id);
    expect((await repository.setAvailability(false)).isAvailable, isFalse);
    expect((await repository.load())?.isAvailable, isFalse);
  });
}
