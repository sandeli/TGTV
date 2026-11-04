import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_it/get_it.dart';
import 'package:video_player_example/common/index.dart';
import 'package:video_player_example/common/widgets/delay_renderer.dart';
import 'package:video_player_example/pages/panel/widgets/iptv_ch.dart';
import 'package:video_player_example/pages/panel/widgets/iptv_list.dart';
import 'package:video_player_example/pages/panel/widgets/time.dart';
import '../../common/enums/debug_setting.dart';

class PanelPage extends StatefulWidget {
  const PanelPage({super.key});

  @override
  State<PanelPage> createState() => _PanelPageState();
}

class _PanelPageState extends State<PanelPage> {
  final iptvStore = GetIt.I<IptvStore>();
  static const _menuIdleDuration = Duration(seconds: 10);
  Timer? _menuIdleTimer;
  late final KeyEventCallback _hardwareKeyHandler = _handleHardwareKeyEvent;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_hardwareKeyHandler);
    _resetMenuIdleTimer();
  }

  bool _handleHardwareKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent || event is KeyRepeatEvent) {
      _resetMenuIdleTimer();
    }
    return false;
  }

  void _resetMenuIdleTimer() {
    _menuIdleTimer?.cancel();
    _menuIdleTimer = Timer(_menuIdleDuration, _hideMenuIfIdle);
  }

  void _hideMenuIfIdle() {
    if (!mounted) return;
    // 设置页等子路由在最上层时，只重新等待，绝不能误把子路由弹掉。
    if (ModalRoute.of(context)?.isCurrent != true) {
      _resetMenuIdleTimer();
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _menuIdleTimer?.cancel();
    HardwareKeyboard.instance.removeHandler(_hardwareKeyHandler);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ESC、系统返回与遮罩交给公共电视弹层处理。
    return TvModalScaffold(
      child: Listener(
        onPointerDown: (_) => _resetMenuIdleTimer(),
        child: Stack(
          children: [
            _buildTopRight(context),
            _buildBottom(),
          ].delayed(enable: DebugSettings.delayRender),
        ),
      ),
    );
  }

  // 右上角保留频道号和时间；不显示当前/稍后节目或分辨率。
  Widget _buildTopRight(BuildContext context) {
    if (MediaQuery.of(context).size.shortestSide < 600) {
      return const SizedBox.shrink();
    }
    final onBackground = AppTheme.fg(context);
    return Positioned(
      top: 20.h,
      right: 20.w,
      child: Row(
        children: [
          Observer(
            builder: (_) => PanelIptvChannel(
                iptvStore.currentIptv.channel.toString().padLeft(2, '0')),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 12, 0).r,
            child: SizedBox(
              height: 50.w,
              child: VerticalDivider(
                thickness: 2.w,
                color: onBackground,
              ),
            ),
          ),
          const PanelTime(),
        ],
      ),
    );
  }

  Widget _buildPanelContent() {
    final isCompact = MediaQuery.of(context).size.shortestSide < 600;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isCompact)
          SafeArea(
            bottom: false,
            child: SizedBox(
              height: 44.h,
              child: Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  tooltip: '关闭频道面板',
                  onPressed: () => Navigator.of(context).pop(),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 44, minHeight: 44),
                  iconSize: 20.sp,
                  icon: const Icon(Icons.close),
                ),
              ),
            ),
          ),
        Expanded(child: const PanelIptvList()),
      ].delayed(enable: DebugSettings.delayRender),
    );
  }

  Positioned _buildBottom() {
    final screen = MediaQuery.of(context).size;
    final isCompact = screen.shortestSide < 600;
    final panelWidth = isCompact
        ? screen.width
        : (screen.width * 0.44).clamp(680.0, 1100.0).toDouble();
    final panel = Container(
      padding: EdgeInsets.only(left: isCompact ? 0 : 40).r,
      child: _buildPanelContent(),
    );

    return Positioned(
      top: 0,
      bottom: 0,
      left: 0,
      child: SizedBox(
        width: panelWidth,
        child: panel,
      ),
    );
  }
}
