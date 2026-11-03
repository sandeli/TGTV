import 'package:flutter_test/flutter_test.dart';
import 'package:video_player_example/pages/iptv/widgets/network_speed_indicator.dart';

void main() {
  group('NetworkSpeedIndicator.formatRate', () {
    test('无统计值显示占位符', () {
      expect(NetworkSpeedIndicator.formatRate(null), '网速 —');
    });

    test('按 B/s、KB/s、MB/s 显示接收速率', () {
      expect(NetworkSpeedIndicator.formatRate(0), '网速 0 B/s');
      expect(NetworkSpeedIndicator.formatRate(512), '网速 512 B/s');
      expect(NetworkSpeedIndicator.formatRate(2048), '网速 2.0 KB/s');
      expect(NetworkSpeedIndicator.formatRate(2 * 1024 * 1024), '网速 2.0 MB/s');
    });
  });
}
