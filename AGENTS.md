# AGENTS.md

## Project Mission

EzCharge is a Flutter/Firebase EV charging app being refactored from a legacy,
screen-heavy codebase into a clean MVVM + Provider architecture.

The team goal is not only to make features work. Every change should move the
project toward clearer ownership:

- `views/` render UI and collect user intent.
- `viewmodels/` hold screen/application state and orchestrate use cases.
- `services/` own Firebase, HTTP, storage, platform APIs, and other external
  integrations.
- `models/` define typed app/domain data and serialization.
- `core/` contains reusable constants, widgets, routes, and utilities.

Prefer small, behavior-preserving refactors over broad rewrites. This app is
legacy and user-facing, so migration should be incremental and verifiable.

## Current Codebase Snapshot

The app already has the beginnings of the target structure:

- `lib/main.dart` wires `MultiProvider` and registers core `ChangeNotifier`
  viewmodels such as `AuthViewModel`, `ChargingStationViewModel`,
  `EmergencyRequestViewModel`, `TrackingViewModel`, `OnboardingViewmodel`, and
  `ApplicationViewmodel`.
- `lib/services/auth_service.dart` and `lib/services/station_service.dart`
  already isolate some Firebase access.
- `lib/models/` contains typed models for users, admins, customers, stations,
  bays, notifications, drivers, and emergency requests.
- `lib/views/` contains most feature screens, including auth, onboarding,
  admin, reports, customer charging flows, profile, rewards, ratings, and
  emergency request flows.
- `lib/core/` contains shared routes, constants, widgets, and utilities.

Known legacy hotspots to handle carefully:

- Many screens still call `FirebaseFirestore`, `FirebaseAuth`,
  `FirebaseStorage`, `ImagePicker`, `http`, and `Navigator` directly.
- Some viewmodels still own external APIs directly instead of delegating to a
  service, especially station, emergency request, tracking, and notification
  flows.
- Some viewmodels receive `BuildContext` or show UI pickers/dialogs; this should
  be migrated toward UI-owned navigation/picker behavior plus viewmodel-owned
  state transitions.
- `provider` is the target state management tool. `get` is still in
  `pubspec.yaml`; avoid introducing new GetX usage during the refactor.
- Firestore field names are inconsistent in places (`CustomerID` vs
  `customerID`, `Status` vs `status`, `Charger` subcollections, etc.). Preserve
  existing backend contracts unless a migration plan is explicit.

## Architecture Rules

### Views

Views should:

- Build widgets, layouts, dialogs, sheets, and form controls.
- Use `context.watch<T>()`, `context.read<T>()`, `Consumer<T>`, or
  `Selector<T, R>` from Provider.
- Own ephemeral widget-only objects such as `TextEditingController`,
  `FocusNode`, animation controllers, local dialog state, and `BuildContext`.
- Trigger intent methods on viewmodels, such as `submitPhoneNumber`,
  `createRequest`, `loadStations`, or `selectPaymentMethod`.
- Handle navigation after a viewmodel returns a success/failure result.

Views should not:

- Query Firestore/Auth/Storage directly.
- Build Firestore document maps inline for business operations.
- Contain fee calculations, capacity rules, authentication lookup rules,
  reservation status rules, or backend ID generation.
- Pass `BuildContext` into a viewmodel unless there is no practical migration
  path yet.

### Viewmodels

Viewmodels should:

- Extend `ChangeNotifier`.
- Expose immutable or read-only state through getters where practical.
- Keep loading, error, selected item, current user, form state, and derived UI
  state.
- Depend on services through constructor injection, with reasonable defaults
  during the migration.
- Convert service responses into screen-ready state.
- Return typed outcomes to the view for navigation and snackbars instead of
  navigating directly.
- Dispose stream subscriptions and controllers they own.

Viewmodels should not:

- Instantiate Firebase clients directly in new or refactored code.
- Show dialogs, date pickers, image pickers, or navigation flows.
- Depend on widgets except for `ChangeNotifier` and Flutter primitives that
  represent state.
- Swallow exceptions silently. Store user-facing errors and log diagnostic
  details through `AppLogger`.

### Services

Services should:

- Own direct calls to Firebase Auth, Cloud Firestore, Firebase Storage, HTTP
  APIs, Google Maps APIs, image upload APIs, and platform integrations.
- Hide Firestore collection paths and field names behind typed methods.
- Return models, DTOs, streams, or typed operation results.
- Keep serialization details close to models.

