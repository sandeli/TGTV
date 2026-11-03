import 'package:fijkplayer_ijkfix/fijkplayer_ijkfix.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player_example/pages/iptv/widgets/iptv_player_panel_builder.dart';

void main() {
  testWidgets('无播放源时隐藏默认等待动画', (tester) async {
    final player = FijkPlayer();
    final panelBuilder = iptvPlayerPanelBuilder(hasPlaybackSource: false);

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Stack(
            children: [
              panelBuilder(
                player,
                FijkData(),
                context,
                const Size(1920, 1080),
                const Rect.fromLTWH(0, 0, 1920, 1080),
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byType(SizedBox), findsOneWidget);
  });

  testWidgets('有播放源时保留默认起播等待动画', (tester) async {
    final player = FijkPlayer();
    final panelBuilder = iptvPlayerPanelBuilder(hasPlaybackSource: true);

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Stack(
            children: [
              panelBuilder(
                player,
                FijkData(),
                context,
                const Size(1920, 1080),
                const Rect.fromLTWH(0, 0, 1920, 1080),
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
