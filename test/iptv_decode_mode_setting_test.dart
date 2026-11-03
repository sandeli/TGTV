import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player_example/common/index.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await PrefsUtil.init();
  });

  test('解码方式默认自动并持久化本地选择', () async {
    expect(IptvSettings.decodeMode, IptvDecodeMode.automatic);

    IptvSettings.decodeMode = IptvDecodeMode.hardware;
    expect(IptvSettings.decodeMode, IptvDecodeMode.hardware);

    IptvSettings.decodeMode = IptvDecodeMode.software;
    expect(IptvSettings.decodeMode, IptvDecodeMode.software);

    IptvSettings.decodeMode = IptvDecodeMode.automatic;
    expect(IptvSettings.decodeMode, IptvDecodeMode.automatic);

    await PrefsUtil.setString(IptvSetting.decodeMode.toString(), 'unknown');
    expect(IptvSettings.decodeMode, IptvDecodeMode.automatic);
  });
}
