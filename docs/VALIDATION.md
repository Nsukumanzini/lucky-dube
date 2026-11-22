# Validation record — 21 November 2026

Provisioned Flutter 3.50.1 stable (ae9b586f34), Dart 3.14.0 in /workspace/flutter after finding no installed Flutter toolchain. Downloading the older archive initially returned 404; GitHub source bootstrap succeeded.

- `flutter pub get`: passed.
- `dart format .`: passed within the application directory.
- `flutter analyze`: no issues found after lint/layout fixes.
- `flutter test`: 11 passed. Six repository tests cover credentials, grade isolation/submission, scoring, preference/message persistence, notifications/completion and configuration/ID integrity. Five widget tests exercise dashboard and every main/additional destination at 360, 390, 768, 1024 and 1440 logical pixels.
- `flutter build web --release --no-web-resources-cdn`: passed. Output: build/web. Rendering resources are bundled instead of fetched from Flutter's CDN.
- `flutter build apk --release`: failed: `No Android SDK found. Try setting the ANDROID_HOME environment variable.` See android-build.log. Install Android SDK, accept licences and rerun the command on a configured host.
- `flutter build ios --release --no-codesign`: unavailable on this Linux host; CLI reported `Could not find an option named "--release"` because the iOS build command is not enabled here. Run on macOS with Xcode.
- `flutter build windows --release`: failed: `"build windows" only supported on Windows hosts.` Run on Windows with Visual Studio's desktop C++ workload.

Tests verify implemented prototype behavior, not full compliance with the requested production acceptance criteria. See FEATURE_CHECKLIST.md. No real Android/iOS/Windows device tests or browser visual inspection were performed. No production deployment was made.

## Full-screen navigation update — 22 November 2026

Feature details and entry forms now use complete pages with app bars, back navigation and responsive action areas. Dedicated GoRouter paths cover subject workspaces, learning items and authorised conversations. Other supporting details and entry forms use Navigator page routes. Only destructive-action confirmations and practice-quiz submit confirmation remain modal.

17 tests pass, including full-screen subject/lesson/resource/assignment/quiz/result/conversation navigation at all five viewport sizes, assignment drafts/submission, lesson completion, chat persistence, unauthorised content rejection and input validation. Existing mock-data and production-scope limitations in FEATURE_CHECKLIST.md still apply.

## Light visual and communication refresh — 22 November 2026

19 tests pass, including the existing five-viewport workflow coverage plus light-theme defaults and staff/group inbox filtering at 360px with enlarged text. Static analysis is clean. Illustrations are original local vector artwork; no external assets or recurring animation tickers were introduced. Reduced-motion settings suppress the welcome transition and hover animation. Dark/system themes remain optional in Settings after the initial light migration.

## English / isiZulu language option — 22 November 2026

28 tests pass. Added catalogue and parameter checks, language persistence/account isolation, pre-login language selection, short-mobile onboarding and isiZulu navigation/detail layouts at 360, 390, 768, 1024 and 1440 pixels. Fixed an overflowing theme dropdown exposed by longer isiZulu labels. Flutter framework localizations and the application catalogue are bundled offline. No external translation service is used. Unknown authored resources keep their source language; school terminology should be reviewed by an isiZulu-speaking educator.

## Learner-facing copy update — 22 November 2026

Removed the status badge and presentation wording from application screens, resources and public web metadata in both languages. Added regression checks for prohibited interface labels. The current quick-sign-in password is Learn123!; the previous password is accepted for compatibility. Local-storage keys and mock repository internals are deliberately unchanged so existing learner data is retained. Local-only and non-delivery notices, practice assessment labels and unofficial report status remain explicit.
