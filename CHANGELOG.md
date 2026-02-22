## 0.1.2

* **Fix**: `rigid_no_unbounded_column` now recognizes `mainAxisSize: MainAxisSize.min` as a valid bounded pattern, eliminating false positives for `Column` inside `SingleChildScrollView`.

## 0.1.1

* **Framework-agnostic**: All rule messages, docs, and examples no longer mandate Riverpod specifically. setState/ChangeNotifier bans apply regardless of chosen state management.
* **Config fix**: State discipline rules now correctly enable for `bloc` and `provider` in balanced preset (previously only `riverpod`).
* **pub.dev metadata**: Added homepage, topics, issue_tracker. Install via `rigid_dart: ^0.1.1`.
* **Archive trimmed**: `.pubignore` excludes 2MB header image. Package size: 27KB.

## 0.1.0

* Initial release.
* 23 strict analyzer rules across 5 phases:
  - **Layout Safety** (3 rules): Expanded constraints, unbounded columns, text field sizing
  - **State Discipline** (5 rules): setState ban, ChangeNotifier ban, async state exhaustiveness, BuildContext safety, dispose enforcement
  - **Architecture** (6 rules): Hardcoded colors/styles, magic numbers, test coverage, layer boundaries, DI leakage
  - **Freshness** (4 rules): WillPopScope, withOpacity, dynamic, print bans
  - **Quality** (5 rules): Widget line limits, raw async, test assertions, list keys, hardcoded strings
* Configurable presets: `strict`, `balanced`, `safety`, `custom`
* 3 quick fixes: WillPopScope → PopScope, withOpacity → withValues, dynamic → Object?
* Optional PATH wrapper to block `flutter run` until clean
* `rigid_dart.yaml` configuration file support
