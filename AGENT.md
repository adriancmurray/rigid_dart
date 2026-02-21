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
  echo ""
  echo "🦀 Analysis clean. Proceeding to: flutter $*"
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
