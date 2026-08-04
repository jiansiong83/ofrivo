import { readFile } from 'node:fs/promises';

const migration = await readFile(new URL('../migrations/20260804000100_step2_foundation.sql', import.meta.url), 'utf8');
const models = await readFile(new URL('../../apps/mobile/lib/features/job_lifecycle/job_lifecycle_models.dart', import.meta.url), 'utf8');
const repository = await readFile(new URL('../../apps/mobile/lib/features/job_lifecycle/job_lifecycle_repository.dart', import.meta.url), 'utf8');
const controller = await readFile(new URL('../../apps/mobile/lib/features/job_lifecycle/job_lifecycle_controller.dart', import.meta.url), 'utf8');
const screens = await readFile(new URL('../../apps/mobile/lib/features/job_lifecycle/job_lifecycle_screens.dart', import.meta.url), 'utf8');
const router = await readFile(new URL('../../apps/mobile/lib/core/router/app_router.dart', import.meta.url), 'utf8');

const checks = [
  ['start RPC', migration.includes('create or replace function public.start_job') && migration.includes("only assigned jobs can be started")],
  ['start provider guard', migration.includes('only the accepted provider can start this job')],
  ['complete RPC', migration.includes('create or replace function public.complete_job') && migration.includes("only in-progress jobs can be completed")],
  ['complete participant guard', migration.includes('only the customer or accepted provider can complete this job')],
  ['cancel RPC', migration.includes('create or replace function public.cancel_job') && migration.includes('only a job participant or admin can cancel this job')],
  ['review participant trigger', migration.includes('create trigger reviews_validate_participants') && migration.includes('reviews require a completed job')],
  ['report participant trigger', migration.includes('create trigger reports_validate_participants') && migration.includes('reports require a job with an accepted provider')],
  ['review/report model', models.includes('class ReviewDraft') && models.includes('class ReportDraft')],
  ['fake lifecycle', repository.includes('class FakeJobLifecycleRepository') && repository.includes('JobStatus.completed')],
  ['Supabase lifecycle RPC adapter', repository.includes("rpc(function, params: params)") && repository.includes("from('reviews')") && repository.includes("from('reports')")],
  ['event history', repository.includes("from('job_events')") && screens.includes('JobEventTimeline')],
  ['lifecycle controller', controller.includes('jobLifecycleControllerProvider') && controller.includes('submitReview') && controller.includes('submitReport')],
  ['review/report routes', router.includes('/customer/jobs/:id/review') && router.includes('/provider/assigned/:id/report')],
];

const failures = checks.filter(([, passed]) => !passed);
if (failures.length > 0) {
  console.error(`Step 8 contract validation failed: ${failures.map(([name]) => name).join(', ')}`);
  process.exit(1);
}
console.log(`Step 8 contract validation passed: ${checks.length} lifecycle/mobile checks.`);
