# AGENTS.md

## Project Mission

EzCharge is a Flutter/Firebase EV charging app being refactored from a legacy, screen-heavy codebase into a clean **MVVM + Provider** architecture.

The team goal is not only to make features work. Every change should move the project toward clearer ownership:
* **views/**: Render UI and collect user intent.
* **viewmodels/**: Hold screen/application state and orchestrate use cases.
* **services/**: Own Firebase, HTTP, storage, platform APIs, and other external integrations.
* **models/**: Define typed app/domain data and serialization.
* **core/**: Contains reusable constants, widgets, routes, and utilities.

**Principle:** Prefer small, behavior-preserving refactors over broad rewrites. This app is legacy and user-facing, so migration should be incremental and verifiable.

---

## Current Codebase Snapshot

The app already has the beginnings of the target structure:
* `lib/main.dart` wires `MultiProvider` and registers core `ChangeNotifier` viewmodels such as `AuthViewModel`, `ChargingStationViewModel`, `EmergencyRequestViewModel`, `TrackingViewModel`, `OnboardingViewmodel`, and `ApplicationViewmodel`.
* `lib/services/auth_service.dart` and `lib/services/station_service.dart` already isolate some Firebase access.
* `lib/models/` contains typed models for users, admins, customers, stations, bays, notifications, drivers, and emergency requests.
* `lib/views/` contains most feature screens, including auth, onboarding, admin, reports, customer charging flows, profile, rewards, ratings, and emergency request flows.
* `lib/core/` contains shared routes, constants, widgets, and utilities.

**Known legacy hotspots to handle carefully:**
* Many screens still call `FirebaseFirestore`, `FirebaseAuth`, `FirebaseStorage`, `ImagePicker`, `http`, and `Navigator` directly.
* Some viewmodels still own external APIs directly instead of delegating to a service, especially station, emergency request, tracking, and notification flows.
* Some viewmodels receive `BuildContext` or show UI pickers/dialogs; this should be migrated toward UI-owned navigation/picker behavior plus viewmodel-owned state transitions.
* **Provider** is the target state management tool. `get` is still in `pubspec.yaml`; **DO NOT** introduce new GetX usage during the refactor.
* Firestore field names are inconsistent in places (`CustomerID` vs `customerID`, `Status` vs `status`, `Charger` subcollections, etc.). **Preserve existing backend contracts** unless a migration plan is explicit.

---

## Architecture Rules

### UI & Styling Rules (Strict)
* **Scope-based Reusability**: 
  * If a widget is shared across **multiple features**, it belongs in `lib/core/widgets/`.
  * If a widget is only reused within a **single feature**, keep it inside that feature's directory (e.g., `lib/views/auth/widgets/`). Do not pollute `core/`.
* **Design Tokens & Constants**: 
  * NEVER hardcode raw colors (e.g., `Colors.blue`) or inline fonts. Use global themes/styles.
  * Repeated general strings (e.g., "Loading...", "Confirm") go to `core/constants/`. Feature-specific labels stay in the feature level.

### Views
* **Should:** Build widgets, layouts, dialogs, sheets, and form controls; use Provider's `context.watch<T>()`, `context.read<T>()`, etc.; own ephemeral widget-only objects (e.g., `TextEditingController`, `FocusNode`); trigger intent methods on viewmodels; handle navigation after a viewmodel returns a success/failure result.
* **Should Not:** Query Firestore/Auth/Storage directly; build Firestore document maps inline for business operations; contain fee calculations, authentication lookup, or reservation rules; pass `BuildContext` into a viewmodel unless there is no practical migration path yet.

### Viewmodels
* **Should:** Extend `ChangeNotifier`; expose immutable/read-only state through getters; keep loading, error, and UI state; depend on services through constructor injection; return typed outcomes to the view for navigation/snackbars instead of navigating directly; dispose stream subscriptions and controllers they own.
* **Should Not:** Instantiate Firebase clients directly; show dialogs, pickers, or handle navigation flows; depend on widgets (except `ChangeNotifier` and state primitives); swallow exceptions silently (use `AppLogger`).

### Services
* **Should:** Own direct calls to Firebase, HTTP APIs, Google Maps, image uploads, and platform integrations; hide Firestore paths and field names behind typed methods; return models, DTOs, streams, or typed operation results.
* **Should Not:** Import screens; navigate; call `notifyListeners`; build widgets or expose Flutter UI state.

### Models & Routing
* **Models**: Use typed fields and constructors; keep `fromMap` / `toMap` logic consistent; preserve legacy Firestore field names until deliberate migration; prefer enums for controlled statuses with safe fallback parsing.
* **Routing**: Keep named route constants in `lib/core/routes/app_routes.dart`; avoid scattering raw `MaterialPageRoute`; **never** move navigation into services.

---

## Team Roles & Responsibilities

### @pm
**The product/refactor lead.** Owns scope, sequencing, acceptance criteria, and behavior preservation.
* **Responsibilities:** Break legacy refactor work into small feature slices (e.g., auth, station, payment); define what must remain behaviorally identical before each refactor begins; identify the affected user role; enforce the Provider + MVVM target architecture.
* **Acceptance Criteria:** Screen renders the same core info; loading/empty/error/success states are handled; no new direct Firebase access in views; `flutter analyze` passes with 0 warnings, and relevant tests pass.

### @developer
**The implementation agent.** Makes scoped code changes that steadily migrate the app toward MVVM + Provider.
* **Responsibilities:** Read the existing feature before editing to preserve user-facing behavior; create or expand services to isolate external APIs; keep widgets thin and move business logic to viewmodels; inject services into viewmodels via constructors; **write focused unit tests for refactored ViewModels by mocking Services (No live DB/Network allowed)**; run `dart format`.
* **Development Flow:**
  1. Upon receiving a task, branch off from the current branch into a **temporary feature branch**.
  2. Implement refactoring, write corresponding mocked unit tests, run local formatting, and perform initial self-testing on this temporary branch.
  3. Once complete, commit changes and hand the temporary branch over to `@reviewer`.

### @reviewer
**The architecture, quality, business-logic, and test reviewer (Combined with Tester role).** Reviews for regressions, ensures the change aligns with MVVM + Provider, verifies module testability, and acts as the project's Reality Checker.
* **Responsibilities:**
  * **Code Review:** Check for direct Firebase usage in views, external clients leaking into viewmodels, `BuildContext` violations, missing disposal logic, or accidental Firestore field renames. Reject immediately if live DB/network clients are instantiated without services.
  * **Testing & Verification:** Verify that dependencies are properly mocked; **ensure `flutter test` is executed on the branch** to verify loading/success/error flows and mapping serialization without crashing on missing Firebase initialization.
  * **🧩 Human & Domain Sanity Audit (Generic Logic Review):** Actively audit the developer's implementations for "common-sense" and logical gaps. Specifically inspect:
    - **Intuitive Workflow Completeness:** Ensure flows are designed around user goals, not technical limitations. (e.g., If a goal logically requires a dependency—like eating soup requires a spoon, or entering a system requires a valid identity—the system must automatically facilitate or resolve that dependency rather than outputting a raw obstruction or error).
    - **Graceful Failure Fallbacks:** Check that error handling acts as a "soft net" instead of a harsh dead-end. Code must anticipate obvious alternative paths when an initial action cannot proceed.
    - **Zero Leakage of Raw Exceptions:** Review that backend/database specific technical errors are always caught, mapped, and translated into meaningful context before reaching the user interface.
  * **Inspect widget placement:** Ensure local widgets aren't leaked into `core/`, and global widgets aren't duplicated across features.
* **Review Stance:** Findings first, ordered by severity with file and line references. If an implementation follows syntax rules but violates basic operational common sense, intuitive workflows, or real-world logic, **REJECT** the code immediately and make the developer fix the logical gap. Approve incremental progress only when code is clean, behavior is fully tested with mocks, and remaining legacy debt is explicitly documented.
---

## Automated Workflow Pipeline (The Relay Race)

1. **Trigger:** When the User says "Approved" or "Approve the plan", `@pm` splits the tasks and passes them to `@developer`.
2. **Branch & Implementation:** `@developer` creates and switches to a **temporary branch** based on the current branch. `@developer` refactors the code, runs `dart format`, and hands the temporary branch over to `@reviewer`.
3. **Review & Test:** `@reviewer` calls the Flutter MCP to run `dart analyze` on the temporary branch. If warnings/errors exist, `@reviewer` rejects it immediately and kicks it back to `@developer` with logs. This loops until 0 warnings. Once clean, `@reviewer` runs `flutter test`. If tests fail, it goes back to `@developer`.
4. **Acceptance:** When all checks and tests pass, `@reviewer` pings `@pm` for final verification and business behavior acceptance on that branch.
5. **Merge & Cleanup:** After verification, `@pm` safely merges the temporary branch into the `current branch`, **deletes the temporary branch completely**, and presents a summary report to the User. The other agents remain silent.