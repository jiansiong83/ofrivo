import 'package:flutter_test/flutter_test.dart';

import 'package:ofrivo_mobile/core/models/app_models.dart';
import 'package:ofrivo_mobile/features/customer/customer_job_repository.dart';

void main() {
  Job job(String id, DateTime expiresAt) => Job(
        id: id,
        title: 'Test job',
        category: 'Plumbing',
        area: 'Mount Austin',
        budget: 100,
        time: 'Today',
        status: JobStatus.open,
        bidCount: 0,
        description: 'A job for expiry testing.',
        expiresAt: expiresAt,
      );

  test('fake expiry changes only due open jobs and emits one count', () async {
    final repository = FakeCustomerJobRepository([
      job('due-job', DateTime(2026, 8, 1)),
      job('future-job', DateTime(2026, 8, 10)),
    ]);

    final count = await repository.expireOpenJobs(now: DateTime(2026, 8, 5));
    final jobs = await repository.loadMyJobs();

    expect(count, 1);
    expect(jobs.firstWhere((item) => item.id == 'due-job').status,
        JobStatus.expired);
    expect(jobs.firstWhere((item) => item.id == 'future-job').status,
        JobStatus.open);
  });
}
