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

This activates the 16 custom lint rules. Any violations will appear as
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
| `rigid_no_with_opacity` | Replace `.withOpacity(x)` with `.withValues(alpha: x)` — **quick fix available** |
| `rigid_no_dynamic` | Replace `dynamic` with an explicit type, `Object?`, or a generic parameter — **quick fix available** |
| `rigid_no_build_context_across_async` | Add `if (!context.mounted) return;` guard after the `await`, or capture values before the `await` |
| `rigid_dispose_required` | Add `.dispose()` or `.cancel()` call in the `dispose()` method |
| `rigid_no_print` | Replace `print()` with `debugPrint()` or a structured logger |

---

## Step 5: Choose your enforcement level

Rigid Dart supports three enforcement tiers. Each tier is additive --
higher tiers include everything from lower tiers.

### Tier 1: Advisor (Steps 1-4 above)

**What it does:** Rules appear as inline errors/warnings in your IDE.
`dart analyze` reports violations. Code still compiles and runs.

**Who it's for:** Teams that want visibility into violations but prefer
gradual adoption. Agents see the errors as IDE feedback but can still
build and run the app.

**What agents experience:** Lint errors appear in tool call responses.
The agent may or may not act on them depending on its instructions.

This is the default after completing Steps 1-4. No extra setup needed.

---

### Tier 2: Gatekeeper (add pre-commit hook)

**What it does:** Tier 1 + violations block commits. The `dart analyze
--fatal-infos` command runs before every `git commit`. If analysis fails,
the commit is rejected.

**Who it's for:** Teams that want to prevent violations from entering the
repository. Agents can still compile and run locally, but cannot commit
bad code.

**What agents experience:** The agent can iterate freely during
development, but when it tries to commit, it hits a wall with clear
error output explaining what to fix.

