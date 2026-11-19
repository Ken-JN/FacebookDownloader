import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fb_downloader/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: FbDownloaderApp()));
    expect(find.byType(FbDownloaderApp), findsOneWidget);
  });
}
