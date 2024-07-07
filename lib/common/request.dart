import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/models/ip.dart';
import 'package:fl_clash/state.dart';
import 'package:flutter/services.dart';

class Request {
  late final Dio _dio;
  int? _port;
  bool _isStart = false;

  Request() {
    _dio = Dio();
    _dio.options = BaseOptions(
      headers: {"User-Agent": globalState.appController.clashConfig.globalUa},
    );
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          _syncProxy();
          return handler.next(options); // 继续请求
        },
      ),
    );
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
  
  Future<String> getDefaultUserAgent() async {
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    if (Platform.isWindows) {
      WindowsDeviceInfo windowsInfo = await deviceInfo.windowsInfo;
      return 'Windows ${windowsInfo.releaseId}';
    } else if (Platform.isMacOS) {
      MacOsDeviceInfo macInfo = await deviceInfo.macOsInfo;
      return 'MacOS ${macInfo.osRelease}';
    } else if (Platform.isLinux) {
      LinuxDeviceInfo linuxInfo = await deviceInfo.linuxInfo;
      return 'Linux ${linuxInfo.prettyName}';
    } else if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      return 'Android ${androidInfo.version.release}; ${androidInfo.model}';
    } else if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      return 'iOS ${iosInfo.systemVersion.replaceAll('.', '_')}';
    } else {
      return 'Unsupported platform';
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
    String userAgent = await getDefaultUserAgent();
    final version = globalState.packageInfo.version;
    final response = await _dio
        .get(
          url,
          options: Options(
            headers: {
              "User-Agent": 'FlC/$version/$userAgent',
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
    final version = globalState.packageInfo.version;
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
