import 'dart:convert';

import 'package:xml/xml.dart';

import '../models/iptv.dart';
import 'catchup.dart';

/// 直播源格式
enum IptvSourceFormat {
  /// JSON 数组（兼容外部列表）
  inline,

  /// m3u 订阅
  m3u,

  /// tvbox 文本
  tvbox,

  /// XSPF XML 播放列表
  xspf,
}

/// 根据内容识别直播源格式（与是否配置自定义源无关）
IptvSourceFormat detectSourceFormat(String source) {
  final trimmed = source.replaceFirst('\uFEFF', '').trimLeft();
  if (trimmed.startsWith('[')) return IptvSourceFormat.inline;
  if (trimmed.startsWith('#EXTM3U')) return IptvSourceFormat.m3u;
  if (RegExp(r'<(?:[A-Za-z_][\w.-]*:)?playlist\b').hasMatch(trimmed)) {
    return IptvSourceFormat.xspf;
  }
  return IptvSourceFormat.tvbox;
}

/// 解析 m3u 直播源
Future<List<IptvGroup>> parseM3uSource(String source) async {
  var groupList = <IptvGroup>[];

  final lines = source.split(RegExp(r'\r?\n')).map((line) => line.trim()).toList();

  // #EXTM3U 全局头可能带 catchup 声明（如 catchup="append"），作为所有频道的默认值
  var m3uHead = '';
  for (final line in lines) {
    if (line.startsWith('#EXTM3U')) {
      m3uHead = line;
      break;
    }
  }

  var channel = 0;
  for (final (lineIdx, line) in lines.indexed) {
    if (line.isEmpty || !line.startsWith('#EXTINF:')) {
      continue;
    }

    final groupName = RegExp('group-title="(.*?)"').firstMatch(line)?.group(
        1) ?? '其他';
    final comma = line.indexOf(',');
    if (comma < 0 || lineIdx + 1 >= lines.length) continue;
    final name = line.substring(comma + 1).trim();
    final url = lines[lineIdx + 1].trim();
    if (name.isEmpty || url.isEmpty) continue;

    final group = groupList.firstWhere((it) => it.name == groupName,
        orElse: () {
          final group = IptvGroup(
              idx: groupList.length, name: groupName, list: []);
          groupList.add(group);
          return group;
        });

    // 频道行上的 catchup 属性可覆盖全局声明
    final catchupInfo = CatchupUtil.resolve(m3uHead, line);

    final iptv = Iptv(
      idx: group.list.length,
      channel: ++channel,
      groupIdx: group.idx,
      name: name,
      url: url,
      tvgName: RegExp('tvg-name="(.*?)"').firstMatch(line)?.group(1) ?? name,
      catchup: catchupInfo.type,
      catchupSource: catchupInfo.source,
      catchupDays: catchupInfo.days,
    );

    group.list.add(iptv);
  }

  return groupList;
}

/// 解析 tvbox 直播源
Future<List<IptvGroup>> parseTvboxSource(String source) async {
  var groupList = <IptvGroup>[];

  final lines = source.split(RegExp(r'\r?\n')).map((line) => line.trim()).toList();

  var channel = 0;
  IptvGroup? group;
  for (final line in lines) {
    if (line.isEmpty) continue;
    if (line.startsWith('#')) continue;

    if (line.endsWith('#genre#')) {
      final groupName = line.split(',')[0];
      group = IptvGroup(idx: groupList.length, name: groupName, list: []);
      groupList.add(group);
    } else {
      final newLine = line.replaceAll('，', ',');
      final comma = newLine.indexOf(',');
      if (comma < 1) continue;

      final name = newLine.substring(0, comma).trim();
      final url = newLine.substring(comma + 1).trim();
      if (url.isEmpty) continue;

      group ??= IptvGroup(idx: groupList.length, name: '直播源', list: []);
      if (!groupList.contains(group)) groupList.add(group);

      final iptv = Iptv(
        idx: group.list.length,
        channel: ++channel,
        groupIdx: group.idx,
        name: name,
        url: url,
        tvgName: name,
      );

      group.list.add(iptv);
    }
  }

  return groupList;
}

