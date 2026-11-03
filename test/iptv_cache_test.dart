import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player_example/common/index.dart';

const _customUrl = 'http://custom.test/result.m3u';
const _oldBuiltin = '[{"grouptitle":"旧频道","title":"旧内置频道","url":"http://old.test/live.m3u8"}]';

const _m3uCustom = '''#EXTM3U
#EXTINF:-1 tvg-name="CCTV1" group-title="自定义组",CCTV1
http://c/1.m3u8
#EXTINF:-1 tvg-name="凤凰卫视" group-title="自定义组",凤凰卫视
http://c/2.m3u8''';

const _genreSource = '''央视频道,#genre#
CCTV1,http://a/1.m3u8
购物频道,#genre#
优购物,http://a/2.m3u8
地方频道,#genre#
湖南卫视,http://a/3.m3u8''';

const _duplicateSource = '''#EXTM3U
#EXTINF:-1 group-title="第一组",同名频道
http://a/1.m3u8
#EXTINF:-1 group-title="第二组",同名频道
http://b/2.m3u8''';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tmpDir;
  late Directory cacheDir;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await PrefsUtil.init();

    tmpDir = Directory.systemTemp.createTempSync('iptv_cache_test');
    cacheDir = Directory('${tmpDir.path}/support')..createSync();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async {
        if (call.method == 'getTemporaryDirectory') return tmpDir.path;
        if (call.method == 'getApplicationSupportDirectory') return cacheDir.path;
        return null;
      },
    );
  });

  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      null,
    );
    tmpDir.deleteSync(recursive: true);
  });

  setUp(() {
    for (final file in [
      File('${tmpDir.path}/iptv.txt'),
      File('${tmpDir.path}/custom.txt'),
      File('${cacheDir.path}/custom.txt'),
    ]) {
      if (file.existsSync()) file.deleteSync();
    }
    IptvSettings.customIptvSource = '';
    IptvSettings.iptvSourceSimplify = false;
    IptvSettings.allowedChannels = [];
  });

  group('用户订阅缓存', () {
    test('缓存新鲜且链接匹配时未失效', () {
      IptvSettings.customIptvSource = _customUrl;
      IptvSettings.customIptvSourceCacheTime = DateTime.now().millisecondsSinceEpoch;
      IptvSettings.customIptvSourceCacheUrl = _customUrl;
      expect(IptvUtil.isCustomSourceCacheStale(), isFalse);
    });

    test('缓存超时或订阅 URL 变化时失效', () {
      IptvSettings.customIptvSource = _customUrl;
      IptvSettings.customIptvSourceCacheTime =
          DateTime.now().millisecondsSinceEpoch - IptvSettings.iptvSourceCacheKeepTime - 1000;
      IptvSettings.customIptvSourceCacheUrl = _customUrl;
      expect(IptvUtil.isCustomSourceCacheStale(), isTrue);

      IptvSettings.customIptvSource = 'http://custom.test/new.m3u';
      expect(IptvUtil.isCustomSourceCacheStale(), isTrue);
    });
  });

  group('buildGroups', () {
    test('只构建用户订阅分组，不添加内置源或自定义后缀', () async {
      final groups = await IptvUtil.buildGroups(_m3uCustom);
      expect(groups.length, 1);
      expect(groups.single.name, '自定义组');
      expect(groups.single.list.map((item) => item.name), ['CCTV1', '凤凰卫视']);
      expect(groups.single.list.map((item) => item.channel), [1, 2]);
    });

    test('空播放列表返回空列表', () async {
      expect(await IptvUtil.buildGroups(''), isEmpty);
    });

    test('只按用户明确选择的频道执行精简，并重排分组索引', () async {
      IptvSettings.iptvSourceSimplify = true;
      IptvSettings.allowedChannels = ['CCTV1', '湖南卫视'];
      final groups = await IptvUtil.buildGroups(_genreSource);
      expect(groups.map((group) => group.name), ['央视频道', '地方频道']);
      expect(groups.map((group) => group.idx), [0, 1]);
      expect(groups[1].list.single.groupIdx, 1);
      expect(groups.expand((group) => group.list).map((item) => item.channel), [1, 2]);
    });

    test('同名频道的备用 URL 合并，空分组会移除', () async {
      final groups = await IptvUtil.buildGroups(_duplicateSource);
      expect(groups.length, 1);
      expect(groups.single.name, '第一组');
      expect(groups.single.list.single.url, 'http://a/1.m3u8;http://b/2.m3u8');
    });
  });

  group('getCachedGroups', () {
    test('没有用户订阅时返回 null，即使旧版内置缓存文件仍存在', () async {
      File('${tmpDir.path}/iptv.txt').writeAsStringSync(_oldBuiltin);
      IptvSettings.customIptvSource = '';
      expect(await IptvUtil.getCachedGroups(), isNull);
    });

    test('只返回 URL 匹配的用户订阅缓存，忽略旧版内置缓存', () async {
      File('${tmpDir.path}/iptv.txt').writeAsStringSync(_oldBuiltin);
      File('${cacheDir.path}/custom.txt').writeAsStringSync(_m3uCustom);
      IptvSettings.customIptvSource = _customUrl;
      IptvSettings.customIptvSourceCacheTime = DateTime.now().millisecondsSinceEpoch;
      IptvSettings.customIptvSourceCacheUrl = _customUrl;

      final groups = await IptvUtil.getCachedGroups();
      expect(groups, isNotNull);
      expect(groups!.map((group) => group.name), ['自定义组']);
      expect(groups.expand((group) => group.list).any((item) => item.name == '旧内置频道'), isFalse);
    });

    test('订阅缓存地址不匹配时不回退到任何旧内置频道', () async {
      File('${tmpDir.path}/iptv.txt').writeAsStringSync(_oldBuiltin);
      File('${cacheDir.path}/custom.txt').writeAsStringSync(_m3uCustom);
      IptvSettings.customIptvSource = 'http://custom.test/new.m3u';
      IptvSettings.customIptvSourceCacheUrl = _customUrl;

      expect(await IptvUtil.getCachedGroups(), isNull);
    });

    test('升级时迁移旧用户订阅缓存并删除旧内置播放列表', () async {
      final legacyBuiltin = File('${tmpDir.path}/iptv.txt')..writeAsStringSync(_oldBuiltin);
      final oldCustom = File('${tmpDir.path}/custom.txt')..writeAsStringSync(_m3uCustom);
      await IptvUtil.migrateLegacyCacheFiles();
      expect(await legacyBuiltin.exists(), isFalse);
      expect(await oldCustom.exists(), isFalse);
      expect(File('${cacheDir.path}/custom.txt').readAsStringSync(), _m3uCustom);
    });
  });

  test('没有订阅 URL 时刷新不会请求远程默认源', () async {
    File('${tmpDir.path}/iptv.txt').writeAsStringSync(_oldBuiltin);
    IptvSettings.customIptvSource = '';
    expect(await IptvUtil.refreshAndGet(), isEmpty);
  });
}
