import 'package:clock/clock.dart';
import 'package:progress/progress.dart';

Future<void> main() async {
  // Double progress with additional data:
  final future = waitWithEta(Duration(seconds: 5));

  future.events.listen((event) {
    print('${event.progress} seconds elapsed, ${event.data} left.');
  });

  print(await future);
}

DataDoubleProgressFuture<String, Duration> waitWithEta(Duration duration) {
  final updater = DataDoubleProgressUpdater<Duration>(
    total: duration.inMicroseconds / Duration.microsecondsPerSecond,
  );

  final wrapped = (Duration duration) async {
    final start = clock.now();
    final end = start.add(duration);

    while (true) {
      final now = clock.now();
      final secondsElapsed =
          (now.microsecondsSinceEpoch - start.microsecondsSinceEpoch) /
              Duration.microsecondsPerSecond;

      final left = end.difference(now);

      if (left.inMicroseconds <= 0) {
        break;
      }

      updater.setProgress(secondsElapsed, left);
      await Future.delayed(const Duration(milliseconds: 500));
    }
    return 'Waited for $duration.';
  };
  return DataDoubleProgressFuture.wrap(wrapped(duration), updater);
}
