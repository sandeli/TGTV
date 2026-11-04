import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player_example/common/index.dart';
import 'package:video_player_example/common/widgets/easy_keyboard_listener.dart';
import 'package:video_player_example/pages/panel/view.dart';
import 'package:video_player_example/pages/panel/widgets/iptv_list.dart';
import 'package:video_player_example/pages/settings/view.dart';

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

Widget _app({
  bool usePanelPage = false,
  bool useSettingsPage = false,
  Size designSize = const Size(1920, 1080),
}) {
  return ScreenUtilInit(
    designSize: designSize,
    minTextAdapt: true,
    child: MaterialApp(
      theme: ThemeData.dark(),
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute<void>(
                  builder: (_) {
                    if (useSettingsPage) return const SettingsPage();
                    if (usePanelPage) return const PanelPage();
                    return Scaffold(
                      body: Align(
                        alignment: Alignment.topLeft,
                        child: SizedBox(
                          width: 480,
                          height: 820,
                          child: const PanelIptvList(),
                        ),
                      ),
                    );
                  },
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

bool _listHasFocus(WidgetTester tester, String label) {
  final listener = tester.widget<EasyKeyboardListener>(
    find
        .ancestor(
          of: find.text(label),
          matching: find.byType(EasyKeyboardListener),
        )
        .first,
  );
  return listener.focusNode.hasFocus;
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

  void setCompactScreen(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 360);
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

  testWidgets('二级频道焦点到第六项后固定位置滚动，列表末尾继续向下到最后一项', (tester) async {
    setScreen(tester);
    final channels = List<Iptv>.generate(
      16,
      (index) => _channel(
        idx: index,
        channel: index + 1,
        groupIdx: 0,
        name: '长频道$index',
      ),
    );
    final store = GetIt.I<IptvStore>();
    store.iptvGroupList = [IptvGroup(idx: 0, name: '长列表', list: channels)];
    store.currentIptv = channels.first;

    await tester.pumpWidget(_app());
    await tester.tap(find.text('打开菜单'));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();

    for (var index = 0; index < 5; index++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
    }
    expect(
      (_tileDecoration(tester, '长频道5').border! as Border).top.color,
      AppTheme.iptvMenuFocusOutline,
    );
    final sixthSlotY = tester.getTopLeft(find.text('长频道5')).dy;
    expect(
      sixthSlotY,
      greaterThan(tester.getTopLeft(find.text('长频道4')).dy),
      reason: '到达第六项前，焦点应随按键逐项向下移动',
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(find.text('长频道6')).dy,
      closeTo(sixthSlotY, 3),
      reason: '超过第六项后焦点应停在原位并滚动频道内容',
    );
    expect(
      (_tileDecoration(tester, '长频道6').border! as Border).top.color,
      AppTheme.iptvMenuFocusOutline,
    );

    for (var index = 7; index < channels.length; index++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
    }
    expect(
      (_tileDecoration(tester, '长频道15').border! as Border).top.color,
      AppTheme.iptvMenuFocusOutline,
    );
    expect(
      tester.getTopLeft(find.text('长频道15')).dy,
      greaterThan(sixthSlotY),
      reason: '滚动到列表底部后，焦点应随屏幕剩余频道继续下移到末项',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('手机横屏两级菜单尺寸紧凑且同时可见', (tester) async {
    setCompactScreen(tester);
    await tester.pumpWidget(
      _app(usePanelPage: true, designSize: const Size(800, 360)),
    );
    await tester.tap(find.text('打开菜单'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();

    expect(find.text('频道分类'), findsOneWidget);
    expect(find.text('二级菜单 · 新闻组'), findsOneWidget);
    expect(find.text('新闻频道一'), findsOneWidget);

    final categoryPane = find.byWidgetPredicate(
      (widget) =>
          widget is Container && widget.color == AppTheme.categoryMenuSurface,
    );
    expect(tester.getSize(categoryPane).width, lessThanOrEqualTo(210));

    final categoryTile = find
        .ancestor(
          of: find.text('新闻组'),
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is Container && widget.decoration is BoxDecoration,
          ),
        )
        .first;
    expect(tester.getSize(categoryTile).height, inInclusiveRange(48, 61));
    expect(tester.takeException(), isNull);
  });

  testWidgets('焦点在两级菜单间移动时白色描边跟随且没有暗色外框', (tester) async {
    setScreen(tester);
    await tester.pumpWidget(_app());
    await tester.tap(find.text('打开菜单'));
    await tester.pumpAndSettle();

    var decoration = _tileDecoration(tester, '新闻组');
    expect(
      (decoration.border! as Border).top.color,
      AppTheme.iptvMenuFocusOutline,
    );
    expect(decoration.color, AppTheme.categoryMenuTileFill);
    expect(decoration.borderRadius, BorderRadius.zero);
    expect(decoration.boxShadow, hasLength(1));
    expect(decoration.boxShadow!.single.color, const Color(0x33FFFFFF));
    expect(decoration.boxShadow!.single.offset, const Offset(0, 2));

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();

    decoration = _tileDecoration(tester, '新闻组');
    expect((decoration.border! as Border).top.color, Colors.transparent);
    expect(decoration.boxShadow, isNull);

    decoration = _tileDecoration(tester, '新闻频道一');
    expect(
      (decoration.border! as Border).top.color,
      AppTheme.iptvMenuFocusOutline,
    );
    expect(decoration.color, AppTheme.channelMenuTileFill);
    expect(decoration.borderRadius, BorderRadius.zero);
    expect(decoration.boxShadow, hasLength(1));
    expect(decoration.boxShadow!.single.color, const Color(0x33FFFFFF));

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();

    decoration = _tileDecoration(tester, '新闻频道一');
    expect((decoration.border! as Border).top.color, Colors.transparent);

    decoration = _tileDecoration(tester, '新闻频道二');
    expect(
      (decoration.border! as Border).top.color,
      AppTheme.iptvMenuFocusOutline,
    );
    expect(decoration.boxShadow, hasLength(1));
  });

  testWidgets('一级和二级菜单焦点往返后仍能恢复到频道', (tester) async {
    setScreen(tester);
    await tester.pumpWidget(_app());
    await tester.tap(find.text('打开菜单'));
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(_listHasFocus(tester, '新闻频道一'), isTrue);
    var decoration = _tileDecoration(tester, '新闻频道一');
    expect(
      (decoration.border! as Border).top.color,
      AppTheme.iptvMenuFocusOutline,
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(_listHasFocus(tester, '新闻组'), isTrue);
    decoration = _tileDecoration(tester, '新闻组');
    expect(
      (decoration.border! as Border).top.color,
      AppTheme.iptvMenuFocusOutline,
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(_listHasFocus(tester, '新闻频道一'), isTrue);
    decoration = _tileDecoration(tester, '新闻频道一');
    expect(
      (decoration.border! as Border).top.color,
      AppTheme.iptvMenuFocusOutline,
    );
  });

  testWidgets('一级和二级菜单使用中性半透明底色且项目均为直角', (tester) async {
    setScreen(tester);
    await tester.pumpWidget(_app());
    await tester.tap(find.text('打开菜单'));
    await tester.pumpAndSettle();

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Container && widget.color == AppTheme.categoryMenuSurface,
      ),
      findsOneWidget,
    );
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Container && widget.color == AppTheme.channelMenuSurface,
      ),
      findsOneWidget,
    );

    final categoryDecoration = _tileDecoration(tester, '体育组');
    final channelDecoration = _tileDecoration(tester, '新闻频道二');
    expect(categoryDecoration.color, AppTheme.categoryMenuTileFill);
    expect(channelDecoration.color, AppTheme.channelMenuTileFill);
    expect(categoryDecoration.borderRadius, BorderRadius.zero);
    expect(channelDecoration.borderRadius, BorderRadius.zero);
    expect(categoryDecoration.color!.alpha, inInclusiveRange(0x20, 0x40));
    expect(channelDecoration.color!.alpha, inInclusiveRange(0x20, 0x40));
    expect(categoryDecoration.color, isNot(channelDecoration.color));
    expect(
      categoryDecoration.color!.alpha,
      lessThan(channelDecoration.color!.alpha),
    );
    expect(
      (channelDecoration.color!.alpha - categoryDecoration.color!.alpha).abs(),
      lessThanOrEqualTo(0x10),
    );
    expect(channelDecoration.borderRadius, BorderRadius.zero);
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

  testWidgets('频道菜单十秒无输入后收起，按键会重置计时且仍可再次打开', (tester) async {
    setScreen(tester);
    await tester.pumpWidget(_app(usePanelPage: true));
    await tester.tap(find.text('打开菜单'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();
    expect(find.text('二级菜单 · 新闻组'), findsOneWidget);

    await tester.pump(const Duration(seconds: 8));
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    await tester.pump(const Duration(seconds: 9));
    expect(find.text('二级菜单 · 新闻组'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text('二级菜单 · 新闻组'), findsNothing);
    expect(find.text('打开菜单'), findsOneWidget);

    await tester.tap(find.text('打开菜单'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();
    expect(find.text('二级菜单 · 新闻组'), findsOneWidget);
  });

  testWidgets('设置页十秒无输入后返回，遥控按键会重置计时', (tester) async {
    setScreen(tester);
    await tester.pumpWidget(_app(useSettingsPage: true));
    await tester.tap(find.text('打开菜单'));
    await tester.pumpAndSettle();
    expect(find.text('TGTV'), findsOneWidget);

    await tester.pump(const Duration(seconds: 8));
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    await tester.pump(const Duration(seconds: 9));
    expect(find.text('TGTV'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text('打开菜单'), findsOneWidget);
  });

  testWidgets('设置子弹窗和文本编辑期间不会被闲置计时器关闭', (tester) async {
    setScreen(tester);
    await tester.pumpWidget(_app(useSettingsPage: true));
    await tester.tap(find.text('打开菜单'));
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    expect(find.text('自定义直播源'), findsOneWidget);

    await tester.pump(const Duration(seconds: 11));
    expect(find.text('自定义直播源'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pump();
    await tester.pump(const Duration(seconds: 11));
    expect(find.text('自定义直播源'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('订阅链接'), findsOneWidget);

    await tester.pump(const Duration(seconds: 9));
    expect(find.text('订阅链接'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text('打开菜单'), findsOneWidget);
  });

  testWidgets('关于是设置最后一项，点击可查看版本与许可证', (tester) async {
    setScreen(tester);
    PackageInfo.setMockInitialValues(
      appName: 'TGTV',
      packageName: 'com.example.tgtv',
      version: '1.5.1',
      buildNumber: '616',
      buildSignature: '',
    );
    await tester.pumpWidget(_app(useSettingsPage: true));
    await tester.tap(find.text('打开菜单'));
    await tester.pumpAndSettle();

    for (var i = 0; i < 5; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
    }
    expect(find.text('关于'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();

    expect(find.text('关于 TGTV'), findsOneWidget);
    expect(find.text('版本：1.5.1'), findsOneWidget);
    expect(find.textContaining('Apache License 2.0'), findsOneWidget);
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
