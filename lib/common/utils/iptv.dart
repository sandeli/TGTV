import 'dart:io';

import 'package:video_player_example/common/index.dart';
import 'package:path_provider/path_provider.dart';


final _logger = LoggerUtil.create(['iptv']);

/// iptv工具类
class IptvUtil {
  IptvUtil._();

  /// 迁移用户播放列表缓存到应用私有持久目录，并删除旧内置列表缓存。
  static Future<void> migrateLegacyCacheFiles() async {
    try {
      final temporaryDirectory = await getTemporaryDirectory();
      final cacheDirectory = await getApplicationSupportDirectory();
      await cacheDirectory.create(recursive: true);

      final oldCustomCache = File('${temporaryDirectory.path}/custom.txt');
      final customCache = File('${cacheDirectory.path}/custom.txt');
      if (await oldCustomCache.exists()) {
        if (!await customCache.exists()) await oldCustomCache.copy(customCache.path);
        await oldCustomCache.delete();
      }

      // 旧版此文件包含内置频道，不能在升级后继续显示。
      final legacyBuiltinCache = File('${temporaryDirectory.path}/iptv.txt');
      if (await legacyBuiltinCache.exists()) await legacyBuiltinCache.delete();
    } catch (e, st) {
      _logger.handle(e, st);
    }
  }

