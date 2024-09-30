A Future that reports the progress of its completion, and various progress bars to show it in CLI.

# Usage

## Tracking progress

### Tracking progress as an integer value

1. Create `IntProgressUpdater` object.
2. Write a function that returns a regular `Future` and kicks the updater object as it progresses.
3. Wrap that function's `Future` into `IntProgressFuture`.
4. `await` it as you would with any other `Future`. Use its `events` to track the progress of the function.

```dart
Future<void> main() async {
  final future = wait(5);

  future.events.listen((event) {
    print('${event.progress} seconds elapsed.');
  });

  print(await future);
}

IntProgressFuture<String> wait(int seconds) {
  final updater = IntProgressUpdater(total: seconds);
  final generate = (int seconds) async {
    for (int n = 0; n < seconds; n++) {
      updater.setProgress(n);
      await Future.delayed(const Duration(seconds: 1));
    }
    return 'Waited $seconds seconds.';
  };
  return IntProgressFuture.wrap(generate(seconds), updater);
}
```

Output:
```
1 seconds elapsed.
2 seconds elapsed.
3 seconds elapsed.
4 seconds elapsed.
Waited 5 seconds.
```

### Tracking progress as a double value

Use `DoubleProgressUpdater` and `DoubleProgressFuture` if your progress measures as `double` and not `int`.

If your progress is from 0 to 1, use `DoubleProgressUpdater.normalized()` convenience constructor.
It's also defined for `IntProgressUpdater` but makes less sense there.

### Tracking intermediate data in addition to the progress

In addition to the progress, you can report custom data with each event.
For this, use

- `DataIntProgressFuture` and `DataIntProgressUpdater`.
- `DataDoubleProgressFuture` and `DataDoubleProgressUpdater`.

```dart
import 'package:clock/clock.dart';
import 'package:progress/progress.dart';

Future<void> main() async {
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

  final generate = (Duration duration) async {
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
  return DataDoubleProgressFuture.wrap(generate(duration), updater);
}
```

Output:
```
0.507785 seconds elapsed, 0:00:04.492215 left.
1.010969 seconds elapsed, 0:00:03.989031 left.
1.512462 seconds elapsed, 0:00:03.487538 left.
2.013939 seconds elapsed, 0:00:02.986061 left.
2.516299 seconds elapsed, 0:00:02.483701 left.
3.018368 seconds elapsed, 0:00:01.981632 left.
3.519966 seconds elapsed, 0:00:01.480034 left.
4.022319 seconds elapsed, 0:00:00.977681 left.
4.524792 seconds elapsed, 0:00:00.475208 left.
Waited for 0:00:05.000000.
```

Use cases for this include:
- Reporting the ETA if it's non-linear and the client can't just extrapolate the elapsed time.
- Reporting intermediate values if you compute some value in iterations.

### Wrapping a Future without progress

Sometimes you don't have a progress information but still need to return `ProgressFuture`
from your method to maintain a consistent API.

In this case, use `ProgressFuture.wrapWithoutProgress(future)` constructor.

### Wrapping a synchronous value

Use `ProgressFuture.value(value)`.

## Printing the progress

### Printing dots

Use `CharacterProgressPrinter`:

```dart
Future<void> main() async {
  final future = wait(20);
  CharacterProgressPrinter(future);
  print(await future);
}

IntProgressFuture<String> wait(int count) {
  final updater = IntProgressUpdater(total: count);
  final generate = (int count) async {
    for (int n = 0; n < count; n++) {
      updater.setProgress(n);
      await Future.delayed(const Duration(milliseconds: 200));
    }
    return 'Done.';
  };
  return IntProgressFuture.wrap(generate(count), updater);
}
```

Output:
```
...................
Done.
```
