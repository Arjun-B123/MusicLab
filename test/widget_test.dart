import 'package:flutter_test/flutter_test.dart';

import 'package:musiclab/core/purchases/subscription_status.dart';
import 'package:musiclab/main.dart';

void main() {
  testWidgets('App boots to the Home tab', (WidgetTester tester) async {
    await tester.pumpWidget(
      MusicLabApp(subscriptionStatus: SubscriptionStatus()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsWidgets);
  });
}
