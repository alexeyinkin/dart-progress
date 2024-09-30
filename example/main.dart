import 'package:progress_future/progress_future.dart';

Future<void> main() async {
  // Integer progress:
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