Services should not:

- Import screens.
- Navigate.
- Call `notifyListeners`.
- Build widgets or expose Flutter UI state.

### Models

Models should:

- Use typed fields and constructors.
- Keep `fromMap`, `fromFirestore`, `toMap`, or `toFirestore` logic consistent.
- Preserve legacy Firestore field names until a deliberate migration is planned.
- Prefer enums for controlled statuses, with safe fallback parsing.

### Routing

- Keep named route constants in `lib/core/routes/app_routes.dart`.
- Avoid scattering raw `MaterialPageRoute` for flows that can reasonably become
  named routes.
- Do not move navigation into services.
- During migration, navigation may remain in views while viewmodels return
  result objects or booleans.

### State Management

- Use Provider and `ChangeNotifier` for the refactor.
- Register app-level providers in `main.dart`.
- Use local providers for feature-specific state when global lifetime is not
  needed.
- Avoid adding Riverpod, Bloc, Redux, GetX state, or another state-management
  pattern unless the team explicitly decides to change direction.

## Refactor Priorities

1. Move direct Firebase/Auth/Storage/HTTP calls out of `views/` into services.
2. Move orchestration and UI state out of large `StatefulWidget`s into
   viewmodels.
3. Remove direct Firebase clients from viewmodels by adding or expanding
   services.
4. Make models responsible for consistent serialization and enum parsing.
5. Replace scattered route construction with named routes where practical.
6. Add focused tests around service parsing, viewmodel state transitions, and
   risky business rules before changing behavior.

Good first migration candidates:

- `lib/views/application/home_screen.dart`
- `lib/views/application/customer/ezcharge/station_screen.dart`
- `lib/views/application/customer/ezcharge/payment_screen.dart`
- `lib/views/application/customer/ezcharge/check_detail.dart`
- `lib/views/application/check_in_screen.dart`
- `lib/views/application/reward_screen.dart`
- `lib/views/application/notification_screen.dart`
- `lib/views/admin/admin_charging_station.dart`
- `lib/views/admin/admin_rewards.dart`
- report screens under `lib/views/reports/`

## Team Roles

### @pm

The product/refactor lead. Owns scope, sequencing, acceptance criteria, and
behavior preservation.

Responsibilities:

- Break legacy refactor work into small feature slices, such as auth, station
  management, rewards, reports, emergency requests, or payment history.
- Define what must remain behaviorally identical before each refactor begins.
- Identify the user role affected by the change: customer, admin, driver, or
  shared app shell.
- Call out Firebase collections, documents, and fields involved in the slice.
- Decide whether a change is pure refactor, bug fix, UI improvement, or backend
  contract migration.
- Keep Provider + MVVM as the target architecture unless the team explicitly
  agrees otherwise.
- Prefer incremental modernization over large rewrites.

Acceptance criteria template:

- The screen still renders the same core information.
- Loading, empty, error, and success states are handled.
- No new direct Firebase/Auth/Storage/HTTP access is added to views.
- Viewmodels expose state and intent methods; services own external APIs.
- Existing Firestore field names and document paths remain compatible.
- `flutter analyze` and relevant tests pass, or failures are documented.

### @developer

The implementation agent. Makes scoped code changes that steadily migrate the
app toward MVVM + Provider.

Responsibilities:

- Read the existing feature before editing. Preserve user-facing behavior unless
  the task explicitly changes it.
- Create or expand services for Firebase, Storage, Auth, HTTP, Maps, image
  upload, and other integrations.
- Keep widgets thin: UI, input collection, local controllers, and navigation
  only.
- Move business rules into viewmodels or domain helpers, and external API calls
  into services.
- Inject services into viewmodels through constructors. Keep default production
  constructors where needed to avoid huge call-site churn.
- Use typed models instead of raw `Map<String, dynamic>` in viewmodels and views
  whenever practical.
- Prefer `AppLogger` for diagnostics instead of scattered `debugPrint` in
  refactored logic.
- Keep imports ordered and relative, matching `analysis_options.yaml`.
- Do not introduce new GetX usage.
- Add focused tests when changing non-trivial viewmodel logic, parsing, status
  transitions, fee calculations, or Firestore mapping.

Implementation checklist:

- Locate direct external API calls in the target screen/viewmodel.
- Add or update a service method with typed inputs and outputs.
- Update the viewmodel to call the service and expose loading/error/data state.
- Update the view to consume Provider state and call viewmodel intent methods.
- Keep navigation, dialogs, and pickers at the UI boundary.
- Run `dart format` on changed Dart files.
- Run `flutter analyze` and relevant `flutter test` targets when feasible.

