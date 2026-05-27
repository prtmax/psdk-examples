---
schema: conductor/repository-workflow-policy/1
execution:
  canonicalize_commands: []
  verify_commands: []
  max_attempts: 3
  retry_backoff_seconds: 300
  command_timeout_seconds: 1800
context:
  read_first:
    - README.md
landing:
  default_merge_method: squash
  allowed_merge_methods:
    - merge
    - squash
---

Use this repository policy as the working contract for Conductor-owned lanes in
PSDK Examples.

PSDK Examples is a collection of platform-specific printer SDK sample applications. It is
not a single application with one root build. Changes should preserve each demo's local
platform conventions and keep the example focused on showing PSDK usage clearly.

## Conductor execution contract

Use Conductor tracker tools for attempt results, review handoff, repair completion, and
closeout. The final repository commit is created by Conductor from structured attempt
metadata; do not create ordinary unmanaged commits as the final handoff result.

Use the issue-scoped Conductor tools autonomously for normal-path state changes and
comments on the currently leased issue. Keep comments specific and actionable. Do not
dump simulator logs, Gradle logs, or unrelated setup details into the issue unless they
explain a blocker.

Automatic intake is driven by the repository-scoped tracker label configured in
`conductor.toml`. Keep work scoped to the current issue. Do not widen into unrelated
examples, SDK package upgrades, formatting sweeps, or localization rewrites unless the
issue explicitly asks for that scope.

Treat `In Review` as a PR-backed handoff state. A normal success path must push the lane
branch, create or update a non-draft PR, and then ask Conductor to complete the review
handoff.

## Required reading

Start with the files listed in `context.read_first`. Then route to the affected example:

- Flutter examples: `dart-example/` or `emapi-demo/flutter/`.
- Web print example: `webprint/`.
- Taro mini program example: `miniprogram-taro/`.
- WeChat mini program example: `miniprogram-wx/`.
- UniApp mini program example: `miniprogram-uniapp/`.
- Harmony example: `harmony-demo/`.
- Android native examples: the matching directory under `android-native-java/`.
- iOS native examples: `ios-native-objectivec/` or `ios-native-swift/`.
- Java and Go examples: `java-demo/` or `go-demo/`.
- Localization work: `l10n/` plus the affected platform example.

Read the affected example's README when one exists. If the example consumes local PSDK
packages by relative path, inspect the matching package in `/code/repotea/psdk` before
changing integration code.

## Validation

There is no root task runner or broad repository gate. Choose commands from the affected
example and record exactly what was run.

Use focused validation:

- Flutter examples: from the example directory, run `flutter pub get`,
  `flutter analyze`, and `flutter test` when tests exist.
- Web print: `cd webprint && npm install && npm run build`.
- Taro mini program: `cd miniprogram-taro && npm install && npm run build:weapp` unless
  the issue targets another Taro platform.
- WeChat or UniApp mini program examples: run the package manager install and the
  project-specific build command when one exists; otherwise validate by static inspection
  and record the missing command.
- Harmony example: use the local Hvigor/DevEco build flow available in `harmony-demo/`;
  if the CLI is not available in the lane environment, record that limitation and inspect
  manifest, ability, and package files directly.
- Android native examples: from the affected demo directory, run `./gradlew assembleDebug`
  when Android SDK prerequisites are available.
- iOS native examples: run CocoaPods/Xcode validation only when the local environment has
  the required toolchain; otherwise inspect project files and record the toolchain gap.

Do not claim work is complete, fixed, reviewed, or ready to land without fresh evidence
from the relevant command output or a clear note that the platform toolchain was not
available.

## Example rules

Keep examples small and direct. A sample app should demonstrate printer discovery,
connection, command construction, printing, and error handling for its target platform
without becoming a generic application framework.

Preserve platform conventions:

- Do not replace a native platform build system with another toolchain.
- Do not upgrade SDK dependencies broadly unless the issue is about dependency refresh.
- Keep demo assets, permissions, manifest entries, and platform capabilities aligned with
  the transport being demonstrated.
- Avoid hardcoding secrets, private endpoints, or device-specific credentials.
- When a sample depends on local PSDK packages, prefer relative development paths only
  where the example already uses that pattern.

## Documentation rules

Update the affected example README when setup, permissions, platform requirements, or user
steps change. Do not create root-level implementation notes, temporary summaries, or phase
documents.

## Review method

Use the repo-native bounded review method for both pre-PR review handoff and retained
review repair:

- Review the actual current diff or repaired branch state for the current `HEAD`.
- Run an implementation pass against the target platform behavior and example clarity.
- Run an adversarial pass against build fallout, missing platform permissions, dependency
  drift, local SDK path drift, generated artifact noise, and docs drift.
- Treat external review claims as candidate findings to validate, not automatic truth.
- Fix the smallest coherent owned batch, rerun relevant verification, re-read `HEAD`, and
  record the normalized review result for that exact head.
- The normalized review outcomes are `clean`, `findings`, `needs_architecture_review`,
  and `blocked`.
- If repeated rounds keep producing new findings for the same phase, stop patch-on-patch
  churn and escalate instead of continuing indefinitely.
