import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player_example/common/index.dart';
import 'package:video_player_example/pages/panel/view.dart';
import 'package:video_player_example/pages/panel/widgets/iptv_list.dart';

Iptv _channel({
  required int idx,
  required int channel,
  required int groupIdx,
  required String name,
}) =>
    Iptv(
      idx: idx,
      channel: channel,
      groupIdx: groupIdx,
      name: name,
      url: 'http://example.test/$name.m3u8',
      tvgName: name,
    );

Widget _app({bool usePanelPage = false}) {
  return ScreenUtilInit(
    designSize: const Size(1920, 1080),
    minTextAdapt: true,
    child: MaterialApp(
      theme: ThemeData.dark(),
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute<void>(
                  builder: (_) => usePanelPage
                      ? const PanelPage()
                      : Scaffold(
                          body: Align(
                            alignment: Alignment.topLeft,
                            child: SizedBox(
                              width: 480,
                              height: 820,
                              child: const PanelIptvList(),
                            ),
                          ),
                        ),
                ));
              },
              child: const Text('打开菜单'),
            ),
          ),
        ),
      ),
    ),
  );
}

BoxDecoration _tileDecoration(WidgetTester tester, String label) {
  final tile = tester.widget<Container>(
    find
        .ancestor(
          of: find.text(label),
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is Container && widget.decoration is BoxDecoration,
          ),
        )
        .first,
  );
  return tile.decoration! as BoxDecoration;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await PrefsUtil.init();
  });

  setUp(() async {
    await GetIt.I.reset();
    final store = IptvStore()
      ..iptvGroupList = [
        IptvGroup(
          idx: 0,
          name: '新闻组',
          list: [
            _channel(idx: 0, channel: 1, groupIdx: 0, name: '新闻频道一'),
            _channel(idx: 1, channel: 2, groupIdx: 0, name: '新闻频道二'),
          ],
        ),
        IptvGroup(
          idx: 1,
          name: '体育组',
          list: [
            _channel(idx: 0, channel: 3, groupIdx: 1, name: '体育频道一'),
          ],
        ),
      ];
    store.currentIptv = store.iptvList.first;
    GetIt.I.registerSingleton<IptvStore>(store);
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  void setScreen(WidgetTester tester) {
    tester.view.physicalSize = const Size(1000, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('一级分类与对应二级频道同时显示，遥控器切换分类', (tester) async {
    setScreen(tester);
    await tester.pumpWidget(_app());
    await tester.tap(find.text('打开菜单'));
    await tester.pumpAndSettle();

    expect(find.text('一级菜单'), findsOneWidget);
    expect(find.text('频道分类'), findsOneWidget);
    expect(find.text('二级菜单 · 新闻组'), findsOneWidget);
    expect(find.text('新闻组'), findsOneWidget);
    expect(find.text('体育组'), findsOneWidget);
    expect(find.text('新闻频道一'), findsOneWidget);
    expect(find.text('新闻频道二'), findsOneWidget);
    expect(find.text('体育频道一'), findsNothing);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();

    expect(find.text('二级菜单 · 体育组'), findsOneWidget);
    expect(find.text('体育频道一'), findsOneWidget);
    expect(find.text('新闻频道一'), findsNothing);
  });

  testWidgets('当前焦点在一级分类和二级频道时都有醒目的描边', (tester) async {
    setScreen(tester);
    await tester.pumpWidget(_app());
    await tester.tap(find.text('打开菜单'));
    await tester.pumpAndSettle();

    var decoration = _tileDecoration(tester, '新闻组');
    expect((decoration.border! as Border).top.color, AppTheme.dialogFocus);
    expect(decoration.boxShadow, isNotEmpty);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();

    decoration = _tileDecoration(tester, '新闻频道一');
    expect((decoration.border! as Border).top.color, AppTheme.dialogFocus);
    expect(decoration.boxShadow, isNotEmpty);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();

    decoration = _tileDecoration(tester, '新闻频道二');
    expect((decoration.border! as Border).top.color, AppTheme.dialogFocus);
    expect(decoration.boxShadow, isNotEmpty);
  });

  testWidgets('遥控器左右键可切换到频道栏并选台', (tester) async {
    setScreen(tester);
    await tester.pumpWidget(_app());
    await tester.tap(find.text('打开菜单'));
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();

    expect(GetIt.I<IptvStore>().currentIptv.name, '新闻频道二');
    expect(find.text('打开菜单'), findsOneWidget, reason: '选台后应关闭频道面板');
  });

  testWidgets('ESC 关闭双栏面板', (tester) async {
    setScreen(tester);
    await tester.pumpWidget(_app(usePanelPage: true));
    await tester.tap(find.text('打开菜单'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();

    expect(find.text('打开菜单'), findsOneWidget);
    expect(find.text('二级菜单 · 新闻组'), findsNothing);
  });

  testWidgets('频道面板顶部不显示节目状态或分辨率', (tester) async {
    setScreen(tester);
    await tester.pumpWidget(_app(usePanelPage: true));
    await tester.tap(find.text('打开菜单'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();

    expect(find.text('正在播放'), findsNothing);
    expect(find.text('稍后播放'), findsNothing);
    expect(find.textContaining('分辨率'), findsNothing);
    expect(find.text('二级菜单 · 新闻组'), findsOneWidget);
  });
}
