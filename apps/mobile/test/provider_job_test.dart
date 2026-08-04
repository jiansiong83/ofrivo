import 'package:flutter_test/flutter_test.dart';

import 'package:ofrivo_mobile/core/data/fake_data.dart';
import 'package:ofrivo_mobile/core/models/app_models.dart';
import 'package:ofrivo_mobile/features/provider/provider_job_models.dart';
import 'package:ofrivo_mobile/features/provider/provider_job_repository.dart';

void main() {
  test('provider feed filters urgent and budgeted jobs', () async {
    final repository = FakeProviderJobRepository(initialJobs: fakeJobs, initialBids: fakeBids);

    final jobs = await repository.loadFeed(
      filters: const ProviderJobFilters(urgentOnly: true, minBudget: 90, sort: ProviderJobSort.highestBudget),
    );

    expect(jobs.map((job) => job.id), ['job-001']);
  });

  test('provider feed can find jobs with no active bids', () async {
    final noBidJob = fakeJobs.first.copyWith(bidCount: 0);
    final repository = FakeProviderJobRepository(initialJobs: [noBidJob], initialBids: const []);

    final jobs = await repository.loadFeed(filters: const ProviderJobFilters(noBidsOnly: true));

    expect(jobs.single.id, 'job-001');
  });

  test('provider can edit an active bid without creating a duplicate', () async {
    final repository = FakeProviderJobRepository(initialJobs: fakeJobs, initialBids: fakeBids);
    final updated = await repository.saveBid(
      BidDraft(
        bidId: 'bid-004',
        jobId: 'job-002',
        amount: '175',
        availableAt: DateTime(2026, 8, 5, 11),
        inclusions: 'Installation, testing, and cleanup',
        exclusions: 'Ceiling reinforcement',
        materialsNote: 'Customer supplies the fan.',
        message: 'I can arrive during the requested window.',
      ),
    );

    final bids = await repository.loadMyBids();
    expect(updated.bid.amount, 175);
    expect(bids.where((item) => item.bid.jobId == 'job-002'), hasLength(1));
    expect(bids.singleWhere((item) => item.bid.jobId == 'job-002').bid.inclusions, contains('cleanup'));
  });

  test('provider can submit and withdraw a new bid', () async {
    final job = Job(
      id: 'job-new',
      title: 'Repair a leaking pipe',
      category: 'Plumbing / Toilet',
      area: 'Mount Austin',
      budget: 140,
      time: 'Friday, 2pm–5pm',
      status: JobStatus.open,
      bidCount: 0,
      description: 'A pipe under the kitchen sink is leaking.',
      categoryId: '00000000-0000-0000-0000-000000000201',
      areaId: '00000000-0000-0000-0000-000000000251',
    );
    final repository = FakeProviderJobRepository(initialJobs: [job], initialBids: const []);
    final saved = await repository.saveBid(
      BidDraft(
        jobId: job.id,
        amount: '120',
        availableAt: DateTime(2026, 8, 7, 14),
        inclusions: 'Inspection and labour',
        exclusions: 'Replacement parts',
        materialsNote: '',
        message: '',
      ),
    );

    await repository.withdrawBid(saved.bid.id);
    final bids = await repository.loadMyBids();
    expect(bids.single.bid.status, BidStatus.withdrawn);
    expect((await repository.loadFeed(filters: const ProviderJobFilters())).single.bidCount, 0);
  });

  test('bid draft requires a positive amount and inclusions', () {
    final draft = BidDraft(
      jobId: 'job-001',
      amount: '0',
      availableAt: DateTime(2026, 8, 4, 17),
      inclusions: '',
      exclusions: '',
      materialsNote: '',
      message: '',
    );

    expect(draft.validate(), 'Enter a bid amount greater than RM0.');
  });
}
