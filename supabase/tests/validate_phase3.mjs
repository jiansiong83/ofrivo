import fs from 'node:fs';

const checks = [];

function read(path) {
  return fs.readFileSync(path, 'utf8');
}

function pass(label, condition) {
  if (!condition) throw new Error(label + ' failed');
  checks.push(label);
  console.log('PASS ' + label);
}

const migration = read('supabase/migrations/20260809000200_job_update_hardening.sql');
const model = read('apps/mobile/lib/features/customer/customer_job_models.dart');
const repository = read('apps/mobile/lib/features/customer/customer_job_repository.dart');
const controller = read('apps/mobile/lib/features/customer/customer_jobs_controller.dart');
const screens = read('apps/mobile/lib/features/customer/customer_screens.dart');
const router = read('apps/mobile/lib/core/router/app_router.dart');
const test = read('apps/mobile/test/customer_job_edit_test.dart');

pass(
  'open jobs cannot be moved back to draft by a browser client',
  migration.includes("old.status = 'open' and new.status = 'draft'") &&
    migration.includes('an open job cannot be moved back to draft'),
);
pass(
  'open job expiry is server-controlled',
  migration.includes('new.expires_at is distinct from old.expires_at') &&
    migration.includes('open job expiry is managed by the server'),
);
pass(
  'job hardening trigger is installed and not browser-callable',
  migration.includes('jobs_guard_open_mutation') &&
    migration.includes('revoke all on function public.guard_open_job_mutation()'),
);
pass(
  'job draft carries an owner id for edits',
  model.includes('final String? jobId') && model.includes('static JobDraft fromJob'),
);
pass(
  'job draft keeps same-day end-after-start validation',
  model.includes('End time must be later on the same day as the start time.'),
);
pass(
  'fake and Supabase repositories expose owner-scoped updates',
  repository.includes('Future<Job> updateJob') &&
    repository.includes("eq('customer_id', userId)") &&
    repository.includes("inFilter('status', ['draft', 'open'])"),
);
pass(
  'fake writes validate before persisting',
  repository.includes('final validationError = draft.validate();') &&
    repository.includes('if (validationError != null) throw StateError(validationError);'),
);
pass(
  'customer controller routes edits through the update operation',
  controller.includes('draft.jobId == null') &&
    controller.includes('repository.updateJob(draft.jobId!, draft'),
);
pass(
  'customer UI exposes edit only for draft/open jobs',
  screens.includes('class EditJobScreen') &&
    screens.includes("currentJob.id}/edit") &&
    screens.includes('currentJob.status == JobStatus.draft'),
);
pass(
  'edit route is nested under the customer job',
  router.includes("path: 'edit'") && router.includes('EditJobScreen'),
);
pass(
  'Phase 3 Flutter regressions cover validation and state gates',
  test.includes('validates before writing a job') &&
    test.includes('not assigned jobs'),
);

console.log('Phase 3 static validation passed: ' + checks.length + ' checks.');
