import 'dart:async';

import 'package:matching/matching.dart';
import 'package:progress_future/progress_future.dart';
import 'package:test/test.dart';

import '../common.dart';

void main() {
  group('ProgressFuture common', () {
    group('intercepts errors of the wrapped future', () {
      test('wrap', () async {
        final updater = ProgressUpdater();
        ProgressFuture.wrap(
          Future<void>.delayed(Duration.zero, () => throw Exception()),
          updater,
        ).onError((e, st) => null);

        await Future.delayed(Duration.zero);
      });
    });

    test('can be listened to multiple times', () async {
      final future = runIntsWithProgress(count: count, delay: delay);
      future.events.listen((_) {});

      expect(() => future.events.listen((_) {}), returnsNormally);

      await future;
    });

    test('closes the stream when complete', () async {
      final updater = ProgressUpdater<double>();
      final wrapped = Future.delayed(Duration.zero);
      final future = ProgressFuture.wrap(wrapped, updater);
      await future;

      expect(() => updater.setProgress(100), throwsStateError);
    });

    test('fractions', () async {
      final events = <ProgressEvent>[];
      // 1.0, 1.5, 2.0, 2.5
      final future = runDoublesWithProgress(
        count: 4,
        delay: delay,
        increment: .5,
      );
      final fractionsFuture = future.fractions;

      fractionsFuture.events.listen((event) {
        events.add(event);
      });

      await future;

      expect(events.length, 3);

      expect(events[0].progress, 0.6);
      expect(events[1].progress, 0.8);
      expect(events[2].progress, 1.0);

      expect(events[2].dateTime - events[1].dateTime, isAfter(delay));
    });
  });
}
