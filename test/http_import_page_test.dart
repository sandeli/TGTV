import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('扫码导入页为空白输入且只提交用户填写的播放列表链接', () async {
    final html = await File('assets/web/index.html').readAsString();

    expect(html, contains('id="playlistUrl"'));
    expect(html, contains('autocomplete="off"'));
    expect(html, contains("request.open('POST', '/api/playlist', true)"));
    expect(html, contains('按“保存”后才会正式保存并加载'));
    expect(html, contains("input.value = '';"));
    expect(html, contains('result && result.message ? result.message'));
    expect(html, isNot(contains('value="')));
    expect(html, isNot(contains('tgys.dpdns.org')));
    expect(html, isNot(contains('HTWMedia.dpdns.org')));
  });
}
