import 'package:flutter_test/flutter_test.dart';

import 'package:ofrivo_mobile/core/data/fake_data.dart';
import 'package:ofrivo_mobile/core/models/app_models.dart';
import 'package:ofrivo_mobile/features/customer/customer_job_models.dart';
import 'package:ofrivo_mobile/features/customer/customer_job_repository.dart';

void main() {
  test('job draft validates required customer details', () {
    final draft = JobDraft.demo();
    expect(draft.validate(), isNull);
    expect(draft.budgetAmount, 100);
    expect(draft.toPreviewJob().status, JobStatus.draft);
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

  test('fake customer repository persists publish and cancel state', () async {
    final repository = FakeCustomerJobRepository(fakeJobs);
    final saved = await repository.saveDraft(JobDraft.demo(), publish: true);
    expect(saved.status, JobStatus.open);
    expect((await repository.loadMyJobs()).first.id, saved.id);

    await repository.cancelJob(saved.id);
    final cancelled = (await repository.loadMyJobs()).firstWhere((job) => job.id == saved.id);
    expect(cancelled.status, JobStatus.cancelled);
  });
}
