import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chat/utils/provider_extension.dart';

void main() {
  group('KeepAliveExtension Tests', () {
    test('keeps provider alive for specified duration and disposes after delay', () async {
      int disposeCount = 0;
      int initializeCount = 0;

      final testProvider = Provider.autoDispose<int>((ref) {
        initializeCount++;
        ref.keepAliveFor(const Duration(milliseconds: 100));
        ref.onDispose(() {
          disposeCount++;
        });
        return 42;
      });

      final container = ProviderContainer();
      addTearDown(container.dispose);

      // 1. Initial read/watch: initializes provider
      final sub1 = container.listen(testProvider, (previous, next) {});
      expect(initializeCount, 1);
      expect(disposeCount, 0);

      // 2. Close subscription (unwatch)
      sub1.close();

      // Immediately after close, it should still be alive because of keep-alive delay
      expect(disposeCount, 0);

      // Wait 50ms (less than 100ms keep-alive duration)
      await Future.delayed(const Duration(milliseconds: 50));
      expect(disposeCount, 0);

      // Wait another 100ms (exceeding 100ms keep-alive duration)
      await Future.delayed(const Duration(milliseconds: 100));
      expect(disposeCount, 1);
    });

    test('cancels keep-alive timer if watched again before delay expires', () async {
      int disposeCount = 0;
      int initializeCount = 0;

      final testProvider = Provider.autoDispose<int>((ref) {
        initializeCount++;
        ref.keepAliveFor(const Duration(milliseconds: 100));
        ref.onDispose(() {
          disposeCount++;
        });
        return 42;
      });

      final container = ProviderContainer();
      addTearDown(container.dispose);

      // 1. Watch provider
      var sub = container.listen(testProvider, (previous, next) {});
      expect(initializeCount, 1);
      expect(disposeCount, 0);

      // 2. Unwatch provider
      sub.close();
      expect(disposeCount, 0);

      // Wait 50ms (timer is running)
      await Future.delayed(const Duration(milliseconds: 50));
      expect(disposeCount, 0);

      // 3. Watch provider again (should resume / cancel timer)
      sub = container.listen(testProvider, (previous, next) {});
      expect(initializeCount, 1); // No re-initialization
      expect(disposeCount, 0);

      // Wait another 100ms (original timer would have expired by now, but was cancelled)
      await Future.delayed(const Duration(milliseconds: 100));
      expect(disposeCount, 0);

      // 4. Clean up / close again
      sub.close();
      // Wait 150ms to allow final disposal
      await Future.delayed(const Duration(milliseconds: 150));
      expect(disposeCount, 1);
    });
  });
}
