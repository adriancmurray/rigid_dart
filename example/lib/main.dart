// ignore_for_file: unused_import, unused_local_variable
// This file intentionally triggers rigid_dart rules for demonstration.

import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════════════
// 🔴 rigid_no_set_state: Using setState in a StatefulWidget
// ═══════════════════════════════════════════════════════════════════
class CounterWidget extends StatefulWidget {
  const CounterWidget({super.key});

  @override
  State<CounterWidget> createState() => _CounterWidgetState();
}

class _CounterWidgetState extends State<CounterWidget> {
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        // ❌ This will fire rigid_no_set_state.
        // FIX: Use a Riverpod provider instead.
        setState(() => _count++);
      },
      child: Text('Count: $_count'),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// 🔴 rigid_no_hardcoded_colors: Using Color() or Colors.* directly
// ═══════════════════════════════════════════════════════════════════
class BadColorWidget extends StatelessWidget {
  const BadColorWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      // ❌ This will fire rigid_no_hardcoded_colors.
      // FIX: Use Theme.of(context).colorScheme.primary
      color: Colors.blue,
      child: const Text('Hello'),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// 🔴 rigid_no_with_opacity: Deprecated .withOpacity()
// ═══════════════════════════════════════════════════════════════════
class OpacityExample extends StatelessWidget {
  const OpacityExample({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;
    return Container(
      // ❌ This will fire rigid_no_with_opacity.
      // Quick fix available: changes to .withValues(alpha: 0.5)
      color: theme.primary.withOpacity(0.5),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// 🟡 rigid_no_hardcoded_strings: Hardcoded text in widgets
// ═══════════════════════════════════════════════════════════════════
class HardcodedStringWidget extends StatelessWidget {
  const HardcodedStringWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ❌ This will fire rigid_no_hardcoded_strings.
        // FIX: Use AppLocalizations.of(context).welcomeTitle
        const Text('Welcome to our app'),
        Text('Hello \${context.toString()}'),
      ],
    );
  }
}
