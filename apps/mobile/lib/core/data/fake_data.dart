import '../models/app_models.dart';
import '../../features/job_lifecycle/job_lifecycle_models.dart';

const demoCustomerUserIds = <String>{
  'demo-user',
  'demo-user-customer-example-test',
};

const demoProviderUserIds = <String>{
  'demo-user',
  'demo-user-provider-example-test',
  'demo-user-provider-b-example-test',
};

List<Job> fakeJobsForCustomer(String userId, List<Job> jobs) =>
    demoCustomerUserIds.contains(userId) ? List<Job>.from(jobs) : <Job>[];

List<Job> fakeJobsForProvider(String userId, List<Job> jobs) =>
    demoProviderUserIds.contains(userId) ? List<Job>.from(jobs) : <Job>[];

String? demoProviderSeedIdForUser(String userId) => switch (userId) {
      'demo-user' || 'demo-user-provider-example-test' => 'demo-user',
      'demo-user-provider-b-example-test' => 'provider-b',
      _ => null,
    };

List<Bid> fakeBidsForProvider(String userId, List<Bid> bids) {
  final seedId = demoProviderSeedIdForUser(userId);
  if (seedId == null) return <Bid>[];
  return [
    for (final bid in bids)
      if (bid.providerId == seedId) bid,
  ];
}

List<Bid> fakeBidsForJobs(List<Job> jobs, List<Bid> bids) {
  final jobIds = jobs.map((job) => job.id).toSet();
  return [
    for (final bid in bids)
      if (jobIds.contains(bid.jobId)) bid
  ];
}

final fakeJobs = <Job>[
  Job(
    id: 'job-001',
    title: 'Toilet blockage',
    category: 'Plumbing / Toilet',
    area: 'Mount Austin',
    budget: 100,
    time: 'Today, 2pm–6pm',
    status: JobStatus.open,
    bidCount: 3,
    description:
        'Water is draining slowly and the toilet is close to overflowing.',
    urgent: true,
    categoryId: '00000000-0000-0000-0000-000000000201',
    areaId: '00000000-0000-0000-0000-000000000251',
    createdAt: DateTime(2026, 8, 4, 8),
    scheduledAt: DateTime(2026, 8, 4, 14),
    scheduledEndAt: DateTime(2026, 8, 4, 18),
    fullAddress: '15 Example Street, Mount Austin, Johor Bahru',
    contactPhone: '+60 12 000 0101',
    contactWhatsapp: '+60 12 000 0101',
  ),
  Job(
    id: 'job-002',
    title: 'Install ceiling fan',
    category: 'Electrical / Lighting / Fan',
    area: 'Taman Molek',
    budget: 160,
    time: 'Tomorrow, 10am–1pm',
    status: JobStatus.open,
    bidCount: 1,
    description:
        'Install one new ceiling fan. Existing power point is available.',
    categoryId: '00000000-0000-0000-0000-000000000202',
    areaId: '00000000-0000-0000-0000-000000000252',
    createdAt: DateTime(2026, 8, 3, 19),
    scheduledAt: DateTime(2026, 8, 5, 10),
    scheduledEndAt: DateTime(2026, 8, 5, 13),
    fullAddress: '18 Example Street, Taman Molek, Johor Bahru',
    contactPhone: '+60 12 000 0101',
    contactWhatsapp: '+60 12 000 0101',
  ),
  Job(
    id: 'job-003',
    title: 'Move a washing machine',
    category: 'Moving / Delivery',
    area: 'Permas Jaya',
    budget: 80,
    time: 'Sat, 9am–12pm',
    status: JobStatus.assigned,
    bidCount: 4,
    description:
        'Move one washing machine from a landed house to a nearby apartment.',
    categoryId: '00000000-0000-0000-0000-000000000204',
    areaId: '00000000-0000-0000-0000-000000000253',
    createdAt: DateTime(2026, 8, 2, 12),
    scheduledAt: DateTime(2026, 8, 8, 9),
    scheduledEndAt: DateTime(2026, 8, 8, 12),
    fullAddress: '22 Example Street, Permas Jaya, Johor Bahru',
    contactPhone: '+60 12 000 0101',
    contactWhatsapp: '+60 12 000 0101',
    acceptedBidId: 'bid-003',
  ),
  Job(
    id: 'job-004',
    title: 'Repair kitchen sink pipe',
    category: 'Plumbing / Toilet',
    area: 'Mount Austin',
    budget: 140,
    time: 'Today, 6pm–8pm',
    status: JobStatus.assigned,
    bidCount: 2,
    description: 'The kitchen sink pipe is leaking under the cabinet.',
    categoryId: '00000000-0000-0000-0000-000000000201',
    areaId: '00000000-0000-0000-0000-000000000251',
    fullAddress: '8 Example Street, Mount Austin, Johor Bahru',
    contactPhone: '+60 12 555 0101',
    contactWhatsapp: '+60 12 555 0101',
    acceptedBidId: 'bid-005',
    createdAt: DateTime(2026, 8, 3, 10),
    scheduledAt: DateTime(2026, 8, 4, 18),
    scheduledEndAt: DateTime(2026, 8, 4, 20),
  ),
];

