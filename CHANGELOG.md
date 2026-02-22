## 0.1.0

* Initial release.
* 23 strict analyzer rules across 5 phases:
  - **Layout Safety** (3 rules): Expanded constraints, unbounded columns, text field sizing
  - **State Discipline** (5 rules): setState ban, ChangeNotifier ban, AsyncValue exhaustiveness, BuildContext safety, dispose enforcement
  - **Architecture** (6 rules): Hardcoded colors/styles, magic numbers, test coverage, layer boundaries, DI leakage
  - **Freshness** (4 rules): WillPopScope, withOpacity, dynamic, print bans
  - **Quality** (5 rules): Widget line limits, raw async, test assertions, list keys, hardcoded strings
* Configurable presets: `strict`, `balanced`, `safety`, `custom`
* 3 quick fixes: WillPopScope → PopScope, withOpacity → withValues, dynamic → Object?
* Optional PATH wrapper to block `flutter run` until clean
* `rigid_dart.yaml` configuration file support