  /// 自定义源缓存是否已失效（过期或源地址已变更）
  static bool isCustomSourceCacheStale([String? sourceUrl]) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return now - IptvSettings.customIptvSourceCacheTime >= IptvSettings.iptvSourceCacheKeepTime ||
        IptvSettings.customIptvSourceCacheUrl != (sourceUrl ?? IptvSettings.customIptvSource);
  }

  /// 获取自定义直播源缓存文件
  static Future<File> _getCustomCacheFile() async {
    final directory = await getApplicationSupportDirectory();
    await directory.create(recursive: true);
    return File('${directory.path}/custom.txt');
  }

  /// 读取自定义直播源缓存（仅当缓存地址与当前配置一致）
  static Future<String> _getCustomCache([String? sourceUrl]) async {
    final url = sourceUrl ?? IptvSettings.customIptvSource;
    if (IptvSettings.customIptvSource != url || IptvSettings.customIptvSourceCacheUrl != url) return '';
    try {
      final cacheFile = await _getCustomCacheFile();
      if (await cacheFile.exists()) {
        return await cacheFile.readAsString();
      }
    } catch (e, st) {
      _logger.handle(e, st);
    }
    return '';
  }

  /// 获取自定义远程直播源（缓存优先，失效时抓取并写缓存；抓取失败回退旧缓存）
  static Future<String> _getCustomSource(String sourceUrl) async {
    // 不把可能包含账号或访问令牌的订阅 URL 写入日志。
    _logger.debug('获取用户导入的直播源');

    final cache = await _getCustomCache(sourceUrl);
    if (IptvSettings.customIptvSource != sourceUrl) return '';
    if (!isCustomSourceCacheStale(sourceUrl) && cache.isNotEmpty) {
      _logger.debug('使用自定义源缓存');
      return cache;
    }

    try {
      final t2 = DateTime.now().millisecondsSinceEpoch;
      // wget.la 等缓存代理首次抓取(冷缓存)可能需 40s+，使用更长超时
      var result = await RequestUtil.get(sourceUrl,
          timeout: const Duration(seconds: 60));
      _logger.debug('请求自定义直播源耗时: ${DateTime.now().millisecondsSinceEpoch - t2}ms');

      if (IptvSettings.customIptvSource != sourceUrl) return '';
      if (result.isNotEmpty) {
        final cacheFile = await _getCustomCacheFile();
        await cacheFile.writeAsString(result);
        IptvSettings.customIptvSourceCacheTime = DateTime.now().millisecondsSinceEpoch;
        IptvSettings.customIptvSourceCacheUrl = sourceUrl;
        _logger.debug('已缓存自定义直播源');
      } else if (cache.isNotEmpty) {
        _logger.debug('订阅暂不可用，使用原有缓存');
        return cache;
      }
      return result;
    } catch (e) {
      _logger.error('获取用户订阅失败');
      if (cache.isNotEmpty) {
        _logger.debug('自定义源抓取失败，回退旧缓存');
        return cache;
      }
      return '';
    }
  }

  /// 获取已缓存的用户播放列表（无网络请求；旧版内置源缓存不再读取）
  static Future<List<IptvGroup>?> getCachedGroups() async {
    if (IptvSettings.customIptvSource.isEmpty) return null;
    final customCache = await _getCustomCache(IptvSettings.customIptvSource);
    if (customCache.isEmpty) return null;
    return buildGroups(customCache);
  }

  /// 根据 allowedChannels 过滤分组
  static List<IptvGroup> _applySimplifyFilter(List<IptvGroup> groups) {
    final allowed = IptvSettings.allowedChannels;
    var channel = 0;

    return groups
        .map((g) {
          final filtered = <Iptv>[];
          for (final item in g.list) {
            final pass = allowed.isEmpty || allowed.contains(item.name);
            if (!pass) continue;
            filtered.add(Iptv(
              idx: filtered.length,
              channel: ++channel,
              groupIdx: g.idx,
              name: item.name,
              url: item.url,
              tvgName: item.tvgName,
              catchup: item.catchup,
              catchupSource: item.catchupSource,
              catchupDays: item.catchupDays,
            ));
          }
          return IptvGroup(idx: g.idx, name: g.name, list: filtered);
        })
        .where((g) => g.list.isNotEmpty)
        .toList();
  }

  /// 解析直播源
  static Future<List<IptvGroup>> _parseSource(String source,
      {bool filter = true}) async {
    try {
      var groups = await parseIptvSource(source);

      if (filter && IptvSettings.iptvSourceSimplify) {
        groups = _applySimplifyFilter(groups);
      }

      return groups;
    } catch (e, st) {
      _logger.handle(e, st);
      rethrow;
    }
  }

  /// 获取当前源所有频道名称（不应用精简过滤）
  static Future<List<String>> getAllChannelNames() async {
    if (IptvSettings.customIptvSource.isEmpty) return [];
    final cache = await _getCustomCache(IptvSettings.customIptvSource);
    if (cache.isEmpty) return [];
    final groups = await _parseSource(cache, filter: false);
    return groups.expand((g) => g.list.map((i) => i.name)).toList();
  }

  /// 同名频道去重合并（保留首次出现的频道，url 用 ; 连接）
  static List<IptvGroup> _mergeDuplicateChannels(List<IptvGroup> groups) {
    final nameToUrls = <String, String>{};
    final nameToGroupIdx = <String, ({int groupIdx, int idx})>{};
    final result = <IptvGroup>[];

    // 第一遍：收集所有频道的 url 并记录首次出现位置
    for (var group in groups) {
      for (var i = 0; i < group.list.length; i++) {
        final iptv = group.list[i];
        if (nameToUrls.containsKey(iptv.name)) {
          nameToUrls[iptv.name] = '${nameToUrls[iptv.name]};${iptv.url}';
        } else {
          nameToUrls[iptv.name] = iptv.url;
          nameToGroupIdx[iptv.name] = (groupIdx: group.idx, idx: i);
        }
      }
    }

    // 第二遍：重建分组，只保留首次出现的频道，并更新合并后的 url
    for (var group in groups) {
      final kept = <Iptv>[];
      for (var i = 0; i < group.list.length; i++) {
        final iptv = group.list[i];
        final firstPos = nameToGroupIdx[iptv.name]!;
        // 只在本组首次出现的位置保留
        if (firstPos.groupIdx == group.idx && firstPos.idx == i) {
          kept.add(Iptv(
            idx: kept.length,
            channel: 0,
            groupIdx: group.idx,
            name: iptv.name,
            url: nameToUrls[iptv.name]!,
            tvgName: iptv.tvgName,
            catchup: iptv.catchup,
            catchupSource: iptv.catchupSource,
            catchupDays: iptv.catchupDays,
          ));
        }
      }
      result.add(IptvGroup(idx: group.idx, name: group.name, list: kept));
    }

    return result.where((g) => g.list.isNotEmpty).toList();
  }

  /// 重排分组与频道索引，并保证索引与最终列表位置严格一致
  ///
  /// 前置的简化过滤（[_applySimplifyFilter]）与同名去重（[_mergeDuplicateChannels]）
  /// 会整组丢弃频道，但重建时保留了原始序号，导致 [IptvGroup.idx] / [Iptv.groupIdx]
  /// 不再等于实际下标——出现"空洞"，甚至大于列表长度。
  ///
  /// 而外层多处把它当作位置索引直接使用（频道面板的定位行、左右键切换分组），
  /// 一旦错位会高亮到错误的分组，或直接越界崩溃。这里按最终位置统一重排，
  /// 同时保持 [Iptv.channel] 的全局连号（供频道号显示与数字选台使用）。
  static List<IptvGroup> _reindex(List<IptvGroup> groups) {
    final result = <IptvGroup>[];
    var channel = 0;

    for (var g = 0; g < groups.length; g++) {
      final group = groups[g];
      final list = <Iptv>[];

      for (var i = 0; i < group.list.length; i++) {
        final old = group.list[i];
        list.add(Iptv(
          idx: i,
          channel: ++channel,
          groupIdx: g,
          name: old.name,
          url: old.url,
          tvgName: old.tvgName,
          catchup: old.catchup,
          catchupSource: old.catchupSource,
          catchupDays: old.catchupDays,
        ));
      }

      result.add(IptvGroup(idx: g, name: group.name, list: list));
    }

    return result;
  }

  /// 解析并整理单个用户播放列表：同名频道合并、频道号重排。
  static Future<List<IptvGroup>> buildGroups(String source) async {
    final groups = source.isEmpty ? <IptvGroup>[] : await _parseSource(source);
    // 前置步骤丢弃过分组，必须按最终位置重排索引后才能对外暴露
    return _reindex(_mergeDuplicateChannels(groups));
  }

  /// 刷新并获取用户主动导入的直播源。
  static Future<List<IptvGroup>> refreshAndGet() async {
    final t0 = DateTime.now().millisecondsSinceEpoch;
    final sourceUrl = IptvSettings.customIptvSource;
    if (sourceUrl.isEmpty) return [];

    final source = await _getCustomSource(sourceUrl);
    if (IptvSettings.customIptvSource != sourceUrl) return [];
    final result = await buildGroups(source);

    _logger.debug('刷新直播源总耗时: ${DateTime.now().millisecondsSinceEpoch - t0}ms');

    return result;
  }
}
