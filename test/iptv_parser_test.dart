import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:video_player_example/common/utils/iptv_parser.dart';

const jsonList = '''[{"grouptitle":"测试组","title":"测试频道","url":"http://a/1.m3u8"}]''';

const m3uSource = '''#EXTM3U x-tvg-url="http://epg.xml" catchup="append"
#EXTINF:-1 tvg-name="CCTV1" tvg-logo="http://l/1.png" group-title="央视频道",CCTV-1
http://a/1.m3u8
#EXTINF:-1 tvg-name="CCTV2" tvg-logo="http://l/2.png" group-title="央视频道",CCTV-2
http://a/2.m3u8
#EXTINF:-1 tvg-name="湖南卫视" tvg-logo="http://l/3.png" group-title="卫视频道",湖南卫视
http://b/3.m3u8''';

const tvboxSource = '''央视频道,#genre#
CCTV1,http://a/1.m3u8
CCTV2，http://a/2.m3u8''';

const xspfSource = '''<?xml version="1.0" encoding="UTF-8"?>
<playlist version="1" xmlns="http://xspf.org/ns/0/">
  <title>测试播放列表</title>
  <trackList>
    <track><title>频道 &amp; 一</title><location>https://example.test/live?a=1&amp;b=2</location><album>新闻组</album></track>
    <track><title>第二频道</title><location>https://example.test/live2.m3u8</location><meta rel="https://example.test/group-title">体育组</meta></track>
    <track><location>https://example.test/live3.m3u8</location></track>
  </trackList>
</playlist>''';

void main() {
  group('detectSourceFormat', () {
    test('JSON 数组识别为 inline 列表', () {
      expect(detectSourceFormat(jsonList), IptvSourceFormat.inline);
    });

    test('#EXTM3U 开头识别为 m3u', () {
      expect(detectSourceFormat(m3uSource), IptvSourceFormat.m3u);
    });

    test('tvbox 文本识别为 TXT', () {
      expect(detectSourceFormat(tvboxSource), IptvSourceFormat.tvbox);
    });

    test('前导空白和 BOM 不影响 m3u 识别', () {
      expect(detectSourceFormat('\uFEFF\n  #EXTM3U x-tvg-url="..."'), IptvSourceFormat.m3u);
    });

    test('XSPF XML 自动识别', () {
      expect(detectSourceFormat(xspfSource), IptvSourceFormat.xspf);
    });
  });

  group('parseIptvSource', () {
    test('兼容外部 JSON 播放列表', () async {
      final groups = await parseIptvSource(jsonList);
      expect(groups.single.name, '测试组');
      expect(groups.single.list.single.name, '测试频道');
      expect(groups.single.list.single.url, 'http://a/1.m3u8');
    });

    test('M3U 解析分组、频道名、URL 和 tvgName', () async {
      final groups = await parseIptvSource(m3uSource);
      expect(groups.length, 2);

      final cctv = groups.firstWhere((g) => g.name == '央视频道');
      expect(cctv.list.length, 2);
      expect(cctv.list[0].name, 'CCTV-1');
      expect(cctv.list[0].url, 'http://a/1.m3u8');
      expect(cctv.list[0].tvgName, 'CCTV1');

      final satellite = groups.firstWhere((g) => g.name == '卫视频道');
      expect(satellite.list.single.name, '湖南卫视');
      expect(satellite.list.single.url, 'http://b/3.m3u8');
    });

    test('M3U 支持 CRLF 换行', () async {
      final groups = await parseIptvSource('#EXTM3U\r\n#EXTINF:-1 group-title="测试",频道\r\nhttp://a/1.m3u8\r\n');
      expect(groups.single.list.single.url, 'http://a/1.m3u8');
    });

    test('TXT 的 #genre# 格式解析', () async {
      final groups = await parseIptvSource(tvboxSource);
      expect(groups.length, 1);
      expect(groups.single.name, '央视频道');
      expect(groups.single.list.length, 2);
      expect(groups.single.list[0].name, 'CCTV1');
      expect(groups.single.list[0].url, 'http://a/1.m3u8');
      expect(groups.single.list[1].name, 'CCTV2');
      expect(groups.single.list[1].url, 'http://a/2.m3u8');
    });

    test('无 #genre# 标头的简单 TXT 会归入默认分组', () async {
      final groups = await parseIptvSource('频道一,http://a/1.m3u8\r\n频道二,http://a/2.m3u8');
      expect(groups.single.name, '直播源');
      expect(groups.single.list.map((item) => item.name), ['频道一', '频道二']);
    });

    test('XSPF 支持 XML 命名空间、分组、实体解码和无标题频道', () async {
      final groups = await parseIptvSource(xspfSource);
      expect(groups.map((group) => group.name), ['新闻组', '体育组', '测试播放列表']);
      expect(groups[0].list.single.name, '频道 & 一');
      expect(groups[0].list.single.url, 'https://example.test/live?a=1&b=2');
      expect(groups[1].list.single.name, '第二频道');
      expect(groups[2].list.single.name, 'https://example.test/live3.m3u8');
    });

    test('XSPF 缺少 trackList 时明确报格式错误', () async {
      await expectLater(
        parseIptvSource('<playlist xmlns="http://xspf.org/ns/0/"/>'),
        throwsFormatException,
      );
    });
  });

  // 真实源回归夹具不纳入仓库；仅在本地存在时才执行。
  group('result.m3u 回归', () {
    test('wget.la 代理的 result.m3u 完整解析', () async {
      final fixture = File('test/fixtures/result.m3u');
      if (!fixture.existsSync()) {
        _log('跳过：本地缺少夹具 test/fixtures/result.m3u');
        return;
      }
      final groups = await parseIptvSource(fixture.readAsStringSync());
      final total = groups.fold<int>(0, (sum, group) => sum + group.list.length);
      expect(groups.length, 9);
      expect(total, 119);
      expect(groups.first.name, '🕘️更新时间');
      expect(groups.first.list.single.name, '2026-02-03 19:05:43');
      final cctv = groups.firstWhere((group) => group.name == '央视频道');
      expect(cctv.list.first.name, 'CCTV-1');
      expect(cctv.list.first.url, 'http://ott.example.com/TVOD/88888888/224/3221225829/1.m3u8?servicetype=1');
    });
  });
}

void _log(String message) {
  // ignore: avoid_print
  print('[iptv_parser] $message');
}
