import 'package:flutter/material.dart';

/// 手机端播放器的常驻触控入口。
///
/// TV 遥控器仍由主页原有的方向键、OK 和设置键处理；这个组件只补充可见的
/// 大触控目标，避免用户必须猜测“点屏幕/长按”手势。
class MobileTouchControlBar extends StatelessWidget {
  const MobileTouchControlBar({
    super.key,
    required this.onPrevious,
    required this.onNext,
    required this.onOpenChannels,
    required this.onOpenSettings,
  });

  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onOpenChannels;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.of(context).size.width < 350;

    return SafeArea(
      minimum: const EdgeInsets.only(bottom: 8),
      child: Center(
        child: Material(
          color: Colors.black.withOpacity(0.72),
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _TouchAction(
                  icon: Icons.skip_previous_rounded,
                  label: '上一台',
                  compact: compact,
                  onTap: onPrevious,
                ),
                _TouchAction(
                  icon: Icons.skip_next_rounded,
                  label: '下一台',
                  compact: compact,
                  onTap: onNext,
                ),
                _TouchAction(
                  icon: Icons.list_alt_rounded,
                  label: '频道列表',
                  compact: compact,
                  onTap: onOpenChannels,
                ),
                _TouchAction(
                  icon: Icons.settings_rounded,
                  label: '设置',
                  compact: compact,
                  onTap: onOpenSettings,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TouchAction extends StatelessWidget {
  const _TouchAction({
    required this.icon,
    required this.label,
    required this.compact,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: compact ? 56 : 72,
          height: 58,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 22),
              if (!compact) ...[
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
