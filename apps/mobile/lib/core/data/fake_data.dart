import '../models/app_models.dart';

final fakeJobs = <Job>[
  const Job(
    id: 'job-001',
    title: 'Toilet blockage',
    category: 'Plumbing / Toilet',
    area: 'Mount Austin',
    budget: 100,
    time: 'Today, 2pm–6pm',
    status: JobStatus.open,
    bidCount: 3,
    description: 'Water is draining slowly and the toilet is close to overflowing.',
    urgent: true,
  ),
  const Job(
    id: 'job-002',
    title: 'Install ceiling fan',
    category: 'Electrical / Lighting / Fan',
    area: 'Taman Molek',
    budget: 160,
    time: 'Tomorrow, 10am–1pm',
    status: JobStatus.open,
    bidCount: 1,
    description: 'Install one new ceiling fan. Existing power point is available.',
  ),
  const Job(
    id: 'job-003',
    title: 'Move a washing machine',
    category: 'Moving / Delivery',
    area: 'Permas Jaya',
    budget: 80,
    time: 'Sat, 9am–12pm',
    status: JobStatus.assigned,
    bidCount: 4,
    description: 'Move one washing machine from a landed house to a nearby apartment.',
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
  ),
];

const fakeProvider = ProviderProfile(
  name: 'Ahmad Plumbing',
  category: 'Plumbing / Toilet',
  area: 'Johor Bahru',
  rating: 4.9,
  completedJobs: 86,
  bio: 'Friendly local plumbing service for homes and small shops.',
  verification: VerificationStatus.approved,
);

const fakeProviderProfileProvider = fakeProvider;