/// 读取 XML 元素的直接子元素文本，按 localName 匹配以兼容默认/前缀命名空间。
String? _xspfChildText(XmlElement parent, String localName) {
  for (final child in parent.childElements) {
    if (child.name.local == localName) return child.innerText.trim();
  }
  return null;
}

/// 解析 XSPF XML 播放列表。
Future<List<IptvGroup>> parseXspfSource(String source) async {
  final document = XmlDocument.parse(source);
  final root = document.rootElement;
  if (root.name.local != 'playlist') {
    throw const FormatException('不是有效的 XSPF 播放列表');
  }

  XmlElement? trackList;
  for (final child in root.childElements) {
    if (child.name.local == 'trackList') {
      trackList = child;
      break;
    }
  }
  if (trackList == null) throw const FormatException('XSPF 缺少 trackList');

  final fallbackGroup = _xspfChildText(root, 'title');
  final groupsByName = <String, IptvGroup>{};
  var channel = 0;
  for (final track in trackList.childElements.where((element) => element.name.local == 'track')) {
    final location = _xspfChildText(track, 'location');
    if (location == null || location.isEmpty) continue;
    final title = _xspfChildText(track, 'title');
    var groupName = _xspfChildText(track, 'album') ?? _xspfChildText(track, 'creator');
    for (final child in track.childElements) {
      if (child.name.local == 'meta') {
        final rel = (child.getAttribute('rel') ?? '').toLowerCase();
        if (rel.contains('group') && child.innerText.trim().isNotEmpty) {
          groupName = child.innerText.trim();
          break;
        }
      }
    }
    groupName ??= (fallbackGroup == null || fallbackGroup.isEmpty) ? 'XSPF' : fallbackGroup;

    final group = groupsByName.putIfAbsent(
      groupName,
      () => IptvGroup(idx: groupsByName.length, name: groupName!, list: []),
    );
    final name = title == null || title.isEmpty ? location : title;
    group.list.add(Iptv(
      idx: group.list.length,
      channel: ++channel,
      groupIdx: group.idx,
      name: name,
      url: location,
      tvgName: name,
    ));
  }

  return groupsByName.values.toList();
}

/// 解析 inline(JSON) 直播源
///
/// 字段为 `title / url / grouptitle / groupidx`；可选回看字段也兼容
/// `catchup / catchupSource / catchupDays` 的常见大小写写法。
Future<List<IptvGroup>> parseInlineSource(String source) async {
  var groupList = <IptvGroup>[];

  final lines = jsonDecode(source);
  var channel = 0;
  for (var i = 0; i < lines.length; i++) {
    final item = lines[i];
    final groupName = item['grouptitle'].toString().trim();
    final name = item["title"].toString().trim();
    String? pick(List<String> keys) {
      for (final k in keys) {
        final v = item[k];
        if (v == null) continue;
        final s = v.toString().trim();
        if (s.isNotEmpty) return s;
      }
      return null;
    }

    final group = groupList.firstWhere((it) => it.name == groupName,
        orElse: () {
          final group = IptvGroup(
              idx: groupList.length, name: groupName, list: []);
          groupList.add(group);
          return group;
        });

    final iptv = Iptv(
      idx: group.list.length,
      channel: ++channel,
      groupIdx: group.idx,
      name: name,
      url: item['url'].toString().trim(),
      tvgName: name,
      catchup: pick(['catchup', 'catchUp']) ?? '',
      catchupSource: pick(['catchupSource', 'catchupsource', 'catchup_source']) ?? '',
      catchupDays: int.tryParse(pick(['catchupDays', 'catchupdays', 'catchup_days']) ?? '1') ?? 1,
    );

    group.list.add(iptv);
  }

  return groupList;
}

/// 按内容识别格式并解析直播源
Future<List<IptvGroup>> parseIptvSource(String source) async {
  switch (detectSourceFormat(source)) {
    case IptvSourceFormat.inline:
      return parseInlineSource(source);
    case IptvSourceFormat.m3u:
      return parseM3uSource(source);
    case IptvSourceFormat.tvbox:
      return parseTvboxSource(source);
    case IptvSourceFormat.xspf:
      return parseXspfSource(source);
  }
}
