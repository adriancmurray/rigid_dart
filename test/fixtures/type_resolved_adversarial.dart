// Test fixtures for type-resolved rules (adversarial false-positive tests).
//
// These classes share names with Flutter widgets but are NOT from Flutter.
// TypeChecker.fromName(..., packageName: 'flutter') should NOT match them.
// If a rule fires on these, it's a false positive.

class Expanded {
  final int flex;
  final Widget child;
  const Expanded({this.flex = 1, required this.child});
}

class Flexible {
  final Widget child;
  const Flexible({required this.child});
}

class Row {
  final List<Widget> children;
  const Row({this.children = const []});
}

class Column {
  final List<Widget> children;
  const Column({this.children = const []});
}

class ListView {
  final List<Widget> children;
  const ListView({this.children = const []});
}

class TextField {
  final String hint;
  const TextField({this.hint = ''});
}

class WillPopScope {
  final Widget child;
  const WillPopScope({required this.child});
}

class Color {
  final int value;
  const Color(this.value);
  Color withOpacity(double opacity) => this;
  Color withValues({required double alpha}) => this;
}

class Colors {
  static const red = Color(0xFFFF0000);
  static const blue = Color(0xFF0000FF);
}

class TextStyle {
  final double? fontSize;
  const TextStyle({this.fontSize});
}

class ChangeNotifier {}
class ValueNotifier<T> extends ChangeNotifier {
  T value;
  ValueNotifier(this.value);
}

class AnimationController {
  void dispose() {}
}

class Widget {}

// Put them all together in usage to test false-positive rates:

void widgetTree() {
  // None of these should fire — they're not from Flutter.
  final row = Row(
    children: [
      Expanded(child: Widget()),
      Flexible(child: Widget()),
    ],
  );

  final col = Column(children: [Widget()]);
  final tf = TextField(hint: 'name');
  final willPop = WillPopScope(child: Widget());
}

void colorUsage() {
  // Not Flutter's Color — should NOT fire.
  final c = Color(0xFF123456);
  final red = Colors.red;
  final faded = red.withOpacity(0.5);
}

void textStyleUsage() {
  // Not Flutter's TextStyle — should NOT fire.
  final style = TextStyle(fontSize: 14);
}

void statePatterns() {
  // Not Flutter's ChangeNotifier — should NOT fire.
  final notifier = ValueNotifier<int>(0);
}

void asyncValue() {
  // Not Riverpod's AsyncValue — should NOT fire.
  final vn = ValueNotifier<int>(42);
  final val = vn.value;
}
