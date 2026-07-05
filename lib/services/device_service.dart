import 'device_service/stub.dart'
    if (dart.library.html) 'device_service/web.dart'
    if (dart.library.io) 'device_service/io.dart' as impl;


class DeviceService {
  static Future<String> getDeviceId() async {
    return impl.getDeviceId();
  }
}
