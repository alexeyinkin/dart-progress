import 'dart:async';

import 'package:matching/matching.dart';
import 'package:progress_future/progress_future.dart';
import 'package:test/test.dart';

import '../common.dart';

void main() {
  group('DataProgressFuture common', () {
    group('intercepts errors of the wrapped future', () {
      test('wrap', () async {
        final updater = DataProgressUpdater();
        DataProgressFuture.wrap(
          Future<void>.delayed(Duration.zero, () => throw Exception()),
          updater,
        ).onError((e, st) => null);

        await Future.delayed(Duration.zero);
      });
    });

    test('can be listened to multiple times', () async {
      final future = runIntsWithProgressAndData(count: count, delay: delay);
      future.events.listen((_) {});

      expect(() => future.events.listen((_) {}), returnsNormally);

      await future;
    });

    test('closes the stream when complete', () async {
      final updater = DataProgressUpdater<int, String>();
      final wrapped = Future.delayed(Duration.zero);
      final future = DataProgressFuture.wrap(wrapped, updater);
      await future;

      expect(() => updater.setProgress(100, '100'), throwsStateError);
    });

    test('fractions', () async {
      final events = <DataProgressEvent>[];
      // 1.0, 1.5, 2.0, 2.5
      final future = runDoublesWithProgressAndData(
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

      expect(events[0].data, '1.5');
      expect(events[1].data, '2.0');
      expect(events[2].data, '2.5');

      expect(events[2].dateTime - events[1].dateTime, isAfter(delay));
    });
  });
}