### @tester

The testability agent. Verifies that each refactored module is easy to test and
has enough automated coverage to protect behavior.

Responsibilities:

- Identify whether the target module can be tested without launching the full
  app, real Firebase, real Storage, real HTTP, or real device APIs.
- Prefer viewmodel and service-unit tests for refactor slices. Widget tests are
  useful when UI states, Provider wiring, or navigation decisions are part of
  the change.
- Check that services are injectable or mockable before tests are written.
- Check that viewmodels expose deterministic state transitions that can be
  asserted with `flutter test`.
- Add or request fakes/mocks for Firebase, Auth, Storage, HTTP, Maps, image
  picking, and time-dependent behavior when those dependencies block testing.
- Verify loading, success, empty, and error states for changed viewmodels.
- Verify model parsing and serialization when Firestore field mappings change
  or are touched.
- Run targeted tests first, then broader `flutter test` when practical.

Testability checklist:

- Can the module be constructed with fake services?
- Can the main behavior be tested without a `BuildContext`?
- Are Firebase collection paths and field maps hidden behind services?
- Are async states observable through viewmodel getters?
- Are errors represented as testable state instead of only `debugPrint` output?
- Does `flutter test` pass for the touched module or suite?

### @reviewer

The architecture and quality reviewer. Reviews for regressions and whether the
change truly moves the codebase toward MVVM + Provider.

Review priorities:

- Behavior regression risk, especially auth, payments, reservations, charging
  sessions, station capacity, rewards, reports, and account verification.
- Direct Firebase/Auth/Storage/HTTP usage in views.
- New or remaining direct external API clients in viewmodels where a service
  should own them.
- Viewmodels that navigate, show dialogs, use `BuildContext`, or trigger
  pickers without a clear transition reason.
- Raw Firestore maps leaking into widgets.
- Firestore field-name or collection-path changes that could break existing
  data.
- Missing loading, empty, error, and success states.
- Missing disposal of stream subscriptions, controllers, or listeners.
- Excessive rebuilds from broad `context.watch` usage where `Selector` or
  smaller widgets would be clearer.
- Tests missing around changed parsing, state transitions, and business rules.

Review stance:

- Findings first, ordered by severity.
- Include file and line references.
- Distinguish required fixes from optional cleanup.
- Do not request broad rewrites when a smaller migration step is safer.
- Approve incremental progress when the code is cleaner, behavior is preserved,
  and the remaining legacy debt is explicitly understood.

## Definition of Done

A refactor slice is done when:

- It preserves the intended user behavior.
- Views are thinner than before.
- External API access has moved closer to services.
- State and business orchestration have moved closer to viewmodels.
- Models are used for structured data where reasonable.
- Provider remains the state-management mechanism.
- The changed module is easy to exercise with `flutter test`, or the remaining
  testability blockers are documented.
- Formatting and analysis have been run, or any blockers are documented.
- Any risky behavior changes have focused tests or a clear manual verification
  note.

## Commands

Common local checks:

```sh
dart format lib
flutter analyze
flutter test
```

Run narrower commands when the change is scoped, but do not skip analysis for
architecture refactors unless there is a documented blocker.

## Working Agreement

- Keep changes small and understandable.
- Prefer clarity over clever abstractions.
- Do not rename Firestore fields casually.
- Do not mix unrelated UI redesigns into architecture refactors.
- Leave unrelated dirty files untouched.
- When in doubt, preserve behavior first, then improve structure.

## Automated Workflow Pipeline (The Relay Race)
1. **Trigger**: When User says "Approved" or "Approve the plan", **@pm** splits the tasks and passes them to **@developer**.
2. **Implementation**: **@developer** creates an isolated branch/worktree, refactors the code, and runs `dart format`. Once done, hands over to **@reviewer**.
3. **Static Review & Test**: **@reviewer** calls Flutter MCP to run `dart analyze`. If warnings/errors exist, **@reviewer** directly rejects it and kicks it back to **@developer** with logs. This loops until 0 warnings.
4. **Verification**: Once code is clean, **@tester** runs `flutter test`. If tests fail, loops back to **@developer**.
5. **Acceptance**: When all checks pass, **@reviewer** pings **@pm** for final verification.
6. **Report**: **@pm** merges the code, formats a summary report, and presents it to the User. The other agents remain silent.