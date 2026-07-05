// Packages
import 'package:uuid/uuid.dart';
import 'dart:html' as html;


Future<String> getDeviceId() async {
  final storage = html.window.localStorage;
  String? deviceId = storage['helloaltr_device_id'];
  if (deviceId == null || deviceId.isEmpty) {
    deviceId = const Uuid().v4();
    storage['helloaltr_device_id'] = deviceId;
  }
  return deviceId;
}
