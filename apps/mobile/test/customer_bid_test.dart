import 'package:flutter_test/flutter_test.dart';

import 'package:ofrivo_mobile/core/data/fake_data.dart';
import 'package:ofrivo_mobile/core/models/app_models.dart';
import 'package:ofrivo_mobile/features/customer/customer_bid_repository.dart';

void main() {
  Job openJob() => const Job(
        id: 'job-test',
        title: 'Fix a sink',
        category: 'Plumbing / Toilet',
        area: 'Mount Austin',
        budget: 120,
        time: 'Today',
        status: JobStatus.open,
        bidCount: 2,
        description: 'A leaking sink.',
      );

  Bid bid(String id, String providerId, double amount) => Bid(
        id: id,
        jobId: 'job-test',
        providerName: providerId,
        providerCategory: 'Plumbing',
        amount: amount,
        availableAt: 'Today',
        inclusions: 'Labour',
        exclusions: '',
        status: BidStatus.pending,
        rating: 4.8,
        completedJobs: 20,
        providerId: providerId,
      );

  test(
      'received bids include provider profiles and acceptance rejects the rest',
      () async {
    final repository = FakeCustomerBidRepository(
      initialJobs: [openJob()],
      initialBids: [
        bid('bid-a', 'provider-a', 100),
        bid('bid-b', 'provider-b', 110)
      ],
      profiles: const [
        ProviderProfile(
            name: 'Provider A',
            category: 'Plumbing',
            area: 'JB',
            rating: 4.8,
            completedJobs: 20,
            bio: 'A',
            verification: VerificationStatus.approved,
            id: 'provider-a'),
        ProviderProfile(
            name: 'Provider B',
            category: 'Plumbing',
            area: 'JB',
            rating: 4.7,
            completedJobs: 18,
            bio: 'B',
            verification: VerificationStatus.approved,
            id: 'provider-b'),
      ],
    );

    final received = await repository.loadReceivedBids('job-test');
    expect(received, hasLength(2));
    expect(received.first.provider.name, 'Provider A');

    final result =
        await repository.acceptBid(jobId: 'job-test', bidId: 'bid-a');
    expect(result.jobStatus, JobStatus.assigned);
    final statuses = await repository.loadReceivedBids('job-test');
    expect(statuses.first.bid.status, BidStatus.accepted);
    expect(statuses.last.bid.status, BidStatus.rejected);
  });

  test('a second acceptance cannot bypass the assigned state', () async {
    final repository = FakeCustomerBidRepository(
      initialJobs: [openJob()],
      initialBids: [
        bid('bid-a', 'provider-a', 100),
        bid('bid-b', 'provider-b', 110)
      ],
      profiles: const [
        ProviderProfile(
            name: 'Provider A',
            category: 'Plumbing',
            area: 'JB',
            rating: 4.8,
            completedJobs: 20,
            bio: 'A',
            verification: VerificationStatus.approved,
            id: 'provider-a'),
        ProviderProfile(
            name: 'Provider B',
            category: 'Plumbing',
            area: 'JB',
            rating: 4.7,
            completedJobs: 18,
            bio: 'B',
            verification: VerificationStatus.approved,
            id: 'provider-b'),
      ],
    );

    await repository.acceptBid(jobId: 'job-test', bidId: 'bid-a');
    expect(() => repository.acceptBid(jobId: 'job-test', bidId: 'bid-b'),
        throwsStateError);
  });
  test('fake customer bids are empty for an unrelated account', () async {
    final repository = FakeCustomerBidRepository(
      initialJobs: fakeJobs,
      initialBids: fakeBids,
      userId: 'demo-user-new-222-222-com',
    );

    expect(await repository.loadReceivedBids('job-001'), isEmpty);
    expect(
      () => repository.acceptBid(jobId: 'job-001', bidId: 'bid-001'),
      throwsStateError,
    );
  });
}
