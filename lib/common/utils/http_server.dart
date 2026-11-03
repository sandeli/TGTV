import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:video_player_example/common/index.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';

final _logger = LoggerUtil.create(['http_server']);

class HttpServerUtil {
  HttpServerUtil._();

  static HttpServer? _server;
  static String serverUrl = 'http://0.0.0.0:${Constants.httpServerPort}';
  static const _maxRequestLength = 8192;

  /// 启动局域网导入服务。仅绑定到优先选出的设备地址，不监听所有网卡。
  static Future<void> init() async {
    if (_server != null) return;

    final localIp = await _getLocalIPV4();
    final bindAddress = localIp == '0.0.0.0'
        ? InternetAddress.anyIPv4
        : InternetAddress(localIp);

    final app = Router();
    app.get('/', (request) async {
      try {
        return shelf.Response.ok(
          await rootBundle.loadString('assets/web/index.html'),
          headers: {
            'content-type': 'text/html; charset=utf-8',
            'cache-control': 'no-store',
            'x-content-type-options': 'nosniff',
            'x-frame-options': 'SAMEORIGIN',
          },
        );
      } catch (e, st) {
        _logger.handle(e, st);
        return shelf.Response.internalServerError(body: '加载导入页面失败');
      }
    });

    // 唯一可写接口：只保存用户在扫码页手动提交的 HTTP(S) 播放列表链接。
    app.post('/api/playlist', (request) async {
      final origin = request.headers['origin'];
      if (origin != null && origin != Uri.parse(serverUrl).origin) {
        return _jsonResponse(403, {'ok': false, 'message': '请求来源无效。'});
      }
      final contentType = (request.headers['content-type'] ?? '').toLowerCase();
      if (!contentType.startsWith('application/json')) {
        return _jsonResponse(415, {'ok': false, 'message': '仅接受播放列表链接提交。'});
      }

      final contentLength = int.tryParse(request.headers['content-length'] ?? '');
      if (contentLength != null && contentLength > _maxRequestLength) {
        return _jsonResponse(413, {'ok': false, 'message': '链接过长。'});
      }

      try {
        final body = await request.readAsString();
        if (body.length > _maxRequestLength) {
          return _jsonResponse(413, {'ok': false, 'message': '链接过长。'});
        }
        final payload = jsonDecode(body);
        final rawUrl = payload is Map ? payload['url'] : null;
        if (rawUrl is! String || rawUrl.trim().isEmpty) {
          return _jsonResponse(400, {'ok': false, 'message': '请输入播放列表链接。'});
        }

        final sourceUrl = rawUrl.trim();
        final uri = Uri.tryParse(sourceUrl);
        if (uri == null ||
            !const {'http', 'https'}.contains(uri.scheme.toLowerCase()) ||
            uri.host.isEmpty) {
          return _jsonResponse(400, {'ok': false, 'message': '请输入有效的 HTTP 或 HTTPS 链接。'});
        }

        IptvSettings.customIptvSource = sourceUrl;
        IptvSettings.iptvSourceSimplify = false;
        IptvSettings.epgCacheHash = 0;
        unawaited(_refreshAfterImport());

        return _jsonResponse(200, {
          'ok': true,
          'message': '链接已导入，设备正在获取播放列表。',
        });
      } on FormatException {
        return _jsonResponse(400, {'ok': false, 'message': '请求内容无效，请检查链接后再试。'});
      } catch (e, st) {
        _logger.handle(e, st);
        return _jsonResponse(500, {'ok': false, 'message': '导入失败，请稍后重试。'});
      }
    });

    // 不记录请求 URL：订阅地址可能含有账号或访问令牌。
    final server = await io.serve(app.call, bindAddress, Constants.httpServerPort);
    _server = server;
    serverUrl = 'http://${server.address.address}:${server.port}';
    _logger.debug('局域网订阅导入服务已启动');
  }

  /// 用户退出二维码页后停止监听，避免导入端口在平时暴露于局域网。
  static Future<void> close() async {
    final server = _server;
    if (server == null) return;
    _server = null;
    serverUrl = 'http://0.0.0.0:${Constants.httpServerPort}';
    await server.close(force: true);
    _logger.debug('局域网订阅导入服务已关闭');
  }

  static shelf.Response _jsonResponse(int status, Map<String, Object> body) {
    return shelf.Response(
      status,
      body: jsonEncode(body),
      headers: {
        'content-type': 'application/json; charset=utf-8',
        'cache-control': 'no-store',
      },
    );
  }

  static Future<void> _refreshAfterImport() async {
    try {
      await GetIt.I<IptvStore>().refreshIptvList();
    } catch (e, st) {
      _logger.handle(e, st);
    }
  }

  static Future<String> _getLocalIPV4() async {
    try {
      final interfaces = await NetworkInterface.list(
        includeLoopback: false,
        includeLinkLocal: false,
        type: InternetAddressType.IPv4,
      );
      final addresses = interfaces.expand((it) => it.addresses).toList();
      for (final address in addresses) {
        if (_isPrivateIPv4(address.address)) return address.address;
      }
      if (addresses.isNotEmpty) return addresses.first.address;
    } catch (e, st) {
      _logger.handle(e, st);
    }
    return '0.0.0.0';
  }

  static bool _isPrivateIPv4(String value) {
    final parts = value.split('.').map(int.tryParse).toList();
    if (parts.length != 4 || parts.any((part) => part == null)) return false;
    final a = parts[0]!;
    final b = parts[1]!;
    return a == 10 ||
        a == 192 && b == 168 ||
        a == 172 && b >= 16 && b <= 31;
  }
}
