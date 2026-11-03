import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:video_player_example/common/index.dart';

class NetworkSpeedIndicator extends StatefulWidget {
  const NetworkSpeedIndicator({super.key});

  static const MethodChannel _channel =
      MethodChannel('com.htwmedia.htv/network_stats');

  /// 将每秒接收字节数格式化为适合电视屏幕的短标签。
  static String formatRate(num? bytesPerSecond) {
    if (bytesPerSecond == null || !bytesPerSecond.isFinite) return '网速 —';
    if (bytesPerSecond < 1024) {
      return '网速 ${bytesPerSecond.toStringAsFixed(0)} B/s';
    }
    if (bytesPerSecond < 1024 * 1024) {
      return '网速 ${(bytesPerSecond / 1024).toStringAsFixed(1)} KB/s';
    }
    return '网速 ${(bytesPerSecond / (1024 * 1024)).toStringAsFixed(1)} MB/s';
  }

  @override
  State<NetworkSpeedIndicator> createState() => _NetworkSpeedIndicatorState();
}

class _NetworkSpeedIndicatorState extends State<NetworkSpeedIndicator> {
  Timer? _timer;
  int? _previousBytes;
  DateTime? _previousSample;
  double? _bytesPerSecond;
  bool _sampling = false;

  @override
  void initState() {
    super.initState();
    _sample();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _sample());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _sample() async {
    if (_sampling) return;
    _sampling = true;
    try {
      final bytes = await NetworkSpeedIndicator._channel
          .invokeMethod<int>('getUidReceivedBytes');
      final now = DateTime.now();
      if (bytes == null || bytes < 0) {
        _previousBytes = null;
        _previousSample = null;
        if (mounted) setState(() => _bytesPerSecond = null);
        return;
      }

      final previousBytes = _previousBytes;
      final previousSample = _previousSample;
      double? rate;
      if (previousBytes != null && previousSample != null) {
        final seconds = now.difference(previousSample).inMicroseconds / 1000000;
        if (seconds > 0) {
          rate = ((bytes - previousBytes).clamp(0, double.infinity)) / seconds;
        }
      }
      _previousBytes = bytes;
      _previousSample = now;
      if (mounted) setState(() => _bytesPerSecond = rate ?? 0);
    } catch (_) {
      _previousBytes = null;
      _previousSample = null;
      if (mounted) setState(() => _bytesPerSecond = null);
    } finally {
      _sampling = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: AppTheme.bgFaded(context, 0.65),
        borderRadius: BorderRadius.circular(10).r,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.network_check, color: AppTheme.fg(context), size: 22.sp),
          SizedBox(width: 8.w),
          Text(
            NetworkSpeedIndicator.formatRate(_bytesPerSecond),
            style: AppTheme.text(AppTheme.fg(context), 20.sp),
          ),
        ],
      ),
    );
  }
}
