import 'dart:async';

import 'package:async/async.dart';
import 'package:clock/clock.dart';

import 'util.dart';

/// A [Future] that reports the progress of its completion
/// as an integer.
typedef IntProgressFuture<R> = ProgressFuture<R, int>;

/// A sink for the code wrapped in [IntProgressFuture] to report
/// its progress.
typedef IntProgressUpdater = ProgressUpdater<int>;

/// A [Future] that reports the progress of its completion
/// as a double.
typedef DoubleProgressFuture<R> = ProgressFuture<R, double>;

/// A sink for the code wrapped in [DoubleProgressFuture] to report
/// its progress.
typedef DoubleProgressUpdater = ProgressUpdater<double>;

/// A [Future] that reports the progress
/// of its completion.
abstract class ProgressFuture<R, N extends num> implements Future<R> {
  /// The progress events.
  Stream<ProgressEvent<N>> get events;

  /// Returns the current progress.
  N get progress;

  /// Returns the cap of the progress or `null` if it is unknown.
  N? get total;

  /// Returns the progress as of the last fired event as a fraction of 1.
  double? get fraction;

  /// Creates the version of this future with the progress reported
  /// as fractions of 1.
  ProgressFuture<R, double> get fractions;

  /// Wraps a regular [future] and listens to the progress
  /// reported by [updater].
  factory ProgressFuture.wrap(
    Future<R> future,
    ProgressUpdater<N> updater,
  ) =>
      _ProgressFutureImpl(future, updater);

  /// Wraps a regular [future] and only reports its full completion.
  ///
  /// Use this constructor when you don't have the progress information
  /// but still need to expose the interface of this class.
  ///
  /// Any listeners to the returned future will fire before any of the listeners
  /// to the progress. This is because the progress event is itself sent
  /// from a listener. To guarantee that the progress is reported before
  /// the future completion, use [ProgressFuture.wrapDelayedWithoutProgress].
  ///
  /// [total] defaults to 1.
  factory ProgressFuture.wrapWithoutProgress(
    Future<R> future, {
    N? total,
  }) =>
      ProgressFuture._wrapWithoutProgress(
        future,
        total: total ?? one<N>(),
        delay: false,
      );

  /// Wraps a regular [future] and only reports its full completion.
  ///
  /// Use this constructor when you don't have the progress information
  /// but still need to expose the interface of this class.
  ///
  /// A delay of zero is introduced after the completion of the original
  /// [future] so that listeners to the progress fire before the listeners
  /// of the returned future. If you don't need this,
  /// use [ProgressFuture.wrapWithoutProgress] which does not delay.
  ///
  /// [total] defaults to 1.
  factory ProgressFuture.wrapDelayedWithoutProgress(
    Future<R> future, {
    N? total,
  }) =>
      ProgressFuture._wrapWithoutProgress(
        future,
        total: total ?? one<N>(),
        delay: true,
      );

  factory ProgressFuture._wrapWithoutProgress(
    Future<R> future, {
    required N total,
    required bool delay,
  }) {
    final updater = ProgressUpdater<N>(total: total);

    // ignore: discarded_futures
    final wrapped = future.then((r) async {
      updater.setProgress(total);
      if (delay) {
        await Future.delayed(Duration.zero);
      }
      return r;
    });

    return _ProgressFutureImpl(wrapped, updater);
  }

  /// Creates a future that is resolved with [value].
  factory ProgressFuture.value(R value) => _ProgressFutureImpl(
        Future.value(value),
        ProgressUpdater<N>(total: zero<N>()),
      );

  /// Waits until all [futures] complete.
  static ProgressFuture<List<R>, N> wait<R, N extends num>(
    List<ProgressFuture<R, N>> futures,
  ) {
    final total = sumOrNull(futures.map((f) => f.total));
    final updater = ProgressUpdater<N>(total: total);

    for (final future in futures) {
      future.events.listen((event) {
        updater.total = sumOrNull(futures.map((f) => f.total));
        updater.setProgress(
          futures.map((f) => f.progress).reduce((a, b) => (a + b) as N),
        );
      });
    }

    // ignore: discarded_futures
    return _ProgressFutureImpl(Future.wait(futures), updater);
  }

