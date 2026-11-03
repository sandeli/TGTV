import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:video_player_example/common/index.dart';

class SettingsAppInfo extends StatefulWidget {
  const SettingsAppInfo({super.key});

  @override
  State<SettingsAppInfo> createState() => _SettingsAppInfoState();
}

class _SettingsAppInfoState extends State<SettingsAppInfo> {
  late final Future<String> _version = PackageInfo.fromPlatform()
      .then((info) => info.version)
      .catchError((_) => '');

  @override
  Widget build(BuildContext context) {
    final fg = AppTheme.fg(context);
    final isPhone = MediaQuery.of(context).size.shortestSide < 600;

    return FutureBuilder<String>(
      future: _version,
      builder: (context, snapshot) => Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            'TGTV',
            style: AppTheme.text(fg, isPhone ? 32.sp : 60.sp,
                weight: FontWeight.bold),
          ),
          SizedBox(width: isPhone ? 8 : 20.w),
          Text(
            snapshot.hasData ? 'v${snapshot.data}' : ' ',
            style: AppTheme.text(AppTheme.fgFaded(context, AppTheme.oSecondary),
                isPhone ? 16.sp : 30.sp,
                weight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
