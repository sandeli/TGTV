import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player_example/pages/settings/widgets/qr_import_page.dart';

Widget _wrapScreenUtil(Widget app) => ScreenUtilInit(
      designSize: const Size(1920, 1080),
      minTextAdapt: true,
      child: app,
    );

void main() {
  testWidgets('没有回填时保持二维码页，收到草稿后关闭该页', (tester) async {
    final drafts = StreamController<String>.broadcast();
    final app = MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () {
              Navigator.of(context).push<void>(
                PageRouteBuilder<void>(
                  opaque: false,
                  pageBuilder: (_, __, ___) => QrImportPage(
                    serverUrl: 'http://192.168.1.10:10381',
                    draftValues: drafts.stream,
                  ),
                ),
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    );

    await tester.pumpWidget(_wrapScreenUtil(app));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.byType(QrImportPage), findsOneWidget);
    expect(find.textContaining('上一级按“保存”'), findsOneWidget);

    drafts.add('https://example.com/playlist.m3u');
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.byType(QrImportPage), findsNothing);
    await drafts.close();
  });

  testWidgets('触屏点击二维码卡片不关闭，点击空白处返回', (tester) async {
    final drafts = StreamController<String>.broadcast();
    final app = MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () {
              Navigator.of(context).push<void>(
                PageRouteBuilder<void>(
                  opaque: false,
                  pageBuilder: (_, __, ___) => QrImportPage(
                    serverUrl: 'http://192.168.1.10:10381',
                    draftValues: drafts.stream,
                  ),
                ),
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    );

    await tester.pumpWidget(_wrapScreenUtil(app));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byType(QrImportPage), findsOneWidget);

    await tester.tap(find.text('扫码导入订阅链接'));
    await tester.pumpAndSettle();
    expect(find.byType(QrImportPage), findsOneWidget);

    await tester.tapAt(const Offset(4, 4));
    await tester.pumpAndSettle();
    expect(find.byType(QrImportPage), findsNothing);
    await drafts.close();
  });
}
