import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../style/index.dart';

/// 半屏/全屏浮层弹窗的公共外壳。
///
/// Panel（频道面板）、Settings（设置页）、二维码这三处原本各抄了一遍同样的骨架：
///   PopScope(canPop) → Focus（ESC / 方向键）→ 半透明黑底。
/// 内容仅通过电视遥控器、键盘和系统返回操作。
class TvModalScaffold extends StatelessWidget {
  const TvModalScaffold({
    super.key,
    required this.child,
    this.scrimColor = AppTheme.scrim,
  });

  final Widget child;

  /// 遮罩底色
  final Color scrimColor;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      child: Focus(
        onKeyEvent: (node, event) {
          if (event.logicalKey == LogicalKeyboardKey.escape &&
              event is KeyDownEvent) {
            Navigator.pop(context);
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: Container(
          color: scrimColor,
          child: child,
        ),
      ),
    );
  }
}
