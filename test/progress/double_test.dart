import 'dart:async';

import 'package:matching/matching.dart';
import 'package:progress_future/progress_future.dart';
import 'package:test/test.dart';

import '../common.dart';

void main() {
  group('ProgressFuture double', () {
    test('DoubleProgressUpdater.normalized() sets total to 1', () {
      final updater = DoubleProgressUpdater.normalized();
      expect(updater.total, 1.0);
    });

    test('reports progress', () async {
      final events = <ProgressEvent>[];
      final fractions = <double?>[];

      final future = runDoublesWithProgress(
        count: count,
        delay: delay,
        increment: .5,
      );
      final initialFraction = future.fraction;
      future.events.listen((event) {
        events.add(event);
        fractions.add(future.fraction);
      });

      final result = await future;

      expect(future.total, 1 + (count - 1) * .5); // Hardcoded in generator.
      expect(future.progress, 2.0);
      expect(result, expectedString);
      expect(events.length, 3);

      expect(events[0].progress, 1.0);
      expect(events[1].progress, 1.5);
      expect(events[2].progress, 2.0);

      expect(events[2].dateTime - events[1].dateTime, isAfter(delay));

      expect(initialFraction, null);
      expect(fractions, [null, .75, 1.0]);
    });

    group('then', () {
      group('regular future', () {
        test('success', () async {
          final events = [];

          final future = runDoublesWithProgress(
            count: count,
            delay: delay,
            increment: .5,
          );
          final DoubleProgressFuture<int> chained =
              future.then((result) => events.length + expectedString.length);

          chained.events.listen((event) {
            events.add(event);
          });

          final result = await chained;
          expect(result, count + expectedString.length);
        });

        test('error', () async {
          Exception? actualError;
          StackTrace? actualStackTrace;

          final updater = DoubleProgressUpdater(total: count.toDouble());
          final future = DoubleProgressFuture.wrap(
            Future<String>.delayed(
              Duration.zero,
              () => throw Exception(errorText),
            ),
            updater,
          );
          final chained = future.then(
            (r) => r * 2,
            onError: (error, stackTrace) {
              actualError = error;
              actualStackTrace = stackTrace;
              return expectedString;
            },
          );

          final result = await chained;

          expect(actualError, isA<Exception>());
          expect(actualStackTrace, isNotNull);
          expect(result, expectedString);
        });
      });
    });

    group('wrapWithoutProgress', () {
      test('with total 1', () async {
        final events = <ProgressEvent>[];

        final regular = Future.delayed(delay, () => expectedString);
        final future = DoubleProgressFuture.wrapWithoutProgress(regular);

        future.events.listen((event) {
          events.add(event);
        });

        final result = await future;

        expect(result, expectedString);
        expect(events, isEmpty);

        await Future.delayed(Duration.zero);

        expect(events.length, 1);
        expect(events[0].progress, 1.0);
      });

      test('with arbitrary total', () async {
        final events = <ProgressEvent>[];

        final regular = Future.delayed(delay, () => expectedString);
        final future = DoubleProgressFuture.wrapWithoutProgress(
          regular,
          total: 7,
        );

        future.events.listen((event) {
          events.add(event);
        });

        final result = await future;

        expect(result, expectedString);
        expect(events, isEmpty);

        await Future.delayed(Duration.zero);

        expect(events.length, 1);
        expect(events[0].progress, 7.0);
      });
    });

    group('wrapDelayedWithoutProgress', () {
      test('with total 1', () async {
        final events = <ProgressEvent>[];

        final regular = Future.delayed(delay, () => expectedString);
        final future = DoubleProgressFuture.wrapDelayedWithoutProgress(regular);

        future.events.listen((event) {
          events.add(event);
        });

        final result = await future;

        expect(result, expectedString);
        expect(events.length, 1);
        expect(events[0].progress, 1.0);
      });

      test('with arbitrary total', () async {
        final events = <ProgressEvent>[];

        final regular = Future.delayed(delay, () => expectedString);
        final future = DoubleProgressFuture.wrapDelayedWithoutProgress(
          regular,
          total: 7,
        );

        future.events.listen((event) {
          events.add(event);
        });

        final result = await future;

        expect(result, expectedString);
        expect(events.length, 1);
        expect(events[0].progress, 7.0);
      });
    });

    test('value', () async {
      final events = <String>[];
      final progressFuture = DoubleProgressFuture.value(expectedString);
      final future = progressFuture.then((r) {
        events.add('ProgressFuture complete');
        return r;
      });
      scheduleMicrotask(() {
        events.add('A microtask complete');
      });

      expect(progressFuture.total, 0.0);

      // This yields for 1 event loop iteration only.
      await Future.delayed(Duration.zero);

      // If ProgressFuture.value took any longer than a single microtask,
      // the order would be different.
      expect(events, ['ProgressFuture complete', 'A microtask complete']);
      expect(await future, expectedString);
    });

    test('wait', () async {
      final events = <ProgressEvent>[];

      final future = DoubleProgressFuture.wait<String, double>([
        runDoublesWithProgress(count: count, delay: delay, increment: .5),
        runDoublesWithProgress(count: count, delay: delay, increment: 1),
      ]);

      future.events.listen((event) {
        events.add(event);
      });

      final result = await future;

      expect(future.total, 5.0);
      expect(result, [expectedString, expectedString]);
      expect(events.length, 6);

      expect(events[0].progress, 1.0);
      expect(events[1].progress, 2.0);
      expect(events[2].progress, 2.5);
      expect(events[3].progress, 3.5);
      expect(events[4].progress, 4.0);
      expect(events[5].progress, 5.0);

      expect(events[4].dateTime - events[3].dateTime, isAfter(delay));
      expect(events[5].dateTime - events[4].dateTime, isBefore(delay));
    });
  });
}
