import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:clearedtogo/screens/preflight_systems/pave_assessment_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SharedPreferences.getInstance();
  });

  testWidgets('PAVE radio groups use dark text and light option styling',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: PaveAssessmentScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('I.M.S.A.F.E. Check (Pilot)'));
    await tester.pumpAndSettle();

    final labelText = tester.widget<Text>(find.text('Illness'));
    expect(labelText.style?.color, Colors.black87);

    final firstTile = tester.widget<RadioListTile<String>>(
        find.byType(RadioListTile<String>).first);
    expect(firstTile.activeColor, const Color(0xFF87CEEB));

    final okTitle = firstTile.title as Text;
    expect(okTitle.style?.color, Colors.black87);
  });
}
