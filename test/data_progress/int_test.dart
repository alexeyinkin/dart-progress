import 'dart:async';

import 'package:matching/matching.dart';
import 'package:progress_future/progress_future.dart';
import 'package:test/test.dart';

import '../common.dart';

void main() {
  group('DataProgressFuture int', () {
    test('IntDataProgressUpdater.normalized() sets total to 1', () {
      final updater = DataIntProgressUpdater.normalized();
      expect(updater.total, 1);
    });

    test('reports progress', () async {
      final events = <DataProgressEvent>[];
      final fractions = <double?>[];

      final future = runIntsWithProgressAndData(count: count, delay: delay);
      final initialFraction = future.fraction;
      future.events.listen((event) {
        events.add(event);
        fractions.add(future.fraction);
      });

      final result = await future;

      expect(future.total, count);
      expect(future.progress, count);
      expect(result, expectedString);
      expect(events.length, 3);

      expect(events[0].progress, 1);
      expect(events[1].progress, 2);
      expect(events[2].progress, 3);

      expect(events[0].data, '1');
      expect(events[1].data, '2');
      expect(events[2].data, '3');

      expect(events[2].dateTime - events[1].dateTime, isAfter(delay));

      expect(initialFraction, null);
      expect(fractions, [null, 2 / 3, 1.0]);
    });

    group('then', () {
      group('regular future', () {
        test('success', () async {
          final events = [];

          final future = runIntsWithProgressAndData(
            count: count,
            delay: delay,
          );
          final DataIntProgressFuture<int, String> chained =
              future.then((result) => events.length + expectedString.length);

          chained.events.listen(events.add);

          final result = await chained;
          expect(result, count + expectedString.length);
        });

        test('error', () async {
          Exception? actualError;
          StackTrace? actualStackTrace;

          final updater = DataIntProgressUpdater(total: count);
          final future = DataIntProgressFuture.wrap(
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