**Setup:** Add this to `.git/hooks/pre-commit` (create the file if it
doesn't exist, make it executable with `chmod +x`):

```bash
#!/usr/bin/env bash
set -euo pipefail
echo "🦀 Rigid Dart -- pre-commit gate"
dart analyze --fatal-infos || {
  echo "❌ RIGID DART: Fix violations before committing."
  echo "   Use // ignore: rule_name for intentional suppressions."
  exit 1
}
echo "✅ Analysis clean. Commit allowed."
```

---

### Tier 3: Compiler (add PATH wrapper)

**What it does:** Tier 1 + Tier 2 + violations block compilation. A
wrapper script intercepts `flutter run`, `flutter build`, and `flutter
test`. Before the real Flutter command executes, `dart analyze
--fatal-infos` must pass. If it doesn't, the command fails immediately.

**Who it's for:** Teams that want maximum enforcement. This is the
"Rust mode" -- nothing runs until the code is clean.

**What agents experience:** The agent calls `flutter run` and receives
what looks like a compilation failure. The output contains every
violation with file, line number, and rule name. The agent has no choice
but to fix the violations and retry. It cannot bypass this because it
doesn't know the wrapper exists -- it just sees `flutter run` failing.

**How it works:** A shell script at `~/bin/flutter` sits ahead of the
real `flutter` binary in PATH. When the agent (or you) runs
`flutter run`, the wrapper intercepts the call:

1. Checks if the command is `run`, `build`, or `test`
2. If yes, runs `dart analyze --fatal-infos` first
3. If analysis fails, exits with error (command never reaches Flutter)
4. If analysis passes, transparently delegates to the real `flutter`

Non-compile commands (`pub get`, `doctor`, `clean`, etc.) pass through
without any gate.

**Setup:**

Create `~/bin/flutter`:

```bash
#!/usr/bin/env bash
# Rigid Dart -- PATH wrapper for flutter
# Intercepts run/build/test with mandatory analysis pass.
set -euo pipefail

# Find the real flutter binary (skip this wrapper).
REAL_FLUTTER=""
while IFS= read -r candidate; do
  if [ "$candidate" != "$0" ] && [ "$candidate" != "$(realpath "$0" 2>/dev/null || echo "$0")" ]; then
    REAL_FLUTTER="$candidate"; break
  fi
done < <(which -a flutter 2>/dev/null)

if [ -z "$REAL_FLUTTER" ]; then
  echo "ERROR: Could not find real flutter binary in PATH."
  exit 1
fi

# Only gate commands that compile code.
GATED="run build test"
SHOULD_GATE=false
for arg in "$@"; do
  for cmd in $GATED; do
    if [ "$arg" = "$cmd" ]; then
      SHOULD_GATE=true; break 2
    fi
  done
  [[ "$arg" != -* ]] && break
done

if [ "$SHOULD_GATE" = true ]; then
  echo ""
  echo "🦀 Rigid Dart gate -- analyzing before compile..."
  echo ""
  if ! dart analyze --fatal-infos 2>&1; then
    echo ""
    echo "════════════════════════════════════════════════════════"
    echo "  ❌ RIGID DART: Analysis failed. Fix violations above."
    echo "  Then retry: flutter $*"
    echo "════════════════════════════════════════════════════════"
    echo ""
    exit 1
  fi

  # Test gate: all tests must pass before compile.
  # Skip if the command is already 'test' (avoid recursion).
  if [ "$1" != "test" ]; then
    echo ""
    echo "🧪 Rigid Dart gate -- running tests..."
    echo ""
    if ! "$REAL_FLUTTER" test 2>&1; then
      echo ""
      echo "════════════════════════════════════════════════════════"
      echo "  ❌ RIGID DART: Tests failed. Fix failures above."
      echo "  Then retry: flutter $*"
      echo "════════════════════════════════════════════════════════"
      echo ""
      exit 1
    fi
  fi

  echo ""
  echo "🦀 Analysis + tests clean. Proceeding to: flutter $*"
  echo ""
fi

exec "$REAL_FLUTTER" "$@"
```

Then make it executable and add `~/bin` to the front of PATH:

```bash
chmod +x ~/bin/flutter
```

Add this to `~/.zshrc` (or `~/.bashrc`):

```bash
export PATH="$HOME/bin:$PATH"
```

**Checkpoint:** Open a new terminal. Run `which flutter`. It should
show `~/bin/flutter`, not the SDK path. Then run `flutter doctor` to
verify passthrough works.

**To disable temporarily:** Rename or remove `~/bin/flutter`. The real
Flutter binary takes over immediately. No PATH changes needed.

**To uninstall permanently:** Delete `~/bin/flutter` and remove the
PATH line from your shell config.

---

## Rules of engagement

1. **Never disable a rigid_dart rule globally.** Use `// ignore:` per-line only.
2. **All colors must come from the theme.** No `Colors.red` or `Color(0xFF...)`.
3. **All text styles must come from the theme.** No raw `fontSize` values.
4. **No `setState`, no `ChangeNotifier`.** Use Riverpod.
5. **No `dynamic`.** Type everything explicitly.
6. **No deprecated APIs.** Use `PopScope`, `.withValues(alpha:)`.

---

## Working with Rigid Dart

### Daily workflow

When you write code in a project that uses rigid_dart, your workflow is:

1. **Write code normally.**
2. **Run `dart analyze --fatal-infos`.** Fix any violations.
3. **Run `dart run custom_lint`.** Fix any `rigid_*` violations.
4. **Commit.** The pre-commit hook (Tier 2) will catch anything you missed.

If Tier 3 (Compiler) is installed, steps 2-3 happen automatically when
you run `flutter run`.

### Suppressing a rule on one line

```dart
// ignore: rigid_no_hardcoded_colors
final debugOverlay = Colors.red.withValues(alpha: 0.3);
```

### Suppressing a rule for an entire file

Only do this in files where the rule genuinely does not apply (e.g.,
a spacing tokens file, a theme definition file):

```dart
// ignore_for_file: rigid_no_magic_numbers

/// Design system spacing tokens. This is where constants are DEFINED.
const kSpacingXS = 4.0;
const kSpacingSM = 8.0;
const kSpacingMD = 16.0;
const kSpacingLG = 24.0;
const kSpacingXL = 32.0;
```

### Understanding severity levels

- 🔴 **ERROR** — Must fix. The rule catches a bug or banned pattern.
- 🟡 **WARNING** — Should fix. The rule catches a code smell.
- 🔵 **INFO** — Consider fixing. The rule suggests a better pattern.

### Theme definition files

Files that DEFINE theme values (colors, text styles) need file-level
suppressions. This is expected:

```dart
// ignore_for_file: rigid_no_hardcoded_colors, rigid_no_hardcoded_text_style

/// App theme definition — the ONLY place hardcoded values are allowed.
class AppTheme {
  static final light = ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: Color(0xFF6750A4)),
    // ...
  );
}
```

### What counts as "outside theme definitions"

The color and text style rules flag violations everywhere EXCEPT:
- Files with `theme` in the filename (e.g., `app_theme.dart`)
- Lines with a `// ignore:` comment
- Files with a `// ignore_for_file:` comment

If your theme file isn't detected, add `// ignore_for_file:` at the top.

---

## Modifying Rigid Dart

### Adding a new rule

1. **Create the rule file** in `lib/rules/<phase>/`:

```dart
// lib/rules/state/no_global_keys.dart
import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart' show DiagnosticReporter;
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:analyzer/dart/ast/ast.dart';

class NoGlobalKeys extends DartLintRule {
  const NoGlobalKeys() : super(code: _code);

  static const _code = LintCode(
    name: 'rigid_no_global_keys',       // Always prefix with rigid_
    problemMessage:
        'GlobalKey is banned. Use ValueKey or UniqueKey instead.',
    errorSeverity: DiagnosticSeverity.ERROR,
  );

  // Use TypeChecker for type-resolved detection (catches aliases/subclasses).
  static const _globalKey = TypeChecker.fromName(
    'GlobalKey',
    packageName: 'flutter',
  );

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    if (isGeneratedFile(resolver.path)) return;

    context.registry.addInstanceCreationExpression((node) {
      final type = node.staticType;
      if (type != null && _globalKey.isExactlyType(type)) {
        reporter.atNode(node, code);
      }
    });
  }
}
```

2. **Register it** in `lib/rigid_dart.dart`:

```dart
import 'package:rigid_dart/rules/state/no_global_keys.dart';
// In getLintRules():
const NoGlobalKeys(),
```

3. **Verify** the package still compiles:

```bash
cd packages/rigid_dart && dart analyze
```

4. **Test** against a consumer project:

```bash
cd apps/your_app && dart run custom_lint
```

5. **Update AGENT.md** — add the new rule to the fix table in Step 4.

### Changing a rule's severity

Edit the `errorSeverity` in the rule's `LintCode` constructor:

```dart
errorSeverity: DiagnosticSeverity.ERROR,    // 🔴 Hard error
errorSeverity: DiagnosticSeverity.WARNING,  // 🟡 Warning
errorSeverity: DiagnosticSeverity.INFO,     // 🔵 Info
```

### Removing a rule

1. Delete the rule file from `lib/rules/<phase>/`.
2. Remove the import and registration from `lib/rigid_dart.dart`.
3. Run `dart analyze` to confirm no broken imports.

### Available AST callbacks

The `context.registry` object provides callbacks for every AST node type.
Common ones used in rigid_dart rules:

| Callback | Use case |
|----------|----------|
| `addInstanceCreationExpression` | Catch `Widget(...)` constructors |
| `addMethodInvocation` | Catch `.method()` calls |
| `addNamedType` | Catch type annotations like `dynamic` |
| `addClassDeclaration` | Catch class definitions and their supertypes |
| `addPrefixedIdentifier` | Catch `Colors.red`, `Icons.star` patterns |
| `addIntegerLiteral` / `addDoubleLiteral` | Catch magic numbers |
| `addNamedExpression` | Catch named parameters in constructors |

### Publishing changes

After modifying rules, commit and push:

```bash
cd packages/rigid_dart
dart analyze                    # Must show 0 issues
git add -A
git commit -m "Add rigid_no_global_keys rule"
git push
```

Consumer projects pick up changes on next `flutter pub get`.

