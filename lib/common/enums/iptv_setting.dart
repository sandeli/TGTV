import '../utils/prefs.dart';
import '../values/constants.dart';

enum IptvDecodeMode { automatic, hardware, software }

extension IptvDecodeModeInfo on IptvDecodeMode {
  String get label => switch (this) {
        IptvDecodeMode.automatic => '自动',
        IptvDecodeMode.hardware => '硬解',
        IptvDecodeMode.software => '软解',
      };

  IptvDecodeMode get next =>
      IptvDecodeMode.values[(index + 1) % IptvDecodeMode.values.length];
}

/// 直播设置
enum IptvSetting {
  /// 初始直播源序号
  initialIptvIdx,

  /// 换台反转
  channelChangeFlip,

  /// 视频解码方式（自动、硬解或软解）
  decodeMode,

  /// 直播源缓存保持时间
  iptvSourceCacheKeepTime,

  /// 自定义直播源
  customIptvSource,

  /// 自定义直播源缓存时间
  customIptvSourceCacheTime,

  /// 自定义直播源缓存对应地址
  customIptvSourceCacheUrl,

  /// 启用epg
  epgEnable,

  /// epg缓存时间
  epgXmlCacheTime,

  /// epg解析缓存hash
  epgCacheHash,

  /// 自定义epg
  customEpgXml,

  /// epg 刷新时间阈值（小时）
  epgRefreshTimeThreshold,

  /// 节目单竖向排列
  channelListVertical,

  /// 回看时间偏移小时数
  ///
  /// m3u 的 `catchup-source` 模板里 ${(b)}/${(e)} 只写格式不写时区，
  /// 服务端按 UTC 还是北京时间解释需要真机校准，这个偏移量就是校准结果。
  catchupUtcOffsetHours,
}

/// 直播设置
class IptvSettings {
  IptvSettings._();

  static int get initialIptvIdx =>
      PrefsUtil.getInt(IptvSetting.initialIptvIdx.toString()) ?? 0;
  static set initialIptvIdx(int value) =>
      PrefsUtil.setInt(IptvSetting.initialIptvIdx.toString(), value);

  static bool get channelChangeFlip =>
      PrefsUtil.getBool(IptvSetting.channelChangeFlip.toString()) ?? false;
  static set channelChangeFlip(bool value) =>
      PrefsUtil.setBool(IptvSetting.channelChangeFlip.toString(), value);

  static IptvDecodeMode get decodeMode {
    final saved = PrefsUtil.getString(IptvSetting.decodeMode.toString());
    return IptvDecodeMode.values.firstWhere(
      (mode) => mode.name == saved,
      orElse: () => IptvDecodeMode.automatic,
    );
  }

  static set decodeMode(IptvDecodeMode value) =>
      PrefsUtil.setString(IptvSetting.decodeMode.toString(), value.name);

  static int get iptvSourceCacheKeepTime =>
      PrefsUtil.getInt(IptvSetting.iptvSourceCacheKeepTime.toString()) ??
      Constants.iptvSourceCacheKeepTime;
  static set iptvSourceCacheKeepTime(int value) =>
      PrefsUtil.setInt(IptvSetting.iptvSourceCacheKeepTime.toString(), value);

  static String get customIptvSource =>
      PrefsUtil.getString(IptvSetting.customIptvSource.toString()) ?? '';
  static set customIptvSource(String value) {
    PrefsUtil.setString(IptvSetting.customIptvSource.toString(), value);
    // 自定义源变更即失效其缓存，下次刷新重新抓取
    PrefsUtil.setInt(IptvSetting.customIptvSourceCacheTime.toString(), 0);
    PrefsUtil.setString(IptvSetting.customIptvSourceCacheUrl.toString(), '');
  }

  static int get customIptvSourceCacheTime =>
      PrefsUtil.getInt(IptvSetting.customIptvSourceCacheTime.toString()) ?? 0;
  static set customIptvSourceCacheTime(int value) =>
      PrefsUtil.setInt(IptvSetting.customIptvSourceCacheTime.toString(), value);

  static String get customIptvSourceCacheUrl =>
      PrefsUtil.getString(IptvSetting.customIptvSourceCacheUrl.toString()) ??
      '';
  static set customIptvSourceCacheUrl(String value) => PrefsUtil.setString(
      IptvSetting.customIptvSourceCacheUrl.toString(), value);

  static bool get epgEnable =>
      PrefsUtil.getBool(IptvSetting.epgEnable.toString()) ?? true;
  static set epgEnable(bool value) =>
      PrefsUtil.setBool(IptvSetting.epgEnable.toString(), value);

  static int get epgXmlCacheTime =>
      PrefsUtil.getInt(IptvSetting.epgXmlCacheTime.toString()) ?? 0;
  static set epgXmlCacheTime(int value) =>
      PrefsUtil.setInt(IptvSetting.epgXmlCacheTime.toString(), value);

  static int get epgCacheHash =>
      PrefsUtil.getInt(IptvSetting.epgCacheHash.toString()) ?? 0;
  static set epgCacheHash(int value) =>
      PrefsUtil.setInt(IptvSetting.epgCacheHash.toString(), value);

  static String get customEpgXml =>
      PrefsUtil.getString(IptvSetting.customEpgXml.toString()) ?? '';
  static set customEpgXml(String value) =>
      PrefsUtil.setString(IptvSetting.customEpgXml.toString(), value);

  static int get epgRefreshTimeThreshold =>
      PrefsUtil.getInt(IptvSetting.epgRefreshTimeThreshold.toString()) ??
      Constants.epgRefreshTimeThreshold;
  static set epgRefreshTimeThreshold(int value) =>
      PrefsUtil.setInt(IptvSetting.epgRefreshTimeThreshold.toString(), value);

  static bool get channelListVertical =>
      PrefsUtil.getBool(IptvSetting.channelListVertical.toString()) ?? false;
  static set channelListVertical(bool value) =>
      PrefsUtil.setBool(IptvSetting.channelListVertical.toString(), value);

  /// 回看地址里 ${(b)}/${(e)} 的时间偏移（小时）
  ///
  /// 默认 8 即北京时间：EPG 的 start/stop 带 `+0800`，多数国内回看服务按本地时间解释。
  /// 若回看内容对不上，把它调成 0 试 UTC。
  static int get catchupUtcOffsetHours =>
      PrefsUtil.getInt(IptvSetting.catchupUtcOffsetHours.toString()) ?? 8;
  static set catchupUtcOffsetHours(int value) =>
      PrefsUtil.setInt(IptvSetting.catchupUtcOffsetHours.toString(), value);
}
