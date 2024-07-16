import 'package:matching/matching.dart';
import 'package:progress/progress.dart';
import 'package:test/test.dart';

import 'common.dart';

const _count = 3;
const _delay = const Duration(milliseconds: 100);

void main() {
  group('ProgressFuture', () {
    group('int', () {
      test('reports progress', () async {
        final events = <ProgressEvent>[];
        final fractions = <double?>[];

        final future = runIntsWithProgress(count: _count, delay: _delay);
        final initialFraction = future.fraction;
        future.events.listen((event) {
          events.add(event);
          fractions.add(future.fraction);
        });

        final result = await future;

        expect(result, 'Complete!');
        expect(events.length, 3);

        expect(events[0].progress, 1);
        expect(events[1].progress, 2);
        expect(events[2].progress, 3);

        expect(events[2].dateTime - events[1].dateTime, isAfter(_delay));

        expect(initialFraction, null);
        expect(fractions, [null, 2 / 3, 1.0]);
      });
    });

    group('double', () {
      test('reports progress', () async {
        final events = <ProgressEvent>[];
        final fractions = <double?>[];

        final future = runDoublesWithProgress(
          count: _count,
          delay: _delay,
          increment: .5,
        );
        final initialFraction = future.fraction;
        future.events.listen((event) {
          events.add(event);
          fractions.add(future.fraction);
        });

        final result = await future;

        expect(result, 'Complete!');
        expect(events.length, 3);

        expect(events[0].progress, 1.0);
        expect(events[1].progress, 1.5);
        expect(events[2].progress, 2.0);

        expect(events[2].dateTime - events[1].dateTime, isAfter(_delay));

        expect(initialFraction, null);
        expect(fractions, [null, .75, 1.0]);
      });
    });

    test('can be listened to multiple times', () async {
      final future = runIntsWithProgress(count: _count, delay: _delay);
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
        delay: _delay,
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

      expect(events[2].dateTime - events[1].dateTime, isAfter(_delay));
    });
  });

  group('DataProgressFuture', () {
    group('int', () {
      test('reports progress', () async {
        final events = <DataProgressEvent>[];
        final fractions = <double?>[];

        final future = runIntsWithProgressAndData(count: _count, delay: _delay);
        final initialFraction = future.fraction;
        future.events.listen((event) {
          events.add(event);
          fractions.add(future.fraction);
        });

        final result = await future;

        expect(result, 'Complete!');
        expect(events.length, 3);

        expect(events[0].progress, 1);
        expect(events[1].progress, 2);
        expect(events[2].progress, 3);

        expect(events[0].data, '1');
        expect(events[1].data, '2');
        expect(events[2].data, '3');

        expect(events[2].dateTime - events[1].dateTime, isAfter(_delay));

        expect(initialFraction, null);
        expect(fractions, [null, 2 / 3, 1.0]);
      });
    });

    group('double', () {
      test('reports progress', () async {
        final events = <DataProgressEvent>[];
        final fractions = <double?>[];

        final future = runDoublesWithProgressAndData(
          count: _count,
          delay: _delay,
          increment: .5,
        );
        final initialFraction = future.fraction;
        future.events.listen((event) {
          events.add(event);
          fractions.add(future.fraction);
        });

        final result = await future;

        expect(result, 'Complete!');
        expect(events.length, 3);

        expect(events[0].progress, 1.0);
        expect(events[1].progress, 1.5);
        expect(events[2].progress, 2.0);

        expect(events[0].data, '1.0');
        expect(events[1].data, '1.5');
        expect(events[2].data, '2.0');

        expect(events[2].dateTime - events[1].dateTime, isAfter(_delay));

        expect(initialFraction, null);
        expect(fractions, [null, .75, 1.0]);
      });
    });

    test('can be listened to multiple times', () async {
      final future = runIntsWithProgressAndData(count: _count, delay: _delay);
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
        delay: _delay,
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

      expect(events[2].dateTime - events[1].dateTime, isAfter(_delay));
    });
  });
}

extension on DateTime {
  Duration operator -(DateTime other) => difference(other);
}
