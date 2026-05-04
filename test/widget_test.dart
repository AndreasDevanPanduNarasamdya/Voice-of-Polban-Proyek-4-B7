import 'package:flutter_test/flutter_test.dart';
import 'package:voice_of_polban/screens/debug_dashboard.dart';

void main() {
  test('debug dashboard widget can be constructed', () {
    const widget = DebugDashboard();

    expect(widget, isNotNull);
  });
}
