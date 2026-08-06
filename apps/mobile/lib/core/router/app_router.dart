import 'package:go_router/go_router.dart';

import '../../features/auth/auth_screens.dart';
import '../../features/common/common_screens.dart';
import '../../features/customer/customer_screens.dart';
import '../../features/customer/customer_job_models.dart';
import '../models/app_models.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/provider/provider_screens.dart';
import '../../features/provider/provider_profile_edit_screen.dart';
import '../../features/job_lifecycle/job_lifecycle_screens.dart';
import '../../features/shell/shell_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/onboarding',
  routes: [
    GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
    GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen()),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(
        path: '/register', builder: (context, state) => const RegisterScreen()),
    GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen()),
    GoRoute(
        path: '/phone-login',
        builder: (context, state) => const PhoneOtpScreen()),
    GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen()),
    GoRoute(
        path: '/suspended',
        builder: (context, state) => const SuspendedAccountScreen()),
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(
            path: '/customer/home',
            builder: (context, state) => const CustomerHomeScreen()),
        GoRoute(
            path: '/customer/post',
            builder: (context, state) => const PostJobScreen()),
        GoRoute(
            path: '/customer/post/preview',
            builder: (context, state) => PostJobPreviewScreen(
                draft: state.extra is JobDraft
                    ? state.extra! as JobDraft
                    : JobDraft.demo())),
        GoRoute(
            path: '/customer/jobs',
            builder: (context, state) => const MyJobsScreen()),
        GoRoute(
            path: '/customer/jobs/:id',
            builder: (context, state) =>
                JobDetailScreen(jobId: state.pathParameters['id']!)),
        GoRoute(
            path: '/customer/jobs/:id/bids',
            builder: (context, state) =>
                ReceivedBidsScreen(jobId: state.pathParameters['id']!)),
        GoRoute(
            path: '/customer/jobs/:id/review',
            builder: (context, state) =>
                ReviewScreen(jobId: state.pathParameters['id']!)),
        GoRoute(
            path: '/customer/jobs/:id/report',
            builder: (context, state) =>
                ReportScreen(jobId: state.pathParameters['id']!)),
        GoRoute(
            path: '/customer/providers/:id',
            builder: (context, state) => ProviderProfileScreen(
                providerId: state.pathParameters['id']!,
                profile: state.extra is ProviderProfile
                    ? state.extra! as ProviderProfile
                    : null)),
        GoRoute(
            path: '/customer/profile',
            builder: (context, state) => const CustomerProfileScreen()),
        GoRoute(
            path: '/provider/apply',
            builder: (context, state) => const BecomeProviderScreen()),
        GoRoute(
            path: '/provider/verification',
            builder: (context, state) => const VerificationStatusScreen()),
        GoRoute(
            path: '/provider/feed',
            builder: (context, state) => const ProviderFeedScreen()),
        GoRoute(
            path: '/provider/filters',
            builder: (context, state) => const ProviderFiltersScreen()),
        GoRoute(
            path: '/provider/jobs/:id',
            builder: (context, state) =>
                ProviderJobDetailScreen(jobId: state.pathParameters['id']!)),
        GoRoute(
            path: '/provider/jobs/:id/bid',
            builder: (context, state) => SubmitBidScreen(
                jobId: state.pathParameters['id']!,
                existingBid: state.extra is Bid ? state.extra! as Bid : null)),
        GoRoute(
            path: '/provider/bids',
            builder: (context, state) => const MyBidsScreen()),
        GoRoute(
            path: '/provider/assigned',
            builder: (context, state) => const AssignedJobsScreen()),
        GoRoute(
            path: '/provider/assigned/:id',
            builder: (context, state) =>
                AssignedJobDetailScreen(jobId: state.pathParameters['id']!)),
        GoRoute(
            path: '/provider/assigned/:id/review',
            builder: (context, state) =>
                ReviewScreen(jobId: state.pathParameters['id']!)),
        GoRoute(
            path: '/provider/assigned/:id/report',
            builder: (context, state) =>
                ReportScreen(jobId: state.pathParameters['id']!)),
        GoRoute(
            path: '/provider/profile',
            builder: (context, state) => const ProviderProfileModeScreen()),
        GoRoute(
            path: '/provider/profile/edit',
            builder: (context, state) => const ProviderProfileEditScreen()),
      ],
    ),
  ],
);
