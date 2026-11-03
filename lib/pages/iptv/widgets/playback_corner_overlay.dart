import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../common/style/app_theme.dart';
import '../../panel/widgets/time.dart';
import 'network_speed_indicator.dart';

/// 直接叠加在视频上的三个角落信息，不绘制填充背景。
class PlaybackCornerOverlay extends StatelessWidget {
  const PlaybackCornerOverlay({
    super.key,
    required this.stationName,
  });

  final String stationName;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: 20.h,
            left: 20.w,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 0.42.sw),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                child: Text(
                  stationName,
                  style: AppTheme.overlayText(28.sp, weight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
          Positioned(
            top: 16.h,
            right: 20.w,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              child: const PanelTime(),
            ),
          ),
          Positioned(
            right: 20.w,
            bottom: 20.h,
            child: const NetworkSpeedIndicator(),
          ),
        ],
      ),
    );
  }
}
