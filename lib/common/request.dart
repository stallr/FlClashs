import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:fl_clash/models/ip.dart';
import 'package:fl_clash/state.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'constant.dart';
import 'other.dart';
import 'package.dart';

class Request {
  late final Dio _dio;
  int? _port;
  bool _isStart = false;

  Request() {
    _dio = Dio();
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        _syncProxy();
        return handler.next(options); // 继续请求
      },
    ));
  }

  Future<String> _getUserAgent() async {
    const platform = MethodChannel('com.tom.cla/ua');
    try {
      final String userAgent = await platform.invokeMethod('getUserAgent');
      return userAgent;
    } on PlatformException catch (e) {
      return "Failed to get user agent: '${e.message}'.";
    }
  }

  Future<String> _getAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return packageInfo.version;
    } catch (e) {
      return 'Failed to get version';
    }
  }
  
  _syncProxy() {
    final port = globalState.appController.clashConfig.mixedPort;
    final isStart = globalState.appController.appState.isStart;
    if (_port != port || isStart != _isStart) {
      _port = port;
      _isStart = isStart;
      _dio.httpClientAdapter = IOHttpClientAdapter(
        createHttpClient: () {
          final client = HttpClient();
          if (!_isStart) return client;
          client.findProxy = (url) {
            return "PROXY localhost:$_port;DIRECT";
          };
          return client;
        },
      );
    }
  }

  Future<Response> getFileResponseForUrl(String url) async {
    String userAgent = await _getUserAgent();
    String appVersion = await _getAppVersion();
    final response = await _dio
        .get(
          url,
          options: Options(
            headers: {
              "User-Agent": 'FlClash/$appVersion/$userAgent',
            },
            responseType: ResponseType.bytes,
          ),
        )
        .timeout(
          httpTimeoutDuration * 2,
        );
    return response;
  }

  Future<Map<String, dynamic>?> checkForUpdate() async {
    final response = await _dio.get(
      "https://api.github.com/repos/$repository/releases/latest",
      options: Options(
        responseType: ResponseType.json,
      ),
    );
    if (response.statusCode != 200) return null;
    final data = response.data as Map<String, dynamic>;
    final remoteVersion = data['tag_name'];
    final packageInfo = await appPackage.packageInfoCompleter.future;
    final version = packageInfo.version;
    final hasUpdate =
        other.compareVersions(remoteVersion.replaceAll('v', ''), version) > 0;
    if (!hasUpdate) return null;
    return data;
  }

  final Map<String, IpInfo Function(Map<String, dynamic>)> _ipInfoSources = {
    "https://ipwho.is/": IpInfo.fromIpwhoIsJson,
    "https://api.ip.sb/geoip/": IpInfo.fromIpSbJson,
    "https://ipapi.co/json/": IpInfo.fromIpApiCoJson,
    "https://ipinfo.io/json/": IpInfo.fromIpInfoIoJson,
  };

  Future<IpInfo?> checkIp(CancelToken? cancelToken) async {
    for (final source in _ipInfoSources.entries) {
      try {
        final response = await _dio
            .get<Map<String, dynamic>>(source.key, cancelToken: cancelToken)
            .timeout(
              httpTimeoutDuration,
            );
        if (response.statusCode == 200 && response.data != null) {
          return source.value(response.data!);
        }
      } catch (e) {
        continue;
      }
    }
    return null;
  }
}

final request = Request();
