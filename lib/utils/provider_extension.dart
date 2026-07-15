import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

extension KeepAliveExtension on Ref {
  void keepAliveFor(Duration duration) {
    final keepAliveLink = keepAlive();
    Timer? timer;

    onDispose(() {
      timer?.cancel();
    });

    onCancel(() {
      // Start the countdown delay when the UI drops its active watch connection
      timer = Timer(duration, () {
        keepAliveLink.close();
      });
    });

    onResume(() {
      // Halt and void the destruction timer if user steps back into view before expiry
      timer?.cancel();
    });
  }
}
