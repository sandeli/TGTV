import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player_example/common/index.dart';

const _customUrl = 'http://custom.test/result.m3u';

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
        if (call.method == 'getApplicationSupportDirectory')
          return cacheDir.path;
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
      File('${tmpDir.path}/custom.txt'),
      File('${cacheDir.path}/custom.txt'),
    ]) {
      if (file.existsSync()) file.deleteSync();
    }
    IptvSettings.customIptvSource = '';
  });

  group('用户订阅缓存', () {
    test('缓存新鲜且链接匹配时未失效', () {
      IptvSettings.customIptvSource = _customUrl;
      IptvSettings.customIptvSourceCacheTime =
          DateTime.now().millisecondsSinceEpoch;
      IptvSettings.customIptvSourceCacheUrl = _customUrl;
      expect(IptvUtil.isCustomSourceCacheStale(), isFalse);
    });

    test('缓存超时或订阅 URL 变化时失效', () {
      IptvSettings.customIptvSource = _customUrl;
      IptvSettings.customIptvSourceCacheTime =
          DateTime.now().millisecondsSinceEpoch -
              IptvSettings.iptvSourceCacheKeepTime -
              1000;
      IptvSettings.customIptvSourceCacheUrl = _customUrl;
      expect(IptvUtil.isCustomSourceCacheStale(), isTrue);

      IptvSettings.customIptvSource = 'http://custom.test/new.m3u';
      expect(IptvUtil.isCustomSourceCacheStale(), isTrue);
    });
  });

  group('buildGroups', () {
    test('只构建用户订阅分组，频道号从一开始连续编号', () async {
      final groups = await IptvUtil.buildGroups(_m3uCustom);
      expect(groups.length, 1);
      expect(groups.single.name, '自定义组');
      expect(groups.single.list.map((item) => item.name), ['CCTV1', '凤凰卫视']);
      expect(groups.single.list.map((item) => item.channel), [1, 2]);
    });

    test('空播放列表返回空列表', () async {
      expect(await IptvUtil.buildGroups(''), isEmpty);
    });

    test('完整保留 TXT #genre# 的所有分类和频道', () async {
      final groups = await IptvUtil.buildGroups(_genreSource);
      expect(groups.map((group) => group.name), ['央视频道', '购物频道', '地方频道']);
      expect(groups.map((group) => group.idx), [0, 1, 2]);
      expect(groups.map((group) => group.list.single.groupIdx), [0, 1, 2]);
      expect(groups.expand((group) => group.list).map((item) => item.channel),
          [1, 2, 3]);
    });

    test('同名频道的备用 URL 合并，空分组会移除', () async {
      final groups = await IptvUtil.buildGroups(_duplicateSource);
      expect(groups.length, 1);
      expect(groups.single.name, '第一组');
      expect(groups.single.list.single.url, 'http://a/1.m3u8;http://b/2.m3u8');
    });
  });

  group('getCachedGroups', () {
    test('没有用户订阅时返回 null', () async {
      IptvSettings.customIptvSource = '';
      expect(await IptvUtil.getCachedGroups(), isNull);
    });

    test('只返回 URL 匹配的用户订阅缓存', () async {
      File('${cacheDir.path}/custom.txt').writeAsStringSync(_m3uCustom);
      IptvSettings.customIptvSource = _customUrl;
      IptvSettings.customIptvSourceCacheTime =
          DateTime.now().millisecondsSinceEpoch;
      IptvSettings.customIptvSourceCacheUrl = _customUrl;

      final groups = await IptvUtil.getCachedGroups();
      expect(groups, isNotNull);
      expect(groups!.map((group) => group.name), ['自定义组']);
      expect(groups.expand((group) => group.list).map((item) => item.name),
          ['CCTV1', '凤凰卫视']);
    });

    test('缓存 URL 不匹配时不回退到其他数据', () async {
      File('${cacheDir.path}/custom.txt').writeAsStringSync(_m3uCustom);
      IptvSettings.customIptvSource = 'http://custom.test/new.m3u';
      IptvSettings.customIptvSourceCacheUrl = _customUrl;

      expect(await IptvUtil.getCachedGroups(), isNull);
    });

    test('升级时迁移旧用户订阅缓存到本机持久目录', () async {
      final oldCustom = File('${tmpDir.path}/custom.txt')
        ..writeAsStringSync(_m3uCustom);
      await IptvUtil.migrateLegacyCacheFiles();
      expect(await oldCustom.exists(), isFalse);
      expect(
          File('${cacheDir.path}/custom.txt').readAsStringSync(), _m3uCustom);
    });
  });

  test('没有订阅 URL 时刷新返回空列表', () async {
    IptvSettings.customIptvSource = '';
    expect(await IptvUtil.refreshAndGet(), isEmpty);
  });
}
