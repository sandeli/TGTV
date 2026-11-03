/// 应用常量
class Constants {
  /// 直播源缓存保持时间
  static const iptvSourceCacheKeepTime = 1000 * 60 * 60; // 1小时

  /// 节目单 XML（仅在用户启用节目单且已有频道时请求）
  static const iptvEpgXml = 'https://htwmedia.dpdns.org/Home/getepg';

  /// EPG 刷新时间阈值（小时）
  static const epgRefreshTimeThreshold = 6; // 不到6点不刷新

  /// GitHub Releases 更新检查
  static const githubReleaseApi = 'https://api.github.com/repos/sandeli/HTV/releases/latest';
  static const githubReleaseLatest = 'https://github.com/sandeli/HTV/releases/latest';

  /// 局域网导入服务端口
  static const httpServerPort = 10381;

  /// HTTP 请求重试次数
  static const httpRetryCount = 10;

  /// HTTP 请求重试间隔（毫秒）
  static const httpRetryInterval = 3000;
}
