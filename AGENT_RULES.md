# AGENT_RULES.md: Kade Ledger

You are helping a student build **Kade Ledger**, an offline-first Flutter app for small shop owners in Sri Lanka. The student is learning while building, so correctness, simplicity and explanations matter more than speed or cleverness.

If anything in a task is unclear, **ask a question before writing code**. Never guess.

---

## 1. Product summary

Shop owners track customers who buy on credit, record credit and payments, track stock, see a dashboard, and share a PDF statement with a customer. It must work fully offline. Cloud sync comes later.

Currency: Sri Lankan rupees (LKR). Languages: English first, Sinhala later.

---

## 2. Fixed tech stack (do not deviate)

| Purpose | Package |
|---|---|
| Framework | Flutter (stable channel) and Dart |
| State management | `flutter_riverpod` (Notifier / AsyncNotifier). **No code generation for Riverpod.** |
| Navigation | `go_router` |
| Local database | `drift` with SQLite (plus `drift_dev` and `build_runner`) |
| IDs | `uuid` (v4) |
| Formatting | `intl` |
| Material widgets | `material_ui` (see import rule below) |
| Charts (phase 2) | `fl_chart` |
| PDF and share (phase 4) | `pdf`, `printing`, `share_plus` |
| Notifications (phase 4) | `flutter_local_notifications` |
| Backend (phase 3 only) | Supabase (`supabase_flutter`) |
| Tests | `flutter_test`, `mocktail` |
| Lints | `flutter_lints` |

Rules about packages:
- **Do not add any package that is not in this table** without asking and getting a yes.
- **Never guess package versions or APIs from memory.** Before adding a package, check its current page on pub.dev and its official docs, and follow the current setup steps. Use `flutter pub add <package>` so the latest compatible version is chosen.
- Do not use `freezed`, `json_serializable`, `bloc`, `provider`, `get`, `getx`, `hive`, `isar` or `sqflite`.
- **Material import rule:** import Material widgets from `package:material_ui/material_ui.dart`. **Never** import `package:flutter/material.dart` (deprecated since Flutter 3.47).
- Use null safety and modern Dart (records and pattern matching are fine where they make code clearer).

---

## 3. Architecture (strict)

Feature-first folders. Each feature has three layers.

```
lib/
  core/            theme, router, utils, money formatting, error types
  data/            app_database.dart (Drift), sync (phase 3 only)
  features/
    customers/
      presentation/   screens, widgets, Riverpod notifiers/providers
      domain/         entities (plain immutable Dart classes), use cases, repository interfaces
      data/           Drift tables/DAOs mapping, repository implementations
    transactions/
    items/
    dashboard/
    statements/
    auth/             (phase 3)
  l10n/
  main.dart
test/
```

Layer rules:
1. **Presentation** never imports Drift, Supabase or any data-layer file. It talks only to Riverpod providers that expose repository interfaces.
2. **Domain** is plain Dart. No Flutter imports, no Drift imports.
3. **Data** implements the domain repository interfaces. Drift types must not leak outside the data layer. Map them to domain entities.
4. **Business logic** (balance calculation, totals, validation) lives in the domain layer or in repositories, **never inside widgets**. Domain **use cases** are for **writes that carry business rules** (for example `AddCustomer`, `RecordCredit`, `RecordPayment`); they are small plain Dart classes that validate inputs and depend only on repository interfaces. Simple reads (such as listing customers or watching a balance) may go through a repository provider directly—do not create one-line pass-through use case classes.
5. One screen = one file for the screen, with reusable widgets in separate files. No file over about 300 lines; split it.
6. Dependencies are provided through Riverpod providers. No global singletons.

---

## 4. Data rules

- **Money is stored as integer minor units** (rupees x 100) in a field named `amountMinor` or similar. **Never use `double` for money.** Format only at display time with `intl`.
- **Balance is never stored.** It is always computed as the sum of `credit` transactions minus the sum of `payment` transactions for a customer.
- Primary keys are **UUID v4 strings** generated on the device.
- Every table has `createdAt` and `updatedAt` (UTC). Every syncable table has a nullable `deletedAt`. **Deleting means setting `deletedAt` (soft delete).** Queries must exclude soft-deleted rows by default.
- Update `updatedAt` on every change.
- Transaction types are exactly `credit` and `payment`. Amounts must be positive; the type decides the direction.
- Validate input: customer name required, amount greater than zero, phone optional but must look like a phone number if given.
- Any schema change needs a **Drift migration** with a version bump and a migration test. **Never delete or reset the user's database** to "fix" a schema problem.

### Tables

