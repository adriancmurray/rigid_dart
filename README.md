# Rigid Dart

Rust-grade guardrails for Dart/Flutter. A `custom_lint` plugin that enforces layout safety, state discipline, architecture boundaries, and modern Dart idioms as hard analyzer errors.

## Why

Dart's compiler is lenient. Agents (and humans) ship runtime crashes that Rust would catch at compile time. Rigid Dart closes this gap with 12 lint rules that act as a synthetic borrow checker for Flutter.

## Rules

| Phase | Rule | Severity | Catches |
|-------|------|----------|---------|
| **Layout** | `rigid_no_expanded_outside_flex` | ERROR | `Expanded` outside `Row`/`Column`/`Flex` |
| | `rigid_no_unbounded_column` | WARNING | Nested scrollables without constraints |
| | `rigid_constrained_text_field` | ERROR | `TextField` in `Row` without width |
| **State** | `rigid_no_set_state` | ERROR | `setState()` calls (use Riverpod) |
| | `rigid_no_change_notifier` | ERROR | `ChangeNotifier` subclass/mixin |
| | `rigid_exhaustive_async` | ERROR | `.value` on `AsyncValue` without `.when()` |
| **Architecture** | `rigid_no_hardcoded_colors` | ERROR | `Color(0xFF...)` / `Colors.*` outside theme |
| | `rigid_no_hardcoded_text_style` | WARNING | Raw `fontSize` literals outside theme |
| | `rigid_no_magic_numbers` | WARNING | Magic numbers in layout params |
| **Freshness** | `rigid_no_will_pop_scope` | ERROR | Deprecated `WillPopScope` |
| | `rigid_no_with_opacity` | ERROR | Deprecated `.withOpacity()` |
| | `rigid_no_dynamic` | ERROR | Explicit `dynamic` type annotations |

## Setup

### 1. Add dependencies

```yaml
# pubspec.yaml
dev_dependencies:
  custom_lint: ^0.8.1
  rigid_dart:
    git:
      url: https://github.com/YOUR_USER/rigid_dart.git
```

### 2. Include analysis options

```yaml
# analysis_options.yaml
include: package:rigid_dart/analysis_options.yaml

analyzer:
  plugins:
    - custom_lint
```

### 3. Run analysis

```bash
dart analyze --fatal-infos
```

### 4. (Optional) PATH wrapper

Drop `bin/flutter_gate` into `~/bin/flutter` to intercept `flutter run/build/test` with a mandatory analysis pass. Agents can't bypass what they can't see.

## Suppressing rules

```dart
// ignore: rigid_no_set_state
setState(() { /* emergency escape hatch */ });
```

## Shared analysis options

`package:rigid_dart/analysis_options.yaml` includes strict Dart settings:

- `strict-casts: true`
- `strict-inference: true`
- `avoid_dynamic_calls`
- `always_declare_return_types`
- `prefer_final_locals`
- And more

## License

MIT
