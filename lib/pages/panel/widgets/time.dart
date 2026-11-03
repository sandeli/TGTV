import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:video_player_example/common/index.dart';

class PanelTime extends StatefulWidget {
  const PanelTime({super.key});

  @override
  State<PanelTime> createState() => _PanelTimeState();
}

class _PanelTimeState extends State<PanelTime> {
  static const _weekdays = ['一', '二', '三', '四', '五', '六', '日'];

  DateTime _beijingNow() =>
      DateTime.now().toUtc().add(const Duration(hours: 8));

  late DateTime _now = _beijingNow();
  late final Timer _timer;

  String get _dateLabel =>
      '${_now.month.toString().padLeft(2, '0')}月${_now.day.toString().padLeft(2, '0')}日  周${_weekdays[_now.weekday - 1]}';

  String get _timeLabel =>
      '${_now.hour.toString().padLeft(2, '0')}:${_now.minute.toString().padLeft(2, '0')}:${_now.second.toString().padLeft(2, '0')}';

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = _beijingNow());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(_dateLabel, style: AppTheme.overlayText(20.sp)),
        Text(
          _timeLabel,
          style: AppTheme.overlayText(40.sp, weight: FontWeight.bold),
        ),
      ],
    );
  }
}
