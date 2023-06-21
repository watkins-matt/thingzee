import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:integration_test/integration_test.dart';
import 'package:repository_ob/repository.dart';
import 'package:thingzee/app.dart';

void main() async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  App.repo = await ObjectBoxRepository.create();
  assert(App.repo.ready);

  group('General App Tests', () {
    testWidgets('Test for exceptions while tapping bottom bar icons.', (WidgetTester tester) async {
      FlutterExceptionHandler? oldOnError = FlutterError.onError;
      FlutterErrorDetails? errorDetails;
      FlutterError.onError = (details) {
        errorDetails = details;
      };

      await tester.pumpWidget(const ProviderScope(
        child: App(),
      ));

      final locationsIconFinder = find.byIcon(Icons.folder);
      await tester.tap(locationsIconFinder);
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.shopping_cart));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.portrait));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.home));
      await tester.pumpAndSettle();

      // Reset FlutterError.onError to the original handler
      FlutterError.onError = oldOnError;

      expect(errorDetails, isNull, reason: 'An exception occurred while testing the app.');
    });
  });
}
