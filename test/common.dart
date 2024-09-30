import 'package:progress_future/progress_future.dart';

const count = 3;
const delay = Duration(milliseconds: 100);
const expectedString = 'Complete!';
const errorText = 'My custom error test';

IntProgressFuture<String> runIntsWithProgress({
  required int count,
  required Duration delay,
}) {
  final updater = IntProgressUpdater();

  // ignore: discarded_futures
  final wrapped = generateIntsWithProgress(updater, count: count, delay: delay);

  return IntProgressFuture.wrap(wrapped, updater);
}

Future<String> generateIntsWithProgress(
  ProgressUpdater<int> updater, {
  required int count,
  required Duration delay,
}) async {
  await Future.delayed(Duration.zero); // To let a client set a listener.
  updater.setProgress(1);
  await Future.delayed(Duration.zero); // To read fraction before setting total.
  updater.total = count;

  for (int i = 2; i <= count; i++) {
    updater.setProgress(i);
    await Future.delayed(delay);
  }

  return expectedString;
}

DataIntProgressFuture<String, String> runIntsWithProgressAndData({
  required int count,
  required Duration delay,
}) {
  final updater = DataIntProgressUpdater<String>();

  // ignore: discarded_futures
  final wrapped = generateIntsWithProgressAndData(
    updater,
    count: count,
    delay: delay,
  );

  return DataIntProgressFuture.wrap(wrapped, updater);
}

Future<String> generateIntsWithProgressAndData(
  DataProgressUpdater<int, String> updater, {
  required int count,
  required Duration delay,
}) async {
  await Future.delayed(Duration.zero); // To let a client set a listener.
  updater.setProgress(1, '1');
  await Future.delayed(Duration.zero); // To read fraction before setting total.
  updater.total = count;

  for (int i = 2; i <= count; i++) {
    updater.setProgress(i, '$i');
    await Future.delayed(delay);
  }

  return expectedString;
}

DoubleProgressFuture<String> runDoublesWithProgress({
  required int count,
  required Duration delay,
  required double increment,
}) {
  final updater = DoubleProgressUpdater();

  // ignore: discarded_futures
  final wrapped = generateDoublesWithProgress(
    updater,
    count: count,
    delay: delay,
    increment: increment,
  );

  return DoubleProgressFuture.wrap(wrapped, updater);
}

Future<String> generateDoublesWithProgress(
  ProgressUpdater<double> updater, {
  required int count,
  required Duration delay,
  required double increment,
}) async {
  await Future.delayed(Duration.zero); // To let a client set a listener.

  double value = 1;
  updater.setProgress(value);
  await Future.delayed(Duration.zero); // To read fraction before setting total.

  updater.total = value + (count - 1) * increment;

  for (int i = 2; i <= count; i++) {
    value += increment;
    updater.setProgress(value);
    await Future.delayed(delay);
  }

  return expectedString;
}

DataDoubleProgressFuture<String, String> runDoublesWithProgressAndData({
  required int count,
  required Duration delay,
  required double increment,
}) {
  final updater = DataDoubleProgressUpdater<String>();

  // ignore: discarded_futures
  final wrapped = generateDoublesWithProgressAndData(
    updater,
    count: count,
    delay: delay,
    increment: increment,
  );

  return DataDoubleProgressFuture.wrap(wrapped, updater);
}

Future<String> generateDoublesWithProgressAndData(
  DataProgressUpdater<double, String> updater, {
  required int count,
  required Duration delay,
  required double increment,
}) async {
  await Future.delayed(Duration.zero); // To let a client set a listener.

  double value = 1;
  updater.setProgress(value, '$value');
  await Future.delayed(Duration.zero); // To read fraction before setting total.

  updater.total = value + (count - 1) * increment;

  for (int i = 2; i <= count; i++) {
    value += increment;
    updater.setProgress(value, '$value');
    await Future.delayed(delay);
  }

  return expectedString;
}

extension DateTimeExtension on DateTime {
  Duration operator -(DateTime other) => difference(other);
}
