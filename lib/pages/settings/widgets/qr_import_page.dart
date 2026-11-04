import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';

import '../../../common/style/app_theme.dart';
import '../../../common/widgets/tv_modal_scaffold.dart';

/// 临时二维码页面。只负责把可用草稿提交信号映射为关闭当前路由。
class QrImportPage extends StatefulWidget {
  const QrImportPage({
    super.key,
    required this.serverUrl,
    required this.draftValues,
  });

  final String serverUrl;
  final Stream<String> draftValues;

  @override
  State<QrImportPage> createState() => _QrImportPageState();
}

class _QrImportPageState extends State<QrImportPage> {
  StreamSubscription<String>? _draftSubscription;

  @override
  void initState() {
    super.initState();
    _draftSubscription = widget.draftValues.listen((_) {
      if (!mounted || ModalRoute.of(context)?.isCurrent != true) return;
      Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    unawaited(_draftSubscription?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TvModalScaffold(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = MediaQuery.of(context).size.shortestSide < 600;
          final panelWidth = (constraints.maxWidth - (isCompact ? 32 : 0))
              .clamp(0.0, 1200.w)
              .toDouble();
          final qrSize = isCompact
              ? (panelWidth - 88).clamp(120.0, 300.0).toDouble()
              : 300.h;

          return Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Navigator.of(context).pop(),
                  child: const SizedBox.expand(),
                ),
              ),
              Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(isCompact ? 16 : 0).r,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {},
                    child: Container(
                      width: panelWidth,
                      padding: EdgeInsets.all(32).r,
                      decoration: BoxDecoration(
                        color: AppTheme.qrPanelSurface,
                        borderRadius: BorderRadius.circular(20).r,
                        border: Border.all(
                            color: AppTheme.qrPanelOutline, width: 2),
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
                            widget.serverUrl,
                            textAlign: TextAlign.center,
                            style: AppTheme.text(
                              AppTheme.qrPanelMutedText,
                              24.sp,
                              weight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 12.h),
                          Text(
                            '手机与电视连接同一 Wi-Fi；在手机网页中手动粘贴 M3U / TXT / XSPF 链接。\n提交后仅回填到电视输入框；此页关闭后，请在上一级按“保存”才会正式保存并加载。订阅及设置仅保存在电视本机，请使用可信 Wi-Fi。',
                            textAlign: TextAlign.center,
                            style:
                                AppTheme.text(AppTheme.qrPanelMutedText, 20.sp),
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
                              height: qrSize,
                              width: qrSize,
                              child: PrettyQrView.data(
                                data: widget.serverUrl,
                                decoration: const PrettyQrDecoration(
                                  shape:
                                      PrettyQrSmoothSymbol(color: Colors.black),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 24.h),
                          Text(
                            '点击空白处或按 ESC 返回',
                            style:
                                AppTheme.text(AppTheme.qrPanelMutedText, 20.sp),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