  @override
  ProgressFuture<R2, N> then<R2>(
    FutureOr<R2> Function(R value) onValue, {
    Function? onError,
  });
}

/// A sink for the code wrapped in [ProgressFuture] to report
/// its progress.
class ProgressUpdater<N extends num> {
  final _listeners = <_ProgressListener>[];
  N? _total;

  /// A sink for the code wrapped in [ProgressFuture] to report its progress
  /// as a fraction of [total] which may or may not be defined initially.
  ProgressUpdater({N? total}) : _total = total;

  /// A sink for the code wrapped in [ProgressFuture] to report its progress
  /// as a fraction of one.
  ProgressUpdater.normalized() : _total = one<N>();

  void _addListener(_ProgressListener<N> listener) {
    _listeners.add(listener);
  }

  /// Reports the [progress].
  void setProgress(N progress) {
    for (final listener in _listeners) {
      listener.setProgress(progress);
    }
  }

  /// The total value of which the reported progress is a fraction.
  N? get total => _total;

  set total(N? newValue) {
    _total = newValue;

    for (final listener in _listeners) {
      listener.total = newValue;
    }
  }
}

abstract class _ProgressListener<N extends num> {
  void setProgress(N progress);

  N? get total;

  set total(N? newValue);
}

/// An event produced by changing the progress of [ProgressUpdater]
/// and reported by [ProgressFuture.events].
abstract class ProgressEvent<N extends num> {
  /// When the event has occurred.
  DateTime get dateTime;

  /// The new progress.
  N get progress;
}

class _ProgressEventImpl<N extends num> implements ProgressEvent<N> {
  @override
  final DateTime dateTime;

  @override
  final N progress;

  _ProgressEventImpl(this.progress) : dateTime = clock.now();
}

class _ProgressFutureImpl<R, N extends num> extends DelegatingFuture<R>
    implements ProgressFuture<R, N>, _ProgressListener<N> {
  final StreamController<ProgressEvent<N>> _eventsController;
  N? _total;
  ProgressEvent<N>? _lastEvent;
  final ProgressUpdater<N> _updater;

  @override
  Stream<ProgressEvent<N>> get events => _eventsController.stream;

  factory _ProgressFutureImpl(Future<R> future, ProgressUpdater<N> updater) {
    final eventsController = StreamController<ProgressEvent<N>>.broadcast();
    final result = _ProgressFutureImpl._(future, updater, eventsController);

    // ignore: discarded_futures
    future.whenComplete(() {
      // Sync because of the bug: https://github.com/dart-lang/sdk/issues/56806
      unawaited(eventsController.close());
    }).ignore();
    return result;
  }

  _ProgressFutureImpl._(
    super._future,
    this._updater,
    this._eventsController,
  ) : _total = _updater.total {
    _updater._addListener(this);
  }

  @override
  N get progress => _lastEvent?.progress ?? zero<N>();

  @override
  N? get total => _total;

  @override
  double? get fraction {
    if (_total == null) {
      return null;
    }

    return (_lastEvent?.progress ?? 0) / _total!;
  }

  @override
  ProgressFuture<R, double> get fractions {
    final updater = ProgressUpdater<double>(total: 1);
    events.listen((e) {
      final fraction = this.fraction;
      if (fraction == null) {
        return;
      }
      updater.setProgress(fraction);
    });
    return _ProgressFutureImpl(this, updater);
  }

  @override
  void setProgress(N progress) {
    final event = _ProgressEventImpl(progress);

    _eventsController.add(
      event,
    );
    _lastEvent = event;
  }

  @override
  set total(N? newValue) {
    _total = newValue;
  }

  @override
  ProgressFuture<R2, N> then<R2>(
    FutureOr<R2> Function(R value) onValue, {
    Function? onError,
  }) {
    // ignore: discarded_futures
    final future = super.then(onValue, onError: onError);
    return _ProgressFutureImpl(future, _updater);
  }
}
