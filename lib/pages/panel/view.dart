import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) {
    // 返回方式（点空白 / ESC）与遮罩交给公共外壳处理。
    return TvModalScaffold(
      child: Stack(
        children: [
          _buildTopRight(context),
          _buildBottom(),
        ].delayed(enable: DebugSettings.delayRender),
      ),
    );
  }

  // 右上角保留频道号和时间；不显示当前/稍后节目或分辨率。
  Widget _buildTopRight(BuildContext context) {
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

  Widget _buildPanelContent({required bool isPhone}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isPhone)
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              tooltip: '关闭频道列表',
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.close, color: Colors.white),
            ),
          ),
        Expanded(child: const PanelIptvList()),
      ].delayed(enable: DebugSettings.delayRender),
    );
  }

  Positioned _buildBottom() {
    final screen = MediaQuery.of(context).size;
    final isPhone = screen.shortestSide < 600;
    final panelWidth = isPhone
        ? (screen.width * 0.92).clamp(0.0, 520.0).toDouble()
        : (screen.width * 0.44).clamp(680.0, 1100.0).toDouble();
    final panel = Container(
      padding: EdgeInsets.only(left: isPhone ? 16 : 40).r,
      child: _buildPanelContent(isPhone: isPhone),
    );

    return Positioned(
      top: 0,
      bottom: 0,
      left: 0,
      child: SizedBox(
        width: panelWidth,
        child: isPhone ? SafeArea(child: panel) : panel,
      ),
    );
  }
}
