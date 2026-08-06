export type ProviderStatus = 'pending' | 'approved' | 'rejected' | 'suspended';
export type CategoryRequestStatus = 'pending' | 'approved' | 'rejected';
export type AccountStatus = 'active' | 'suspended';
export type ReportStatus = 'open' | 'reviewing' | 'resolved' | 'dismissed';
export type JobStatus = 'draft' | 'open' | 'assigned' | 'in_progress' | 'completed' | 'cancelled' | 'expired';
export type BidStatus = 'pending' | 'accepted' | 'rejected' | 'withdrawn' | 'expired';

export interface AdminProvider {
  id: string;
  name: string;
  email: string;
  category: string;
  area: string;
  status: ProviderStatus;
  submittedAt: string;
  rating: number;
  completedJobs: number;
  bio: string;
  evidence: string[];
  evidenceLinks?: { label: string; path: string; url: string | null }[];
}

export interface AdminCategoryRequest {
  id: string;
  providerId: string;
  providerName: string;
  providerEmail: string;
  categoryId: string;
  category: string;
  status: CategoryRequestStatus;
  submittedAt: string;
  reviewedAt: string;
  adminNote: string;
}

export interface AdminUser {
  id: string;
  name: string;
  email: string;
  role: 'customer' | 'provider' | 'admin';
  status: AccountStatus;
  joinedAt: string;
  jobs: number;
  bids: number;
}

export interface AdminJob {
  id: string;
  title: string;
  customer: string;
  area: string;
  category: string;
  budget: number;
  status: JobStatus;
  bids: number;
  createdAt: string;
  fullAddress: string;
}

export interface AdminBid {
  id: string;
  jobTitle: string;
  provider: string;
  customer: string;
  amount: number;
  status: BidStatus;
  createdAt: string;
}

export interface AdminReport {
  id: string;
  jobTitle: string;
  reporter: string;
  reportedUser: string;
  reason: string;
  description: string;
  status: ReportStatus;
  createdAt: string;
}

export interface AdminAuditEvent {
  id: string;
  actor: string;
  action: string;
  target: string;
  createdAt: string;
}

export interface AdminData {
  categoryRequests: AdminCategoryRequest[];
  providers: AdminProvider[];
  users: AdminUser[];
  jobs: AdminJob[];
  bids: AdminBid[];
  reports: AdminReport[];
  audit: AdminAuditEvent[];
  categories: string[];
  areas: string[];
}

