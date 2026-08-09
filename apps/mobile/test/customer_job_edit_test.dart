import 'package:flutter_test/flutter_test.dart';

import 'package:ofrivo_mobile/core/data/fake_data.dart';
import 'package:ofrivo_mobile/core/models/app_models.dart';
import 'package:ofrivo_mobile/features/customer/customer_job_models.dart';
import 'package:ofrivo_mobile/features/customer/customer_job_repository.dart';

void main() {
  test('fake repository validates before writing a job', () async {
    final repository = FakeCustomerJobRepository(fakeJobs);
    final invalid = JobDraft(
      category: jobCategoryOptions.first,
      area: jobAreaOptions.first,
      title: 'Fix leaking tap',
      description: 'Water is leaking from the kitchen tap.',
      fullAddress: '12 Example Street, Mount Austin, Johor Bahru',
      contactPhone: '+60 12 000 0101',
      contactWhatsapp: '',
      budget: '100',
      timeWindow: 'Fri, 7 Aug, 5:00 PM - 2:00 PM',
      scheduledAt: DateTime(2026, 8, 7, 17),
      scheduledEndAt: DateTime(2026, 8, 7, 14),
      urgent: false,
    );

    await expectLater(
      repository.saveDraft(invalid, publish: true),
      throwsA(isA<StateError>()),
    );
    expect(await repository.loadMyJobs(), hasLength(fakeJobs.length));
  });

  test('customer can edit draft/open jobs but not assigned jobs', () async {
    final repository = FakeCustomerJobRepository(fakeJobs);
    final openJob = (await repository.loadMyJobs())
        .firstWhere((job) => job.status == JobStatus.open);
    final openDraft = JobDraft.fromJob(openJob);
    final updated = await repository.updateJob(
      openJob.id,
      JobDraft(
        jobId: openDraft.jobId,
        category: openDraft.category,
        area: openDraft.area,
        title: 'Updated service request',
        description: openDraft.description,
        fullAddress: openDraft.fullAddress,
        contactPhone: openDraft.contactPhone,
        contactWhatsapp: openDraft.contactWhatsapp,
        budget: openDraft.budget,
        timeWindow: openDraft.timeWindow,
        scheduledAt: openDraft.scheduledAt,
        scheduledEndAt: openDraft.scheduledEndAt,
        urgent: openDraft.urgent,
      ),
      publish: false,
    );
    expect(updated.title, 'Updated service request');
    expect(updated.status, JobStatus.open);

    final assignedJob = (await repository.loadMyJobs())
        .firstWhere((job) => job.status == JobStatus.assigned);
    await expectLater(
      repository.updateJob(assignedJob.id, JobDraft.fromJob(assignedJob),
          publish: false),
      throwsA(isA<StateError>()),
    );
  });
}
