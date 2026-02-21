import 'package:custom_lint_builder/custom_lint_builder.dart';

/// Shared [TypeChecker] registry for Flutter framework types.
///
/// Uses [TypeChecker.fromName] so we resolve against the real type hierarchy,
/// catching aliases, reexports, and subclasses — not just string names.
abstract final class FlutterTypes {
  // ── Layout ──────────────────────────────────────────────────────────
  static const expanded = TypeChecker.fromName(
    'Expanded',
    packageName: 'flutter',
  );
  static const flexible = TypeChecker.fromName(
    'Flexible',
    packageName: 'flutter',
  );
  static const row = TypeChecker.fromName('Row', packageName: 'flutter');
  static const column = TypeChecker.fromName('Column', packageName: 'flutter');
  static const flex = TypeChecker.fromName('Flex', packageName: 'flutter');
  static const wrap = TypeChecker.fromName('Wrap', packageName: 'flutter');
  static const listView = TypeChecker.fromName(
    'ListView',
    packageName: 'flutter',
  );
  static const gridView = TypeChecker.fromName(
    'GridView',
    packageName: 'flutter',
  );
  static const customScrollView = TypeChecker.fromName(
    'CustomScrollView',
    packageName: 'flutter',
  );
  static const singleChildScrollView = TypeChecker.fromName(
    'SingleChildScrollView',
    packageName: 'flutter',
  );
  static const textField = TypeChecker.fromName(
    'TextField',
    packageName: 'flutter',
  );
  static const textFormField = TypeChecker.fromName(
    'TextFormField',
    packageName: 'flutter',
  );
  static const sizedBox = TypeChecker.fromName(
    'SizedBox',
    packageName: 'flutter',
  );

  /// Flex-family: Row, Column, Flex, Wrap.
  static const flexFamily = TypeChecker.any([row, column, flex, wrap]);

  /// Scrollable-family: ListView, GridView, CustomScrollView, etc.
  static const scrollableFamily = TypeChecker.any([
    listView,
    gridView,
    customScrollView,
    singleChildScrollView,
  ]);

  /// TextField-family: TextField, TextFormField.
  static const textFieldFamily = TypeChecker.any([textField, textFormField]);

  // ── State ───────────────────────────────────────────────────────────
  static const state = TypeChecker.fromName('State', packageName: 'flutter');
  static const changeNotifier = TypeChecker.fromName(
    'ChangeNotifier',
    packageName: 'flutter',
  );
  static const valueNotifier = TypeChecker.fromName(
    'ValueNotifier',
    packageName: 'flutter',
  );

  // ── Architecture ────────────────────────────────────────────────────
  static const color = TypeChecker.fromName('Color', packageName: 'flutter');
  static const textStyle = TypeChecker.fromName(
    'TextStyle',
    packageName: 'flutter',
  );

  // ── Freshness ───────────────────────────────────────────────────────
  static const willPopScope = TypeChecker.fromName(
    'WillPopScope',
    packageName: 'flutter',
  );

  // ── Disposables ─────────────────────────────────────────────────────
  static const animationController = TypeChecker.fromName(
    'AnimationController',
    packageName: 'flutter',
  );
  static const focusNode = TypeChecker.fromName(
    'FocusNode',
    packageName: 'flutter',
  );
  static const scrollController = TypeChecker.fromName(
    'ScrollController',
    packageName: 'flutter',
  );
  static const tabController = TypeChecker.fromName(
    'TabController',
    packageName: 'flutter',
  );
  static const textEditingController = TypeChecker.fromName(
    'TextEditingController',
    packageName: 'flutter',
  );
  static const pageController = TypeChecker.fromName(
    'PageController',
    packageName: 'flutter',
  );

  /// Dart SDK types
  static const streamSubscription = TypeChecker.fromName(
    'StreamSubscription',
    packageName: 'dart.async',
  );
  static const timer = TypeChecker.fromName('Timer', packageName: 'dart.async');
}
