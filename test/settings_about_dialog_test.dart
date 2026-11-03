import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:video_player_example/pages/settings/widgets/settings_about_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    PackageInfo.setMockInitialValues(
      appName: 'TGTV',
      packageName: 'com.example.tgtv',
      version: '1.5.1',
      buildNumber: '616',
      buildSignature: '',
    );
  });

  void setScreen(WidgetTester tester) {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Widget app(SettingsAboutUrlLauncher launcher) {
    return ScreenUtilInit(
      designSize: const Size(1920, 1080),
      minTextAdapt: true,
      child: MaterialApp(
        theme: ThemeData.dark(),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => SettingsAboutDialog(urlLauncher: launcher),
              ),
              child: const Text('打开关于'),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('遥控器可打开 GitHub 和 LICENSE 链接', (tester) async {
    setScreen(tester);
    final opened = <Uri>[];
    await tester.pumpWidget(app((uri) async {
      opened.add(uri);
      return true;
    }));
    await tester.tap(find.text('打开关于'));
    await tester.pumpAndSettle();

    expect(find.text('关于 TGTV'), findsOneWidget);
    expect(find.text('版本：1.5.1'), findsOneWidget);
    expect(find.textContaining('仓库未单独注明 TGTV 著作权人'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    expect(opened, [Uri.parse('https://github.com/sandeli/TGTV')]);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    expect(
      opened,
      [
        Uri.parse('https://github.com/sandeli/TGTV'),
        Uri.parse('https://github.com/sandeli/TGTV/blob/main/LICENSE'),
      ],
    );
  });

  testWidgets('链接启动失败时显示可手动访问的地址', (tester) async {
    setScreen(tester);
    await tester.pumpWidget(app((_) async => false));
    await tester.tap(find.text('打开关于'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('打开 GitHub'));
    await tester.pumpAndSettle();

    expect(find.textContaining('无法打开浏览器'), findsOneWidget);
    expect(
        find.textContaining('https://github.com/sandeli/TGTV'), findsWidgets);
  });
}
