// Packages
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';

Future<String> getDeviceId() async {
  try {
    final directory = await getApplicationSupportDirectory();
    final file = File('${directory.path}/helloaltr_device_id.txt');
    if (await file.exists()) {
      final deviceId = await file.readAsString();
      if (deviceId.isNotEmpty) {
        return deviceId.trim();
      }
    }
    final deviceId = const Uuid().v4();
    await file.writeAsString(deviceId);
    return deviceId;
  } catch (e) {
    // Fallback if directory/file operations fail
    return const Uuid().v4();
  }
}