final fakeBids = <Bid>[
  const Bid(
    id: 'bid-001',
    jobId: 'job-001',
    providerName: 'Ahmad Plumbing',
    providerCategory: 'Plumbing / Toilet',
    amount: 120,
    availableAt: 'Today, 5pm',
    inclusions: 'Inspection and labour',
    exclusions: 'Materials and wall hacking',
    status: BidStatus.pending,
    rating: 4.9,
    completedJobs: 86,
    providerId: 'demo-user',
  ),
  const Bid(
    id: 'bid-002',
    jobId: 'job-001',
    providerName: 'JB Home Fix',
    providerCategory: 'Handyman',
    amount: 95,
    availableAt: 'Today, 3pm',
    inclusions: 'Inspection and basic unclogging',
    exclusions: 'Replacement parts',
    status: BidStatus.pending,
    rating: 4.7,
    completedJobs: 42,
    providerId: 'provider-b',
  ),
  const Bid(
    id: 'bid-004',
    jobId: 'job-002',
    providerName: 'Ahmad Plumbing',
    providerCategory: 'Electrical / Lighting / Fan',
    amount: 150,
    availableAt: 'Tomorrow, 11am',
    inclusions: 'Installation and testing',
    exclusions: 'Ceiling reinforcement',
    status: BidStatus.pending,
    rating: 4.9,
    completedJobs: 86,
    providerId: 'demo-user',
  ),
  const Bid(
    id: 'bid-003',
    jobId: 'job-003',
    providerName: 'MoveRight JB',
    providerCategory: 'Moving / Delivery',
    amount: 90,
    availableAt: 'Sat, 9am',
    inclusions: 'Two movers and trolley',
    exclusions: 'Staircase surcharge',
    status: BidStatus.accepted,
    rating: 4.8,
    completedJobs: 121,
    providerId: 'provider-mover',
  ),
  const Bid(
    id: 'bid-005',
    jobId: 'job-004',
    providerName: 'Ahmad Plumbing',
    providerCategory: 'Plumbing / Toilet',
    amount: 125,
    availableAt: 'Today, 6pm',
    inclusions: 'Inspection, labour, and leak repair',
    exclusions: 'Replacement pipe if required',
    status: BidStatus.accepted,
    rating: 4.9,
    completedJobs: 86,
    providerId: 'demo-user',
  ),
];

const fakeProvider = ProviderProfile(
  id: 'demo-user',
  name: 'Ahmad Plumbing',
  category: 'Plumbing / Toilet',
  area: 'Johor Bahru',
  rating: 4.9,
  completedJobs: 86,
  bio: 'Friendly local plumbing service for homes and small shops.',
  verification: VerificationStatus.approved,
  portfolioUrls: [
    'demo/portfolio-plumbing-1.jpg',
    'demo/portfolio-plumbing-2.jpg'
  ],
);

const fakeProviderB = ProviderProfile(
  id: 'provider-b',
  name: 'JB Home Fix',
  category: 'Handyman',
  area: 'Johor Bahru',
  rating: 4.7,
  completedJobs: 42,
  bio:
      'A practical handyman team for quick household repairs and installations.',
  verification: VerificationStatus.approved,
  portfolioUrls: ['demo/portfolio-handyman-1.jpg'],
);

const fakeProviderMover = ProviderProfile(
  id: 'provider-mover',
  name: 'MoveRight JB',
  category: 'Moving / Delivery',
  area: 'Johor Bahru',
  rating: 4.8,
  completedJobs: 121,
  bio: 'Careful local movers with trolleys and a flexible weekend crew.',
  verification: VerificationStatus.approved,
  portfolioUrls: ['demo/portfolio-mover-1.jpg', 'demo/portfolio-mover-2.jpg'],
);

final fakeProviderProfiles = <ProviderProfile>[
  fakeProvider,
  fakeProviderB,
  fakeProviderMover
];

final fakeNotifications = <AppNotification>[
  AppNotification(
    id: 'notification-003',
    type: NotificationType.jobExpiring,
    title: 'Job expiring soon',
    body: 'Your toilet blockage job will stop accepting offers tomorrow.',
    isRead: false,
    createdAt: DateTime(2026, 8, 4, 10),
    referenceType: 'job',
    referenceId: 'job-001',
  ),
  AppNotification(
    id: 'notification-004',
    type: NotificationType.newJob,
    title: 'New matching job nearby',
    body: 'A plumbing job is open in Mount Austin.',
    isRead: false,
    createdAt: DateTime(2026, 8, 4, 9, 30),
    referenceType: 'job',
    referenceId: 'job-001',
  ),
  AppNotification(
    id: 'notification-001',
    type: NotificationType.newBid,
    title: 'New offer received',
    body: 'Your toilet blockage job has a new offer.',
    isRead: false,
    createdAt: DateTime(2026, 8, 4, 9),
    referenceType: 'job',
    referenceId: 'job-001',
  ),
  AppNotification(
    id: 'notification-002',
    type: NotificationType.providerApproved,
    title: 'Provider verification approved',
    body: 'You can now view matching jobs.',
    isRead: true,
    createdAt: DateTime(2026, 8, 3, 16),
    referenceType: 'provider',
    referenceId: 'demo-user',
  ),
];

List<AppNotification> fakeNotificationsForUser(
    String userId, List<AppNotification> notifications) {
  return [
    for (final notification in notifications)
      if (notification.recipientId == userId ||
          (notification.recipientId == null &&
              (userId == 'demo-user' ||
                  (demoCustomerUserIds.contains(userId) &&
                      (notification.type == NotificationType.jobExpiring ||
                          notification.type == NotificationType.newBid)) ||
                  (demoProviderUserIds.contains(userId) &&
                      (notification.type == NotificationType.newJob ||
                          notification.type ==
                              NotificationType.providerApproved)))))
        notification
  ];
}

final fakeJobEvents = <JobEventRecord>[];
final fakeReviews = <ReviewRecord>[];
final fakeReports = <ReportRecord>[];
