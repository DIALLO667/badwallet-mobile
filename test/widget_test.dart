import 'package:flutter_test/flutter_test.dart';

import 'package:badwallet_mobile/main.dart';

void main() {
  testWidgets('BadWallet app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const BadWalletApp());
    // L'app démarre sur le SplashScreen sans erreur
    await tester.pump();
  });
}
