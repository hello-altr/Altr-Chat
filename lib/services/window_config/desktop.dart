// window_config_desktop.dart
import 'dart:io';
import 'package:nativeapi/nativeapi.dart';
import 'package:chat/values.dart'; // To access kMinWindowSize

void configureDesktopWindow() {
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    final window = WindowManager.instance.getCurrent();
    window?.setMinimumSize(kMinWindowSize.width, kMinWindowSize.height);
  }
}