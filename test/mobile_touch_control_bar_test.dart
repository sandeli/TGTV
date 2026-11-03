import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player_example/common/widgets/mobile_touch_control_bar.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('four labeled touch actions call their matching callbacks',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    var previous = 0;
    var next = 0;
    var channels = 0;
    var settings = 0;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: MobileTouchControlBar(
          onPrevious: () => previous++,
          onNext: () => next++,
          onOpenChannels: () => channels++,
          onOpenSettings: () => settings++,
        ),
      ),
    ));

    expect(find.text('上一台'), findsOneWidget);
    expect(find.text('下一台'), findsOneWidget);
    expect(find.text('频道列表'), findsOneWidget);
    expect(find.text('设置'), findsOneWidget);

    await tester.tap(find.text('上一台'));
    await tester.tap(find.text('下一台'));
    await tester.tap(find.text('频道列表'));
    await tester.tap(find.text('设置'));

    expect((previous, next, channels, settings), (1, 1, 1, 1));
  });

  testWidgets(
      'narrow phones use compact buttons while preserving touch target size',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: MobileTouchControlBar(
          onPrevious: () {},
          onNext: () {},
          onOpenChannels: () {},
          onOpenSettings: () {},
        ),
      ),
    ));

    expect(find.text('上一台'), findsNothing);
    expect(find.bySemanticsLabel('上一台'), findsOneWidget);
    final buttonSize = tester.getSize(find.byType(InkWell).first);
    expect(buttonSize.width, greaterThanOrEqualTo(48));
    expect(buttonSize.height, greaterThanOrEqualTo(48));
  });
}
