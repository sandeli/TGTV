import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('扫码导入页为空白输入且只提交用户填写的播放列表链接', () async {
    final html = await File('assets/web/index.html').readAsString();

    expect(html, contains('id="playlistUrl"'));
    expect(html, contains('autocomplete="off"'));
    expect(html, contains("request.open('POST', '/api/playlist', true)"));
    expect(html, contains('导入后会替换电视当前保存的订阅链接'));
    expect(html, isNot(contains('value="')));
    expect(html, isNot(contains('tgys.dpdns.org')));
    expect(html, isNot(contains('HTWMedia.dpdns.org')));
  });
}
