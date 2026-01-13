import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_kit/ui_kit.dart';

void main() {
  testWidgets('OrganizationRegistrationScreen renders shadcn components', (tester) async {
    // Provide a ShadApp wrapper since Shadcn widgets require ShadTheme/ShadApp
    await tester.pumpWidget(
      const ShadApp(
        home: OrganizationRegistrationScreen(),
      ),
    );

    expect(find.byType(ShadInput), findsNWidgets(2)); // Org name and Branch name
    expect(find.byType(ShadButton), findsOneWidget); // Create button
  });
}