export function makeFakeAdminData(): AdminData {
  return {
    categoryRequests: [],
    providers: [
      {
        id: 'provider-102',
        name: 'Ahmad Plumbing',
        email: 'ahmad@example.test',
        category: 'Plumbing / Toilet',
        area: 'Mount Austin',
        status: 'pending',
        submittedAt: 'Today, 09:12',
        rating: 4.9,
        completedJobs: 86,
        bio: 'Friendly local plumbing service for homes and small shops.',
        evidence: ['IC front', 'IC back', 'Selfie', 'Work photo 1'],
      },
      {
        id: 'provider-104',
        name: 'JB Home Fix',
        email: 'homefix@example.test',
        category: 'Handyman',
        area: 'Taman Molek',
        status: 'pending',
        submittedAt: 'Yesterday, 18:40',
        rating: 4.7,
        completedJobs: 42,
        bio: 'A practical handyman team for quick household repairs.',
        evidence: ['IC front', 'IC back', 'Selfie', 'SSM certificate'],
      },
      {
        id: 'provider-106',
        name: 'MoveRight JB',
        email: 'moveright@example.test',
        category: 'Moving / Delivery',
        area: 'Permas Jaya',
        status: 'approved',
        submittedAt: '02 Aug 2026',
        rating: 4.8,
        completedJobs: 121,
        bio: 'Careful local movers with trolleys and a flexible weekend crew.',
        evidence: ['IC front', 'IC back', 'Selfie', 'Work photo 1'],
      },
    ],
    users: [
      { id: 'customer-101', name: 'Alex Tan', email: 'customer@example.test', role: 'customer', status: 'active', joinedAt: '01 Aug 2026', jobs: 4, bids: 0 },
      { id: 'provider-102', name: 'Ahmad Plumbing', email: 'ahmad@example.test', role: 'provider', status: 'active', joinedAt: '02 Aug 2026', jobs: 2, bids: 7 },
      { id: 'provider-104', name: 'JB Home Fix', email: 'homefix@example.test', role: 'provider', status: 'active', joinedAt: '03 Aug 2026', jobs: 1, bids: 3 },
      { id: 'customer-109', name: 'Suspended customer', email: 'suspended@example.test', role: 'customer', status: 'suspended', joinedAt: '18 Jul 2026', jobs: 1, bids: 0 },
    ],
    jobs: [
      { id: 'job-301', title: 'Toilet blockage', customer: 'Alex Tan', area: 'Mount Austin', category: 'Plumbing / Toilet', budget: 100, status: 'open', bids: 3, createdAt: 'Today, 08:00', fullAddress: '15 Example Street, Mount Austin, Johor Bahru' },
      { id: 'job-302', title: 'Install ceiling fan', customer: 'Alex Tan', area: 'Taman Molek', category: 'Electrical / Lighting / Fan', budget: 160, status: 'open', bids: 1, createdAt: 'Yesterday, 19:00', fullAddress: '18 Example Street, Taman Molek, Johor Bahru' },
      { id: 'job-303', title: 'Move a washing machine', customer: 'Alex Tan', area: 'Permas Jaya', category: 'Moving / Delivery', budget: 80, status: 'assigned', bids: 4, createdAt: '02 Aug 2026', fullAddress: '22 Example Street, Permas Jaya, Johor Bahru' },
      { id: 'job-304', title: 'Repair kitchen sink pipe', customer: 'Alex Tan', area: 'Mount Austin', category: 'Plumbing / Toilet', budget: 140, status: 'completed', bids: 2, createdAt: '01 Aug 2026', fullAddress: '8 Example Street, Mount Austin, Johor Bahru' },
    ],
    bids: [
      { id: 'bid-401', jobTitle: 'Toilet blockage', provider: 'Ahmad Plumbing', customer: 'Alex Tan', amount: 120, status: 'pending', createdAt: 'Today, 09:20' },
      { id: 'bid-402', jobTitle: 'Toilet blockage', provider: 'JB Home Fix', customer: 'Alex Tan', amount: 95, status: 'pending', createdAt: 'Today, 09:26' },
      { id: 'bid-403', jobTitle: 'Move a washing machine', provider: 'MoveRight JB', customer: 'Alex Tan', amount: 90, status: 'accepted', createdAt: '02 Aug 2026' },
      { id: 'bid-404', jobTitle: 'Repair kitchen sink pipe', provider: 'Ahmad Plumbing', customer: 'Alex Tan', amount: 125, status: 'accepted', createdAt: '01 Aug 2026' },
    ],
    reports: [
      { id: 'report-501', jobTitle: 'Repair kitchen sink pipe', reporter: 'Alex Tan', reportedUser: 'Ahmad Plumbing', reason: 'Work quality concern', description: 'The leak returned after the first visit and the provider stopped replying.', status: 'open', createdAt: 'Today, 10:12' },
      { id: 'report-502', jobTitle: 'Move a washing machine', reporter: 'MoveRight JB', reportedUser: 'Alex Tan', reason: 'Payment or price dispute', description: 'Customer disputed the agreed scope after the job was completed.', status: 'reviewing', createdAt: 'Yesterday, 14:22' },
      { id: 'report-503', jobTitle: 'Install ceiling fan', reporter: 'Alex Tan', reportedUser: 'JB Home Fix', reason: 'No-show or late arrival', description: 'Provider did not arrive in the agreed time window.', status: 'resolved', createdAt: '30 Jul 2026' },
    ],
    audit: [
      { id: 'audit-601', actor: 'Admin', action: 'Reviewed report', target: 'report-502', createdAt: 'Today, 11:02' },
      { id: 'audit-602', actor: 'Admin', action: 'Approved provider', target: 'provider-106', createdAt: 'Yesterday, 16:40' },
      { id: 'audit-603', actor: 'Admin', action: 'Suspended account', target: 'customer-109', createdAt: '30 Jul 2026' },
    ],
    categories: ['Plumbing / Toilet', 'Electrical / Lighting / Fan', 'Air Conditioning', 'Moving / Delivery', 'Cleaning', 'Handyman'],
    areas: ['Mount Austin', 'Taman Molek', 'Permas Jaya', 'Taman Setia Indah', 'Bukit Indah'],
  };
}
