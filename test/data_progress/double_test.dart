import 'dart:async';

import 'package:matching/matching.dart';
import 'package:progress_future/progress_future.dart';
import 'package:test/test.dart';

import '../common.dart';

void main() {
  group('DataProgressFuture double', () {
    test('DoubleDataProgressUpdater.normalized() sets total to 1', () {
      final updater = DataDoubleProgressUpdater.normalized();
      expect(updater.total, 1.0);
    });

    test('reports progress', () async {
      final events = <DataProgressEvent>[];
      final fractions = <double?>[];

      final future = runDoublesWithProgressAndData(
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

      expect(events[0].data, '1.0');
      expect(events[1].data, '1.5');
      expect(events[2].data, '2.0');

      expect(events[2].dateTime - events[1].dateTime, isAfter(delay));

      expect(initialFraction, null);
      expect(fractions, [null, .75, 1.0]);
    });

    group('then', () {
      group('regular future', () {
        test('success', () async {
          final events = [];

          final future = runDoublesWithProgressAndData(
            count: count,
            delay: delay,
            increment: .5,
          );
          final DataDoubleProgressFuture<int, String> chained =
              future.then((result) => events.length + expectedString.length);

          chained.events.listen(events.add);

          final result = await chained;
          expect(result, count + expectedString.length);
        });

        test('error', () async {
          Exception? actualError;
          StackTrace? actualStackTrace;

          final updater = DataDoubleProgressUpdater(total: count.toDouble());
          final future = DataDoubleProgressFuture.wrap(
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
  });
}
