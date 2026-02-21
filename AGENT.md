# Agent Instructions for Rigid Dart

You are installing **Rigid Dart**, a `custom_lint` plugin that enforces strict
Dart/Flutter coding standards. Follow these steps exactly. Do not skip steps.
Verify each checkpoint before proceeding.

---

## Step 1: Add dependencies

Add these to the project's `pubspec.yaml` under `dev_dependencies`:

```yaml
dev_dependencies:
  custom_lint: ^0.8.1
  rigid_dart:
    git:
      url: https://github.com/adriancmurray/rigid_dart.git
```

Then run:

```bash
flutter pub get
```

**Checkpoint:** Verify `rigid_dart` appears in `.dart_tool/package_config.json`.

---

## Step 2: Configure analysis options

Replace or update the project's `analysis_options.yaml`:

```yaml
include: package:rigid_dart/analysis_options.yaml

analyzer:
  plugins:
    - custom_lint
```

You may add project-specific overrides under `linter: rules:` but do NOT
disable any rigid_dart rules globally. Use `// ignore: rule_name` for
one-off suppressions only.

**Checkpoint:** Run `dart analyze`. You should see rigid_dart's strict
analysis options take effect (e.g., `strict-casts`, `strict-inference`).

---

## Step 3: Verify rules are active

Run:

```bash
dart run custom_lint
```

This activates the 12 custom lint rules. Any violations will appear as
errors or warnings with the `rigid_` prefix.

**Checkpoint:** Output should show rule violations (if any exist) prefixed
with `rigid_`. If no violations exist, the output will be clean.

---

## Step 4: Fix violations

When rigid_dart flags violations, fix them according to these patterns:

| Rule | Fix |
|------|-----|
| `rigid_no_expanded_outside_flex` | Move `Expanded`/`Flexible` to be a direct child of `Row`/`Column`/`Flex` |
| `rigid_no_unbounded_column` | Wrap nested `Column`/`ListView` in `SizedBox` with height, or set `shrinkWrap: true` |
| `rigid_constrained_text_field` | Wrap `TextField` in `Expanded` or `SizedBox` when inside a `Row` |
| `rigid_no_set_state` | Replace `setState` with Riverpod `ref.read`/`ref.watch` |
| `rigid_no_change_notifier` | Replace `ChangeNotifier` with Riverpod `Notifier` or `AsyncNotifier` |
| `rigid_exhaustive_async` | Replace `.value` with `.when(data:, loading:, error:)` |
| `rigid_no_hardcoded_colors` | Replace `Colors.*` and `Color(0xFF...)` with `Theme.of(context).colorScheme.*` |
| `rigid_no_hardcoded_text_style` | Replace raw `TextStyle(fontSize: N)` with `Theme.of(context).textTheme.*` |
| `rigid_no_magic_numbers` | Extract layout literals to named constants or spacing tokens |
| `rigid_no_will_pop_scope` | Replace `WillPopScope` with `PopScope(canPop:, onPopInvokedWithResult:)` |
| `rigid_no_with_opacity` | Replace `.withOpacity(x)` with `.withValues(alpha: x)` |
| `rigid_no_dynamic` | Replace `dynamic` with an explicit type, `Object?`, or a generic parameter |

---

## Step 5: Gate compilation (optional)

To block `flutter run/build/test` until analysis passes, create `~/bin/flutter`:

```bash
#!/usr/bin/env bash
set -euo pipefail
REAL_FLUTTER=""
while IFS= read -r candidate; do
  if [ "$candidate" != "$0" ] && [ "$candidate" != "$(realpath "$0" 2>/dev/null || echo "$0")" ]; then
    REAL_FLUTTER="$candidate"; break
  fi
done < <(which -a flutter 2>/dev/null)
GATED="run build test"
SHOULD_GATE=false
for arg in "$@"; do
  for cmd in $GATED; do [ "$arg" = "$cmd" ] && SHOULD_GATE=true && break 2; done
  [[ "$arg" != -* ]] && break
done
if [ "$SHOULD_GATE" = true ]; then
  echo "🦀 Rigid Dart gate..."
  dart analyze --fatal-infos || { echo "❌ Fix violations first."; exit 1; }
fi
exec "$REAL_FLUTTER" "$@"
```

Then:

```bash
chmod +x ~/bin/flutter
# Ensure ~/bin is first in PATH:
export PATH="$HOME/bin:$PATH"
```

---

## Rules of engagement

1. **Never disable a rigid_dart rule globally.** Use `// ignore:` per-line only.
2. **Run `dart analyze --fatal-infos` before every commit.**
3. **All colors must come from the theme.** No `Colors.red` or `Color(0xFF...)`.
4. **All text styles must come from the theme.** No raw `fontSize` values.
5. **No `setState`, no `ChangeNotifier`.** Use Riverpod.
6. **No `dynamic`.** Type everything explicitly.
7. **No deprecated APIs.** Use `PopScope`, `.withValues(alpha:)`.
