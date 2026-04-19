import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sudoku/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Selecting an empty cell filters candidates', (WidgetTester tester) async {
    app.main();
    // Wait for initialization (FutureBuilder) to complete
    int attempts = 0;
    while (find.byKey(const ValueKey('newGameBtn')).evaluate().isEmpty && attempts < 100) {
      await tester.pump(const Duration(milliseconds: 100));
      attempts++;
    }
    // pump manually to allow fadeIn animation (1000ms) to complete
    await tester.pump(const Duration(milliseconds: 1500));

    // 1. Start a new game
    final newGameButton = find.byKey(const ValueKey('newGameBtn'));
    expect(newGameButton, findsOneWidget);
    await tester.tap(newGameButton);
    
    // Wait for bottom sheet and 'Easy' button to appear
    attempts = 0;
    while (find.byKey(const ValueKey('level_easy')).evaluate().isEmpty && attempts < 100) {
      await tester.pump(const Duration(milliseconds: 100));
      attempts++;
    }
    await tester.pump(const Duration(milliseconds: 500)); // wait for sheet to fully open

    // 2. Select 'Easy' difficulty
    final easyButton = find.byKey(const ValueKey('level_easy'));
    expect(easyButton, findsOneWidget);
    await tester.tap(easyButton);
    
    // Wait for the game to generate and the board to appear.
    attempts = 0;
    while (find.byKey(const ValueKey('cell_0')).evaluate().isEmpty && attempts < 200) {
      await tester.pump(const Duration(milliseconds: 100));
      attempts++;
    }
    await tester.pump(const Duration(milliseconds: 1000)); // wait for board to settle

    // 3. Find an empty cell. We added ValueKey('cell_$index') to cells.
    // An empty cell has a Text widget with an empty string.
    final emptyCellText = find.descendant(
      of: find.byType(InkWell),
      matching: find.text(''),
    ).first;
    
    expect(emptyCellText, findsWidgets); // Should find at least one empty cell
    
    // 4. Tap the empty cell
    await tester.tap(emptyCellText);
    await tester.pump(const Duration(milliseconds: 500)); // wait for selection state to update

    // 5. Verify the candidate filtering.
    // At least one of the input buttons (1-9) should be disabled 
    // because the cell must share a row/col/grid with SOME existing number.
    int disabledCount = 0;
    int enabledCount = 0;
    
    for (int i = 1; i <= 9; i++) {
      final buttonFinder = find.byKey(ValueKey('input_$i'));
      expect(buttonFinder, findsOneWidget);
      
      final CupertinoButton button = tester.widget<CupertinoButton>(buttonFinder);
      if (button.onPressed == null) {
        disabledCount++;
      } else {
        enabledCount++;
      }
    }
    
    // In a standard Sudoku puzzle, tapping an empty cell will almost 
    // certainly result in SOME numbers being disabled.
    expect(disabledCount, greaterThan(0), reason: 'Expected at least one candidate to be disabled.');
    expect(enabledCount, greaterThan(0), reason: 'Expected at least one candidate to be enabled.');

    // 6. Find a non-empty cell.
    Finder? nonEmptyCellFinder;
    for (int i = 0; i < 81; i++) {
      final cellFinder = find.byKey(ValueKey('cell_$i'));
      final textFinder = find.descendant(of: cellFinder, matching: find.byType(Text));
      if (textFinder.evaluate().isNotEmpty) {
        final Text textWidget = tester.widget<Text>(textFinder.first);
        if (textWidget.data != null && textWidget.data!.isNotEmpty) {
          nonEmptyCellFinder = cellFinder;
          break;
        }
      }
    }
    
    expect(nonEmptyCellFinder, isNotNull, reason: 'Expected to find at least one non-empty cell.');

    // 7. Tap the non-empty cell
    await tester.tap(nonEmptyCellFinder!);
    await tester.pump(const Duration(milliseconds: 500)); // wait for selection state to update
    
    // 8. Verify all inputs are disabled
    int fullyDisabledCount = 0;
    for (int i = 1; i <= 9; i++) {
      final buttonFinder = find.byKey(ValueKey('input_$i'));
      expect(buttonFinder, findsOneWidget);
      final CupertinoButton button = tester.widget<CupertinoButton>(buttonFinder);
      if (button.onPressed == null) {
        fullyDisabledCount++;
      }
    }
    
    expect(fullyDisabledCount, 9, reason: 'Expected ALL candidates to be disabled for a non-empty cell.');
  });
}
