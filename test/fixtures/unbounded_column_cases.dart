// Test fixture for rigid_no_unbounded_column rule.
//
// These are FAKE classes (not from Flutter) — the rule checks
// FlutterTypes so none of these should trigger.
// The purpose is to verify the _hasMainAxisSizeMin and _hasShrinkWrap
// helper methods don't cause regressions on non-Flutter types.

// ── Fake Flutter types ────────────────────────────────────────────

class Widget {}

enum MainAxisSize { min, max }
enum CrossAxisAlignment { start, center, end }

class Column {
  final MainAxisSize mainAxisSize;
  final CrossAxisAlignment crossAxisAlignment;
  final List<Widget> children;
  const Column({
    this.mainAxisSize = MainAxisSize.max,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.children = const [],
  });
}

class SingleChildScrollView {
  final Widget? child;
  const SingleChildScrollView({this.child});
}

class SizedBox {
  final double? height;
  final Widget? child;
  const SizedBox({this.height, this.child});
}

class ListView {
  final bool shrinkWrap;
  final List<Widget> children;
  const ListView({this.shrinkWrap = false, this.children = const []});
}

// ── SHOULD NOT trigger (non-Flutter, but exercises code paths) ─────

// Column with mainAxisSize: MainAxisSize.min inside a scrollable
void minSizedColumnInScrollable() {
  SingleChildScrollView(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [Widget()],
    ),
  );
}

// Column with shrinkWrap-style pattern (only valid on ListView)
void listViewWithShrinkWrap() {
  SingleChildScrollView(
    child: ListView(
      shrinkWrap: true,
      children: [Widget()],
    ),
  );
}

// Column inside SizedBox inside scrollable
void columnInSizedBox() {
  SingleChildScrollView(
    child: SizedBox(
      height: 200,
      child: Column(
        children: [Widget()],
      ),
    ),
  );
}

// ── WOULD trigger if these were real Flutter types ──────────────────

// Unbounded Column directly inside scrollable (no mitigation)
void unboundedColumn() {
  SingleChildScrollView(
    child: Column(
      children: [Widget()],
    ),
  );
}

// Column with mainAxisSize: MainAxisSize.max (still unbounded)
void maxSizedColumn() {
  SingleChildScrollView(
    child: Column(
      mainAxisSize: MainAxisSize.max,
      children: [Widget()],
    ),
  );
}
