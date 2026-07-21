import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:clearedtogo/main.dart';

void main() {
  testWidgets('checkboxes use the app accent styling', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    final checkboxTheme = materialApp.theme!.checkboxTheme;

    expect(
      checkboxTheme.fillColor!.resolve({WidgetState.selected}),
      const Color(0xFF87CEEB),
    );
    expect(
      checkboxTheme.checkColor!.resolve({WidgetState.selected}),
      Colors.white,
    );
  });
}
