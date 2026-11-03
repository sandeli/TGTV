import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../common/style/index.dart';
import '../../../common/widgets/tv_dialog_frame.dart';

typedef SettingsAboutUrlLauncher = Future<bool> Function(Uri uri);

class SettingsAboutDialog extends StatefulWidget {
  const SettingsAboutDialog({super.key, this.urlLauncher});

  /// 可注入链接启动器，便于测试；正常使用时打开系统浏览器。
  final SettingsAboutUrlLauncher? urlLauncher;

  @override
  State<SettingsAboutDialog> createState() => _SettingsAboutDialogState();
}

class _SettingsAboutDialogState extends State<SettingsAboutDialog> {
  static final Uri _projectUri = Uri.parse('https://github.com/sandeli/TGTV');
  static final Uri _licenseUri =
      Uri.parse('https://github.com/sandeli/TGTV/blob/main/LICENSE');

  final FocusNode _rootFocusNode = FocusNode(debugLabel: 'SettingsAboutRoot');
  final List<FocusNode> _buttonFocusNodes = List<FocusNode>.generate(
    3,
    (index) => FocusNode(debugLabel: 'SettingsAboutAction$index'),
  );
  late final Future<String> _version = PackageInfo.fromPlatform()
      .then((info) => info.version)
      .catchError((_) => '未知');

  int _focusIndex = 0;
  String? _launchError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _buttonFocusNodes.first.requestFocus();
    });
  }

  @override
  void dispose() {
    _rootFocusNode.dispose();
    for (final node in _buttonFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _requestFocus(int index) {
    final count = _buttonFocusNodes.length;
    final next = ((index % count) + count) % count;
    setState(() => _focusIndex = next);
    _buttonFocusNodes[next].requestFocus();
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.escape || key == LogicalKeyboardKey.goBack) {
      Navigator.of(context).pop();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.arrowDown) {
      _requestFocus(_focusIndex + 1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.arrowUp) {
      _requestFocus(_focusIndex - 1);
      return KeyEventResult.handled;
    }
    if (isTvConfirmKey(key)) {
      switch (_focusIndex) {
        case 0:
          unawaited(_openLink(_projectUri));
          break;
        case 1:
          unawaited(_openLink(_licenseUri));
          break;
        case 2:
          Navigator.of(context).pop();
          break;
      }
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Future<void> _openLink(Uri uri) async {
    if (mounted) setState(() => _launchError = null);
    try {
      final opened = widget.urlLauncher == null
          ? await launchUrl(uri, mode: LaunchMode.externalApplication)
          : await widget.urlLauncher!(uri);
      if (!opened && mounted) {
        setState(() => _launchError = '无法打开浏览器，请手动访问：\n$uri');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _launchError = '无法打开浏览器，请手动访问：\n$uri');
      }
    }
  }

  ButtonStyle _actionButtonStyle() {
    return ButtonStyle(
      backgroundColor: MaterialStateProperty.all(AppTheme.dialogActionFill),
      foregroundColor: MaterialStateProperty.all(AppTheme.dialogActionText),
      side: MaterialStateProperty.resolveWith<BorderSide>(
        (states) => BorderSide(
          color: states.contains(MaterialState.focused)
              ? AppTheme.iptvMenuFocus
              : AppTheme.dialogOutline,
          width: states.contains(MaterialState.focused) ? 3 : 1.5,
        ),
      ),
      shape: MaterialStateProperty.all(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(8).r),
      ),
      padding: MaterialStateProperty.all(
        EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
      ),
    );
  }

  Widget _actionButton({
    required int index,
    required String label,
    required VoidCallback onPressed,
  }) {
    return TextButton(
      focusNode: _buttonFocusNodes[index],
      onPressed: onPressed,
      style: _actionButtonStyle(),
      child: Text(label),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fg = AppTheme.fg(context);
    return TvDialogFrame(
      focusNode: _rootFocusNode,
      onKeyEvent: _handleKeyEvent,
      maxWidth: 720,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '关于 TGTV',
            style: AppTheme.text(fg, 34.sp, weight: FontWeight.bold),
          ),
          SizedBox(height: 16.h),
          FutureBuilder<String>(
            future: _version,
            builder: (context, snapshot) => Text(
              '版本：${snapshot.data ?? '读取中…'}',
              style: AppTheme.text(fg, 24.sp),
            ),
          ),
          SizedBox(height: 16.h),
          Text('项目主页',
              style: AppTheme.text(fg, 24.sp, weight: FontWeight.w600)),
          SizedBox(height: 4.h),
          Text(
            _projectUri.toString(),
            style: AppTheme.text(fg, 22.sp).copyWith(
              decoration: TextDecoration.underline,
            ),
          ),
          SizedBox(height: 14.h),
          Text(
            '版权信息：仓库未单独注明 TGTV 著作权人。\n'
            '许可证：Apache License 2.0（见仓库 LICENSE 文件）。',
            style: AppTheme.text(AppTheme.fgFaded(context, 0.9), 22.sp),
          ),
          if (_launchError != null) ...[
            SizedBox(height: 12.h),
            Text(
              _launchError!,
              style: AppTheme.text(AppTheme.error(context), 20.sp),
            ),
          ],
          SizedBox(height: 20.h),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 12.w,
            runSpacing: 8.h,
            children: [
              _actionButton(
                index: 0,
                label: '打开 GitHub',
                onPressed: () => unawaited(_openLink(_projectUri)),
              ),
              _actionButton(
                index: 1,
                label: '查看 LICENSE',
                onPressed: () => unawaited(_openLink(_licenseUri)),
              ),
              _actionButton(
                index: 2,
                label: '关闭',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