| Table | Fields |
|---|---|
| customers | id, name, phone, note, createdAt, updatedAt, deletedAt |
| transactions | id, customerId, type, amountMinor, note, date, dueDate (nullable), createdAt, updatedAt, deletedAt |
| items | id, name, unitPriceMinor, quantity, lowStockThreshold, createdAt, updatedAt, deletedAt |

(`sync_queue` is added only in phase 3.)

---

## 5. Offline-first rule

The local Drift database is the **only source of truth for the UI**. The UI reads and writes only local data. Cloud sync (phase 3) runs in the background and never blocks the UI. **Do not add any Supabase or network code until the task explicitly says phase 3.**

---

## 6. Phases (work only on the current phase)

| Phase | Scope |
|---|---|
| 0 | Project setup, folders, lints, Git, CI skeleton |
| 1a | Design document (`docs/DESIGN.md`) and architecture rules updates |
| 1b | Drift database, customer domain/data layers, `AddCustomer` use case, unit tests (no UI) |
| 1c | Customer list screen and customer form, search, validation, routes, widget tests |
| 1d | Transactions entity/repository, `RecordCredit`/`RecordPayment` use cases, balance, customer detail screen, tests |
| 2 | Items and dashboard |
| 3 | Supabase auth and sync |
| 4 | PDF statements, reminders, Sinhala |
| 5 | Tests, README, release APK |

**Never implement something from a later phase early.** If a task seems to need it, stop and ask.

---

## 7. How to work on every task

1. **Restate the task** in your own words in 2-3 lines.
2. **List the files you will create or change** and wait for a yes if the list has more than 5 files.
3. Make the **smallest change** that completes the task. No unrelated refactors, renames, formatting sweeps or "improvements".
4. Write or update **tests** for any business logic.
5. Run `dart format .`, `flutter analyze` and `flutter test`. **All must pass with zero errors and zero warnings.**
6. If something fails, report the **exact error output**. Do not hide it, skip it, or disable it.
7. Finish with this report, always in this format:
   - **Changed:** files created/modified and what each does
   - **Why:** the reasoning for the key decisions, in plain language
   - **Run it:** exact commands
   - **Check it manually:** 3-5 things to try in the app, including edge cases
   - **Not done / risks:** anything incomplete or uncertain

Do not say a task is complete unless analyze and tests pass and you actually ran them. If you could not run something, say so.

---

## 8. Forbidden actions

- Deleting or rewriting files unrelated to the task
- Hand-editing generated files (`*.g.dart`). Regenerate with `dart run build_runner build --delete-conflicting-outputs`
- Disabling lints, skipping tests, adding `// ignore` comments, or loosening analysis options to make errors go away
- Downgrading Flutter, Dart or package versions to dodge an error without asking
- Using `git push --force`, `git reset --hard`, rewriting history, or committing unless asked
- Running destructive shell commands outside the project folder
- Hardcoding secrets, API keys or URLs. Secrets go through `--dart-define` or env files that are **gitignored**
- Placeholder or fake implementations (`// TODO`, `return 0`, stub data) presented as finished. If you stub something, label it clearly as a stub in the report
- Inventing APIs. If you are not sure a function or parameter exists, read the package docs or source first
- Adding features, screens or packages that were not requested
- Silencing errors with empty `catch` blocks. Handle errors and surface them to the UI

---

## 9. Code style

- Follow `flutter_lints`. Prefer `const` constructors where possible.
- Clear names. Short functions. Comments explain **why**, not what.
- Handle loading, empty and error states on every screen that shows data (use `AsyncValue`).
- Material 3, a simple clean theme, support for light and dark mode.
- Layouts must work on small phones and use no hardcoded pixel sizes that break on other screens.
- No text hardcoded in widgets once localization is set up (phase 4). Until then, keep strings in one place so they are easy to move.

---

## 10. Testing rules

- Unit tests for: balance calculation, money formatting, validation, repository logic (use an in-memory Drift database).
- Widget tests for the main screens once they exist.
- Tests must check real behavior. No tests that only assert `true`.
- Do not change a test just to make it pass. If a test fails, find out whether the code or the test is wrong and explain which.

---

## 11. Git conventions

- One feature or fix per commit. The student will commit; you only suggest the message.
- Commit message format: `feat: add customer list screen`, `fix: correct balance rounding`, `test: add balance tests`, `chore: update lints`.

---

## 12. Learning mode

The student is rebuilding their skills. After each task:
- Explain the 2-3 most important concepts used (for example, what a Riverpod `Notifier` does here) in simple language.
- Point out one thing the student should try to write by hand next time.
- Never dump a huge amount of code without explaining its structure first.

