import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:video_player_example/common/index.dart';
import 'package:video_player_example/pages/settings/widgets/app_info.dart';
import 'package:video_player_example/pages/settings/widgets/settings.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  static const _idleDuration = Duration(seconds: 10);
  Timer? _idleTimer;
  late final KeyEventCallback _hardwareKeyHandler = _handleHardwareKeyEvent;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_hardwareKeyHandler);
    _resetIdleTimer();
  }

  bool _handleHardwareKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent || event is KeyRepeatEvent) {
      _resetIdleTimer();
    }
    return false;
  }

  void _resetIdleTimer() {
    _idleTimer?.cancel();
    _idleTimer = Timer(_idleDuration, _hideIfIdle);
  }

  void _hideIfIdle() {
    if (!mounted) return;

    // 设置弹窗、二维码页或正在编辑的输入框都在子路由中，不能被设置页计时器关闭。
    if (ModalRoute.of(context)?.isCurrent != true) {
      _resetIdleTimer();
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _idleTimer?.cancel();
    HardwareKeyboard.instance.removeHandler(_hardwareKeyHandler);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ESC、系统返回与遮罩交给公共电视弹层处理，与 PanelPage、二维码页一致。
    return TvModalScaffold(
      child: Listener(
        onPointerDown: (_) => _resetIdleTimer(),
        child: Stack(
          children: [
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 40).r,
                  child: DefaultTextStyle(
                    style: const TextStyle(decoration: TextDecoration.none),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SettingsAppInfo(),
                        SizedBox(height: 30.h),
                        const SettingsMain(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
