# Lucky Dube learner application

Offline Flutter demonstration owned and developed by **Optimal Growth Technologies SA**. Intended presentation: 26 November 2026. This is an independent prototype with fictional people, sample subject combinations and temporary branding; no school endorsement is implied.

## Run

Install Flutter stable (Dart >=3.4; current Material APIs require Flutter >=3.35), then:

```sh
cd lucky_dube_learner
flutter pub get
flutter run -d chrome
```

Platform scaffolding for Android, iOS, web and Windows is included. No API keys, backend, remote fonts or runtime API requests are used. Package installation requires internet; the installed application does not. For web, use --no-web-resources-cdn so rendering assets are served locally; initial web installation still requires the local server.

## Sign-in credentials

| Grade | Learner number | Password |
|---|---|---|
| 8 | LD80001 | Learn123! |
| 9 | LD90001 | Learn123! |
| 10 | LD10001 | Learn123! |

Use Quick sign-in on the login screen. Settings also switches accounts. Remember me restores a session. Settings → Reset local information clears all locally saved state after confirmation. School-managed records are read-only. All dates displayed in the demo refer to South African school activities in November 2026.

## Demonstration walkthrough

1. Skip or complete onboarding and choose a grade.
2. Open Subjects → Mathematics → Lesson and mark complete.
3. Open Homework, write an answer, save a draft, submit and view local confirmation/history.
4. Complete a practice quiz; objective results are immediate and written answers await simulated marking. Published school marks are not changed.
5. Open Messages, choose an authorised channel, send a message and inspect the labelled simulated response.
6. Explore announcements, calendar, attendance and the performing arts portfolio.
7. Switch theme/account, restart and verify persisted preferences.

## Architecture and integration

`lib/app` owns Material themes and GoRouter. `lib/data` contains immutable configuration/records, a repository interface, mock dataset and SharedPreferences implementation. `lib/features` implements the adaptive learner screens and interaction dialogs. Riverpod injects the repository from main. School identity, grades, module labels, arts disciplines and palette defaults are centrally defined in SchoolConfiguration.

The current implementation is a prototype, not a finished clean-architecture migration. Screens still depend on MockRepository-specific methods. A future backend integration should expand LearnerRepository to expose typed asynchronous submissions, conversations, results and resources, replace the provider override, and move feature logic into individual feature controllers. Authenticate and authorise on the server in that future phase; local demo credentials are intentionally not secure authentication. No backend is included here.

Local state uses learner-prefixed keys, so account switching isolates messages, submissions, completion and notifications. Selected attachments currently retain filenames only, not persistent file bytes; do not delete originals expecting them to be available from the app. Concern reports stay on this device and are never delivered to staff. Never enter real sensitive information.

## Build and quality checks

```sh
flutter pub get
dart format .
flutter analyze
flutter test
flutter build web --release --no-web-resources-cdn
flutter build apk --release
# macOS with Xcode:
flutter build ios --release --no-codesign
# Windows with Visual Studio desktop workload:
flutter build windows --release
```

See docs/VALIDATION.md for actual execution results and docs/FEATURE_CHECKLIST.md for scope gaps. Do not infer build success from the commands above.

## Vercel web deployment

Vercel serves the tested `web-dist/` release bundle. No server, APIs or credentials are needed. To update it, run `flutter build web --release --no-web-resources-cdn`, replace `web-dist/` with `build/web/`, then commit both source and the release bundle. Source repository: https://github.com/Nsukumanzini/lucky-dube. Git-based automatic deployment requires connecting that repository to the existing Vercel project. The current release was deployed directly through the connected Vercel API. The GitHub repository is public; the deployed demo is accessible using its Vercel production URL subject to account deployment protection.

Live production demo: https://lucky-dube.vercel.app/
See docs/DEPLOYMENT.md for deployment status and the pending GitHub step.

## Screen-based feature navigation

Subject workspaces provide seven tabs: overview, lessons, materials, assignments, assessments, results and discussions. Learning content and conversations open on dedicated routes that can be refreshed or linked directly after sign-in. Supporting details (events, announcements, portfolios, schedule entries, privacy and support receipts) and entry forms open as full pages with back navigation. Only short reset/delete and quiz-submission confirmations remain dialogs. Back navigation preserves local learner state; drafts are saved explicitly using Save draft.

## Learner visual refresh

Light mode is now the default, with white surfaces, a soft-blue welcome panel and teal/coral/violet learning accents. The first launch after this update migrates existing theme preferences to light once; subsequent explicit theme selections still persist. Original layered-book artwork is painted locally, with a finite entrance transition and a gentle desktop hover effect. Both respect the device's reduced-motion setting and require no hosted images, animation service or 3D runtime.

Messages now has staff/group filters, contextual previews, read indicators, channel identity, date separators, left/right bubbles, attachment styling, local delivery labels and a keyboard-aware composer. Educator responses remain simulated. Conversation options retain mute and private local reporting.

## English and isiZulu

Choose **English** or **isiZulu** from the language control before sign-in, in the main header, or in **Profile → Settings → Language / Ulimi**. Switching language takes effect immediately and does not reset learner work. The device remembers the pre-sign-in preference; each signed-in learner has their own persisted choice. Account switching restores that learner's preference. Resetting demonstration data clears language preferences too.

Flutter's offline localization delegates translate built-in controls. Application text is maintained in `lib/app/localization/zu.json`, with a generated Dart catalogue (`python3 tool/generate_catalog.py`, then `dart format lib/app/localization/catalog.dart`). English source labels remain canonical for routes, IDs, filtering and scoring. Exact translations are preferred; composed labels use single-pass phrase translation with names, learner numbers and numeric values preserved. Unknown authored content falls back to its original language. Learner-written chat messages and attachment filenames are never automatically translated. No translation API or internet connection is used.

The catalogue includes UI controls, demonstration lesson instructions, quiz questions, support guidance and school notices. Have an isiZulu-speaking educator review terminology and school-specific wording before wider school use; external learning materials should be authored and reviewed in their intended language rather than treated as automatically translated curriculum.

## Learner-facing wording

Visible status labels have been removed from the learner interface. Quick sign-in uses Learn123!; the previous access password remains accepted for compatibility. Local-only storage, non-delivery notices and the unofficial report label remain accurate. Internal mock repository classes and the legacy preference key are retained to preserve existing data and development architecture.
