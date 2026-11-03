import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player_example/pages/iptv/widgets/playback_corner_overlay.dart';

void main() {
  testWidgets('三个角落信息以白字直接叠加视频且没有填充背景', (tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(1920, 1080),
        minTextAdapt: true,
        child: MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: SizedBox.expand(
              child: Stack(
                children: const [
                  ColoredBox(color: Colors.blueGrey),
                  PlaybackCornerOverlay(stationName: '凤凰资讯 8M1080'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final stationText = tester.widget<Text>(find.text('凤凰资讯 8M1080'));
    expect(stationText.style?.color, Colors.white);
    expect(stationText.style?.shadows, isNotEmpty);

    final networkText = tester.widget<Text>(find.textContaining('网速'));
    expect(networkText.style?.color, Colors.white);
    expect(networkText.style?.shadows, isNotEmpty);

    expect(
      find.byWidgetPredicate(
        (widget) => widget is Container && widget.decoration != null,
      ),
      findsNothing,
    );

    final positions = tester.widgetList<Positioned>(find.byType(Positioned));
    expect(positions, hasLength(3));
    expect(positions.first.top, 20.h);
    expect(positions.first.left, 20.w);
    expect(positions.last.right, 20.w);
    expect(positions.last.bottom, 20.h);
  });
}
