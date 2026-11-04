import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../style/index.dart';
import 'tv_dialog_frame.dart';

class TvDialogSaveException implements Exception {
  const TvDialogSaveException(this.message);

  final String message;
}

/// 弹窗按钮描述
class TvDialogButton {
  const TvDialogButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;
}

/// 电视端文本编辑弹窗
///
/// 焦点环是「输入框 → 自定义按钮 → 取消 → 保存」的一维序列，
/// 由容器层统一托管方向键与 OK 键，保证「保存」永远可达；
/// 输入框需要按 OK 进入编辑，按返回键退出编辑。
class TvTextEditDialog extends StatefulWidget {
  const TvTextEditDialog({
    super.key,
    required this.title,
    required this.hint,
    required this.initialValue,
    required this.onSave,
    this.draftValues,
    this.subtitle,
    this.extraButtons = const <TvDialogButton>[],
    this.maxWidth = 500,
    this.fontSize = 24,
  });

  final String title;
  final String? subtitle;
  final String hint;
  final String initialValue;
  final FutureOr<void> Function(String) onSave;
  final Stream<String>? draftValues;
  final List<TvDialogButton> extraButtons;

  /// 弹窗宽度（设计稿单位）
  final double maxWidth;

  /// 正文字号（设计稿单位）
  final double fontSize;

  @override
  State<TvTextEditDialog> createState() => _TvTextEditDialogState();
}

class _TvTextEditDialogState extends State<TvTextEditDialog>
    with TvDialogEditStateMixin<TvTextEditDialog> {
  /// 焦点环中的「输入框」位置
  static const int _fieldIndex = 0;

  final _fieldFocusNode = FocusNode(debugLabel: 'TvTextEditField');

  late final TextEditingController _controller;
  late final List<TvDialogButton> _buttons;
  late final List<FocusNode> _buttonNodes;
  StreamSubscription<String>? _draftSubscription;
  String? _saveError;
  bool _isSaving = false;

  /// 当前焦点序号：0 为输入框，其余为 extraButtons + 取消 + 保存
  int _focusIndex = _fieldIndex;

  @override
  FocusNode get tvEditFocusNode => _fieldFocusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _buttons = <TvDialogButton>[
      ...widget.extraButtons,
      TvDialogButton(label: '取消', onPressed: () => Navigator.pop(context)),
      TvDialogButton(label: '保存', onPressed: _save),
    ];
    _buttonNodes = List.generate(_buttons.length, (_) => FocusNode());
    _draftSubscription = widget.draftValues?.listen((draft) {
      if (!mounted) return;
      _controller.value = TextEditingValue(
        text: draft,
        selection: TextSelection.collapsed(offset: draft.length),
      );
      setState(() => _saveError = null);
    });

    // 初帧给输入框的高亮落在容器层，不把焦点真交给 EditableText
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) tvRootFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    unawaited(_draftSubscription?.cancel());
    _controller.dispose();
    for (final node in _buttonNodes) {
      node.dispose();
    }
    super.dispose();
  }

  int get _ringCount => _buttonNodes.length + 1;

  Future<void> _save() async {
    if (_isSaving) return;
    setState(() {
      _isSaving = true;
      _saveError = null;
    });
    try {
      await widget.onSave(_controller.text);
      if (mounted) Navigator.pop(context);
    } on TvDialogSaveException catch (error) {
      if (mounted) setState(() => _saveError = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _saveError = '保存失败，请检查订阅链接和网络后重试。');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _requestFocusIndex(int index) {
    if (_buttonNodes.isEmpty) return;
    final count = _ringCount;
    final next = ((index % count) + count) % count;
    setState(() => _focusIndex = next);
    // 落在输入框上时只做高亮，不真正把焦点交给它，
    // 否则 EditableText 会立刻接管方向键
    if (next == _fieldIndex) {
      tvRootFocusNode.requestFocus();
    } else {
      _buttonNodes[next - 1].requestFocus();
    }
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    final common = tvHandleCommonKey(event);
    if (common != null) return common;

    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowDown ||
        key == LogicalKeyboardKey.arrowRight) {
      _requestFocusIndex(_focusIndex + 1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowUp ||
        key == LogicalKeyboardKey.arrowLeft) {
      _requestFocusIndex(_focusIndex - 1);
      return KeyEventResult.handled;
    }
    if (isTvConfirmKey(key)) {
      if (_focusIndex == _fieldIndex) {
        tvEnterEditing();
      } else {
        // _focusIndex 为 0 时代表输入框，按钮从 1 开始
        _buttons[_focusIndex - 1].onPressed();
      }
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  ButtonStyle _actionButtonStyle() {
    return ButtonStyle(
      backgroundColor: MaterialStateProperty.resolveWith<Color>(
        (states) => states.contains(MaterialState.focused)
            ? AppTheme.dialogFocus
            : AppTheme.dialogActionFill,
      ),
      foregroundColor: MaterialStateProperty.all(AppTheme.dialogActionText),
      textStyle: MaterialStateProperty.all(
        AppTheme.text(
          AppTheme.dialogActionText,
          widget.fontSize.sp,
          weight: FontWeight.w600,
        ),
      ),
      side: MaterialStateProperty.resolveWith<BorderSide>(
        (states) => BorderSide(
          color: states.contains(MaterialState.focused)
              ? AppTheme.dialogActionText
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

  @override
  Widget build(BuildContext context) {
    final fg = AppTheme.fg(context);
    return TvDialogFrame(
      focusNode: tvRootFocusNode,
      onKeyEvent: _handleKey,
      maxWidth: widget.maxWidth,
      fontSize: widget.fontSize,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: AppTheme.text(fg, (widget.fontSize + 8).sp),
            ),
            if (widget.subtitle != null) ...[
              SizedBox(height: 12.h),
              Text(
                widget.subtitle!,
                style: AppTheme.text(
                    AppTheme.fgFaded(context, AppTheme.oSecondary),
                    widget.fontSize.sp),
              ),
            ],
            SizedBox(height: 20.h),
            _buildField(),
            if (_saveError != null) ...[
              SizedBox(height: 12.h),
              Text(
                _saveError!,
                style: AppTheme.text(
                  AppTheme.error(context),
                  widget.fontSize.sp,
                  weight: FontWeight.w600,
                ),
              ),
            ],
            SizedBox(height: 20.h),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 16.w,
              runSpacing: 8.h,
              children: [
                for (var i = 0; i < _buttonNodes.length; i++)
                  TextButton(
                    focusNode: _buttonNodes[i],
                    onPressed: _buttons[i].onPressed,
                    style: _actionButtonStyle(),
                    child: Text(
                      _isSaving && _buttons[i].label == '保存'
                          ? '正在保存…'
                          : _buttons[i].label,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField() {
    return TvDialogField(
      controller: _controller,
      focusNode: _fieldFocusNode,
      hint: widget.hint,
      fontSize: widget.fontSize,
      // 编辑态自然要高亮；非编辑态下随焦点环是否落在输入框上
      active: tvEditing || _focusIndex == _fieldIndex,
      editing: tvEditing,
      onActivate: tvEditing ? null : tvEnterEditing,
      enableInteractiveSelection:
          MediaQuery.of(context).size.shortestSide < 600,
      onChanged: (_) {
        if (_saveError != null) setState(() => _saveError = null);
      },
      onSubmitted: (_) => tvExitEditing(),
    );
  }
}
