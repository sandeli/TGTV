import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player_example/pages/iptv/widgets/mobile_menu_touch_zone.dart';

void main() {
  testWidgets('手机左侧菜单区域可点，屏幕其余区域不触发', (tester) async {
    tester.view.physicalSize = const Size(800, 360);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var openCount = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox.expand(
          child: Stack(
            children: [
              const Positioned.fill(child: ColoredBox(color: Colors.black)),
              MobileMenuTouchZone(onTap: () => openCount++),
            ],
          ),
        ),
      ),
    ));

    final tab = find.byWidgetPredicate(
      (widget) =>
          widget is SizedBox && widget.width == 46 && widget.height == 78,
    );
    expect(tab, findsOneWidget);
    expect(tester.getTopLeft(tab), const Offset(0, 141));

    await tester.tapAt(const Offset(80, 180));
    expect(openCount, 1);

    await tester.tapAt(const Offset(250, 180));
    expect(openCount, 1);
  });
}
