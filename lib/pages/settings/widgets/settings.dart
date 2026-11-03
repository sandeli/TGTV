import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_it/get_it.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:video_player_example/common/index.dart';

import '../../../common/widgets/two_dimension_list_view.dart';

class SettingItem {
  final String title;
  final String Function() value;
  final String Function() description;
  final void Function() onTap;
  final void Function()? onLongTap;

  SettingItem({
    required this.title,
    required this.value,
    required this.description,
    required this.onTap,
    this.onLongTap,
  });
}

class SettingsMain extends StatefulWidget {
  const SettingsMain({super.key});

  @override
  State<SettingsMain> createState() => _SettingsMainState();
}

class _SettingsMainState extends State<SettingsMain> {
  final iptvStore = GetIt.I<IptvStore>();
  late final List<SettingItem> _settingItemList;

  /// 电视端文本编辑弹窗：复用容器级方向键焦点管理，保证保存按钮可达。
  void _showTvTextEditDialog({
    required String title,
    required String hint,
    required String initialValue,
    required ValueChanged<String> onSave,
    String? subtitle,
    List<TvDialogButton> extraButtons = const <TvDialogButton>[],
    double maxWidth = 500,
    double fontSize = 24,
  }) {
    showDialog(
      context: context,
      builder: (_) => TvTextEditDialog(
        title: title,
        subtitle: subtitle,
        hint: hint,
        initialValue: initialValue,
        onSave: onSave,
        extraButtons: extraButtons,
        maxWidth: maxWidth,
        fontSize: fontSize,
      ),
    );
  }

  void _showCustomSourceDialog() {
    _showTvTextEditDialog(
      title: '自定义直播源',
      subtitle: '支持 M3U、TXT（#genre#）和 XSPF；可用手机扫码导入链接',
      hint: '输入订阅链接',
      initialValue: IptvSettings.customIptvSource,
      maxWidth: 700,
      fontSize: 24,
      extraButtons: [
        TvDialogButton(label: '二维码', onPressed: _showServerQrcode),
      ],
      onSave: (value) {
        IptvSettings.customIptvSource = value.trim();
        IptvSettings.epgCacheHash = 0;
        iptvStore.refreshIptvList().then((_) {
          if (mounted) setState(() {});
        });
      },
    );
  }

