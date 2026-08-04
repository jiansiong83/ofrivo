import 'package:flutter_test/flutter_test.dart';

import 'package:ofrivo_mobile/core/models/app_models.dart';
import 'package:ofrivo_mobile/features/job_lifecycle/job_lifecycle_models.dart';
import 'package:ofrivo_mobile/features/job_lifecycle/job_lifecycle_repository.dart';

void main() {
  Job assignedJob({JobStatus status = JobStatus.assigned}) => Job(
        id: 'job-lifecycle',
        title: 'Repair a sink',
        category: 'Plumbing',
        area: 'Mount Austin',
        budget: 120,
        time: 'Today',
        status: status,
        bidCount: 1,
        description: 'The sink is leaking.',
        acceptedBidId: 'bid-lifecycle',
      );

  const acceptedBid = Bid(
    id: 'bid-lifecycle',
    jobId: 'job-lifecycle',
    providerName: 'Provider One',
    providerCategory: 'Plumbing',
    amount: 110,
    availableAt: 'Today',
    inclusions: 'Labour',
    exclusions: '',
    status: BidStatus.accepted,
    rating: 4.8,
    completedJobs: 20,
    providerId: 'provider-1',
  );

  test('accepted provider can start, complete, review, and report', () async {
    final repository = FakeJobLifecycleRepository(
        initialJobs: [assignedJob()],
        initialBids: [acceptedBid],
        role: AppMode.provider,
        providerId: 'provider-1');

    expect((await repository.startJob('job-lifecycle')).status,
        JobStatus.inProgress);
    expect((await repository.completeJob('job-lifecycle')).status,
        JobStatus.completed);
    final review = await repository.submitReview(
        jobId: 'job-lifecycle',
        draft: const ReviewDraft(rating: 5, comment: 'Clear communication.'));
    expect(review.revieweeId, 'customer-demo');
    final report = await repository.submitReport(
        jobId: 'job-lifecycle',
        draft: const ReportDraft(
            reasonCode: 'Other',
            description: 'A follow-up detail for safety review.'));
    expect(report.status, 'open');
    expect(await repository.loadEvents('job-lifecycle'), hasLength(2));
  });

  test('customer can complete an in-progress job but cannot start it',
      () async {
    final repository = FakeJobLifecycleRepository(
        initialJobs: [assignedJob(status: JobStatus.inProgress)],
        initialBids: [acceptedBid],
        role: AppMode.customer);

    expect(() => repository.startJob('job-lifecycle'), throwsStateError);
    expect((await repository.completeJob('job-lifecycle')).status,
        JobStatus.completed);
    expect(
        (await repository.submitReview(
                jobId: 'job-lifecycle',
                draft: const ReviewDraft(rating: 4, comment: 'Good work.')))
            .revieweeId,
        'provider-1');
  });

  test('review and report drafts enforce their input boundaries', () {
    expect(const ReviewDraft(rating: 0, comment: '').validate(), isNotNull);
    expect(const ReportDraft(reasonCode: '', description: 'short').validate(),
        isNotNull);
  });
}
