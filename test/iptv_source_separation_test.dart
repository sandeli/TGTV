import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player_example/common/index.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await PrefsUtil.init();
  });

  setUp(() {
    IptvSettings.customIptvSource = '';
  });

  group('空壳默认行为', () {
    test('未导入订阅时没有播放列表地址', () async {
      expect(IptvSettings.customIptvSource, isEmpty);
      expect(await IptvUtil.refreshAndGet(), isEmpty);
    });

    test('只保存用户主动填写的播放列表 URL', () {
      const url = 'https://example.test/list.m3u';
      IptvSettings.customIptvSource = url;
      expect(IptvSettings.customIptvSource, url);
    });

    test('清空订阅会清除旧的缓存链接标记', () {
      IptvSettings.customIptvSource = 'https://example.test/old.txt';
      IptvSettings.customIptvSourceCacheUrl = 'https://example.test/old.txt';
      IptvSettings.customIptvSource = '';
      expect(IptvSettings.customIptvSource, isEmpty);
      expect(IptvSettings.customIptvSourceCacheUrl, isEmpty);
    });
  });
}