  Future<void> _showServerQrcode() async {
    await HttpServerUtil.init();
    if (!mounted) {
      await HttpServerUtil.close();
      return;
    }

    await NavigatorUtil.push(
      context,
      TvModalScaffold(
        child: Center(
          child: Container(
            width: 1200.w,
            padding: EdgeInsets.all(32).r,
            decoration: BoxDecoration(
              color: AppTheme.qrPanelSurface,
              borderRadius: BorderRadius.circular(20).r,
              border: Border.all(color: AppTheme.qrPanelOutline, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.45),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '扫码导入订阅链接',
                  style: AppTheme.text(
                    AppTheme.qrPanelText,
                    36.sp,
                    weight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 12.h),
                Text(
                  HttpServerUtil.serverUrl,
                  textAlign: TextAlign.center,
                  style: AppTheme.text(
                    AppTheme.qrPanelMutedText,
                    24.sp,
                    weight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 12.h),
                Text(
                  '手机与电视连接同一 Wi-Fi；网页输入框为空，手动粘贴 M3U / TXT / XSPF 链接。\n订阅及设置仅保存在电视本机；此页无配对码，仅在二维码页打开时临时提供播放列表导入。请使用可信 Wi-Fi。',
                  textAlign: TextAlign.center,
                  style: AppTheme.text(AppTheme.qrPanelMutedText, 20.sp),
                ),
                SizedBox(height: 24.h),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16).r,
                    border: Border.all(
                      color: AppTheme.qrPanelOutline,
                      width: 1.5,
                    ),
                  ),
                  padding: EdgeInsets.all(12).r,
                  child: SizedBox(
                    height: 300.h,
                    width: 300.h,
                    child: PrettyQrView.data(
                      data: HttpServerUtil.serverUrl,
                      decoration: const PrettyQrDecoration(
                        shape: PrettyQrSmoothSymbol(color: Colors.black),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 24.h),
                Text(
                  '点击空白处或按 ESC 返回',
                  style: AppTheme.text(AppTheme.qrPanelMutedText, 20.sp),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await HttpServerUtil.close();
  }

  @override
  void initState() {
    super.initState();
    refreshSettingItemList();
  }

  @override
  Widget build(BuildContext context) {
    const itemHeight = 190.0;
    final itemWidth = 400.w;

    return SizedBox(
      height: itemHeight + 20.h,
      child: TwoDimensionListView(
        size: (rowHeight: itemHeight, colWidth: itemWidth),
        scrollOffset: (row: 0, col: -1),
        gap: (row: 20.h, col: 20.w),
        itemCount: (row: 1, col: (_) => _settingItemList.length),
        onSelect: (position) => setState(() {
          _settingItemList.elementAtOrNull(position.col)?.onTap();
        }),
        onLongSelect: (position) => setState(() {
          _settingItemList.elementAtOrNull(position.col)?.onLongTap?.call();
        }),
        itemBuilder: (context, position, isSelected) =>
            _buildSettingItem(_settingItemList[position.col], isSelected),
      ),
    );
  }

  Widget _buildSettingItem(SettingItem item, bool isSelected) {
    final textColor = AppTheme.tileText(context, isSelected);

    return Container(
      padding: EdgeInsets.all(30).r,
      decoration: BoxDecoration(
        color:
            isSelected ? AppTheme.fg(context) : AppTheme.bgFaded(context, 0.8),
        borderRadius: BorderRadius.circular(20).r,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                item.title,
                style: AppTheme.text(textColor, 30.sp),
              ),
              Text(
                item.value(),
                style: AppTheme.text(textColor, 30.sp),
              ),
            ],
          ),
          Text(
            item.description(),
            style: AppTheme.text(textColor, 24.sp),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  void refreshSettingItemList() {
    _settingItemList = [
      SettingItem(
        title: '换台反转',
        value: () => IptvSettings.channelChangeFlip ? '反转' : '正常',
        description: () => IptvSettings.channelChangeFlip
            ? '方向键上：下一个频道\n方向键下：上一个频道'
            : '方向键上：上一个频道\n方向键下：下一个频道',
        onTap: () {
          IptvSettings.channelChangeFlip = !IptvSettings.channelChangeFlip;
          setState(() {});
        },
      ),
      SettingItem(
        title: '订阅链接',
        value: () => IptvSettings.customIptvSource.isNotEmpty ? '已导入' : '未导入',
        description: () => IptvSettings.customIptvSource.isEmpty
            ? '点击输入或扫码导入；长按清空'
            : '链接已保存；长按清空',
        onTap: _showCustomSourceDialog,
        onLongTap: () {
          IptvSettings.customIptvSource = '';
          IptvSettings.epgCacheHash = 0;
          iptvStore.refreshIptvList().then((_) {
            if (mounted) setState(() {});
          });
        },
      ),
      SettingItem(
        title: '节目单',
        value: () => IptvSettings.epgEnable ? '启用' : '禁用',
        description: () => '首次加载时可能会有跳帧风险',
        onTap: () {
          IptvSettings.epgEnable = !IptvSettings.epgEnable;
          iptvStore.refreshEpgList().then((_) {
            if (mounted) setState(() {});
          });
        },
      ),
      SettingItem(
        title: '节目单缓存',
        value: () => '当天',
        description: () =>
            IptvSettings.epgXmlCacheTime > 0 ? '已缓存(点击清除缓存)' : '未缓存',
        onTap: () {
          if (IptvSettings.epgXmlCacheTime > 0) {
            IptvSettings.epgXmlCacheTime = 0;
            IptvSettings.epgCacheHash = 0;
            iptvStore.refreshEpgList().then((_) {
              if (mounted) setState(() {});
            });
          }
        },
      ),
    ];
  }
}
