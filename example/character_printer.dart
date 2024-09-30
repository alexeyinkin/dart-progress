import 'package:progress/printers.dart';
import 'package:progress/progress.dart';

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
