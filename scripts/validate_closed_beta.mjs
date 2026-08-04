import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = path.resolve(fileURLToPath(new URL('..', import.meta.url)));

function read(relativePath) {
  return fs.readFileSync(path.join(root, relativePath), 'utf8');
}

function assertIncludes(contents, needle, label) {
  if (!contents.includes(needle)) {
    throw new Error(`${label}: missing ${needle}`);
  }
}

const buildGradle = read('apps/mobile/android/app/build.gradle.kts');
const keyExample = read('apps/mobile/android/key.properties.example');
const androidIgnore = read('apps/mobile/android/.gitignore');
const runbook = read('docs/CLOSED_BETA_RUNBOOK.md');
const bugTemplate = read('docs/BUG_REPORT_TEMPLATE.md');
const checklist = read('docs/RELEASE_CHECKLIST.md');
const pubspec = read('apps/mobile/pubspec.yaml');

const buildContract = [
  'key.properties',
  'releaseSigningConfigured',
  'allowDebugReleaseSigning',
  'OFRIVO_ALLOW_DEBUG_RELEASE_SIGNING',
  'Closed-beta release signing is not configured',
];
buildContract.forEach((needle) => assertIncludes(buildGradle, needle, 'release signing guard'));

['storeFile=', 'storePassword=', 'keyAlias=', 'keyPassword='].forEach((needle) => {
  assertIncludes(keyExample, needle, 'key.properties example');
});
['key.properties', '**/*.keystore', '**/*.jks'].forEach((needle) => {
  assertIncludes(androidIgnore, needle, 'keystore ignore rules');
});

[
  'Signed APK / AAB',
  'Google Play',
  'closed-testing',
  'Test identities and jobs',
  'CB-JOB-001',
  'Bug report process',
  'Rollback build',
  'External gates',
].forEach((needle) => assertIncludes(runbook, needle, 'closed-beta runbook'));

['Severity:', 'Build version', 'Reproduction', 'privacy', 'Retest build'].forEach((needle) => {
  assertIncludes(bugTemplate, needle, 'bug report template');
});
assertIncludes(checklist, '## Step 12 Closed Beta', 'release checklist');
assertIncludes(checklist, 'Test accounts and rollback build are documented', 'release checklist');

const versionMatch = pubspec.match(/^version:\s+(\d+\.\d+\.\d+\+\d+)$/m);
if (!versionMatch) {
  throw new Error('pubspec: expected versionName+versionCode format');
}
const buildNumber = Number(versionMatch[1].split('+')[1]);
if (!Number.isInteger(buildNumber) || buildNumber < 1) {
  throw new Error('pubspec: versionCode must be a positive integer');
}

console.log('Step 12 contract validation passed: 10 closed-beta readiness checks.');
