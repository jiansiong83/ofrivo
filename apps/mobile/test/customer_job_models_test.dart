import 'package:flutter_test/flutter_test.dart';

import 'package:ofrivo_mobile/core/data/fake_data.dart';
import 'package:ofrivo_mobile/core/models/app_models.dart';
import 'package:ofrivo_mobile/features/customer/customer_job_models.dart';
import 'package:ofrivo_mobile/features/customer/customer_job_repository.dart';

void main() {
  test(
      'scheduled ranges format from local DateTime values with legacy fallback',
      () {
    expect(
      formatJobTimeWindow(
        DateTime(2026, 8, 10, 18),
        DateTime(2026, 8, 10, 19),
        'Flexible',
      ),
      'Mon, 10 Aug, 6:00 PM - 7:00 PM',
    );
    expect(formatJobTimeWindow(null, null, 'Flexible'), 'Flexible');
  });

  test('job draft validates required customer details', () {
    final draft = JobDraft.demo();
    expect(draft.validate(), isNull);
    expect(draft.budgetAmount, 100);
    expect(draft.toPreviewJob().status, JobStatus.draft);
  });

  test('job draft carries a selected time range into the preview job', () {
    final start = DateTime(2026, 8, 7, 14);
    final end = DateTime(2026, 8, 7, 17);
    final draft = JobDraft(
      category: jobCategoryOptions.first,
      area: jobAreaOptions.first,
      title: 'Fix leaking tap',
      description: 'Water is leaking from the kitchen tap.',
      fullAddress: '12 Example Street, Mount Austin, Johor Bahru',
      contactPhone: '+60 12 000 0101',
      contactWhatsapp: '+60 12 000 0101',
      budget: '100',
      timeWindow: 'Fri, 7 Aug, 2:00 PM - 5:00 PM',
      scheduledAt: start,
      scheduledEndAt: end,
      urgent: false,
    );

    expect(draft.validate(), isNull);
    final preview = draft.toPreviewJob();
    expect(preview.scheduledAt, start);
    expect(preview.scheduledEndAt, end);
  });

  test('job draft rejects an end time before the start time', () {
    final draft = JobDraft(
      category: jobCategoryOptions.first,
      area: jobAreaOptions.first,
      title: 'Fix leaking tap',
      description: 'Water is leaking from the kitchen tap.',
      fullAddress: '12 Example Street, Mount Austin, Johor Bahru',
      contactPhone: '+60 12 000 0101',
      contactWhatsapp: '+60 12 000 0101',
      budget: '100',
      timeWindow: 'Fri, 7 Aug, 5:00 PM - 2:00 PM',
      scheduledAt: DateTime(2026, 8, 7, 17),
      scheduledEndAt: DateTime(2026, 8, 7, 14),
      urgent: false,
    );

    expect(
      draft.validate(),
      'End time must be later on the same day as the start time.',
    );
  });
  test('job draft rejects same-time and overnight ranges', () {
    JobDraft draftFor(DateTime start, DateTime end) => JobDraft(
          category: jobCategoryOptions.first,
          area: jobAreaOptions.first,
          title: 'Fix leaking tap',
          description: 'Water is leaking from the kitchen tap.',
          fullAddress: '12 Example Street, Mount Austin, Johor Bahru',
          contactPhone: '+60 12 000 0101',
          contactWhatsapp: '+60 12 000 0101',
          budget: '100',
          timeWindow: 'Fri, 7 Aug, 10:00 PM - 10:00 PM',
          scheduledAt: start,
          scheduledEndAt: end,
          urgent: false,
        );

    expect(
      draftFor(DateTime(2026, 8, 7, 10), DateTime(2026, 8, 7, 10)).validate(),
      'End time must be later on the same day as the start time.',
    );
    expect(
      draftFor(DateTime(2026, 8, 7, 22), DateTime(2026, 8, 8, 1)).validate(),
      'End time must be later on the same day as the start time.',
    );
  });
  test('job draft rejects incomplete or oversized requests', () {
    final draft = JobDraft(
      category: jobCategoryOptions.first,
      area: jobAreaOptions.first,
      title: 'x',
      description: '',
      fullAddress: '',
      contactPhone: '',
      contactWhatsapp: '',
      budget: '0',
      timeWindow: '',
      urgent: false,
      photoPaths: List<String>.filled(6, 'photo.jpg'),
    );
    expect(draft.validate(), isNotNull);
  });

  test('fake customer repository scopes seed jobs by account', () async {
    final newAccount = FakeCustomerJobRepository(fakeJobs,
        userId: 'demo-user-new-222-222-com');
    expect(await newAccount.loadMyJobs(), isEmpty);

    final demoAccount = FakeCustomerJobRepository(fakeJobs,
        userId: 'demo-user-customer-example-test');
    expect(await demoAccount.loadMyJobs(), hasLength(fakeJobs.length));
  });
  test('fake customer repository persists publish and cancel state', () async {
    final repository = FakeCustomerJobRepository(fakeJobs);
    final saved = await repository.saveDraft(JobDraft.demo(), publish: true);
    expect(saved.status, JobStatus.open);
    expect((await repository.loadMyJobs()).first.id, saved.id);

    await repository.cancelJob(saved.id);
    final cancelled =
        (await repository.loadMyJobs()).firstWhere((job) => job.id == saved.id);
    expect(cancelled.status, JobStatus.cancelled);
  });
}
