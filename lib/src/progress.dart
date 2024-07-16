import 'dart:async';

import 'package:async/async.dart';
import 'package:clock/clock.dart';

/// A [Future] that reports the progress of its completion as an integer.
typedef IntProgressFuture<R> = ProgressFuture<R, int>;

/// A sink for the code wrapped in [IntProgressFuture] to report
/// its progress.
typedef IntProgressUpdater = ProgressUpdater<int>;

/// A [Future] that reports the progress of its completion as a double.
typedef DoubleProgressFuture<R> = ProgressFuture<R, double>;

/// A sink for the code wrapped in [DoubleProgressFuture] to report
/// its progress.
typedef DoubleProgressUpdater = ProgressUpdater<double>;

/// A [Future] that reports the progress of its completion.
abstract class ProgressFuture<R, N extends num> implements Future<R> {
  /// The progress events.
  Stream<ProgressEvent<N>> get events;

  /// Returns the progress as of the last fired event as a fraction of 1.
  double? get fraction;

  /// Creates the version of this future with the progress reported
  /// as fractions of 1.
  ProgressFuture<R, double> get fractions;

  /// Wraps a regular [future] and listen to the progress reported by [updater].
  factory ProgressFuture.wrap(
    Future<R> future,
    ProgressUpdater<N> updater,
  ) =>
      _ProgressFutureImpl(future, updater);
}

/// A sink for the code wrapped in [ProgressFuture] to report its progress.
class ProgressUpdater<N extends num> {
  final _listeners = <_ProgressListener>[];
  N? _total;

  ProgressUpdater({N? total}) : _total = total;

  void _addListener(_ProgressListener<N> listener) {
    _listeners.add(listener);
  }

  /// Reports the [progress].
  void setProgress(N progress) {
    for (final listener in _listeners) {
      listener.setProgress(progress);
    }
  }

  /// Sets the total value of which the reported progress is a fraction.
  set total(N newValue) {
    _total = newValue;

    for (final listener in _listeners) {
      listener.total = newValue;
    }
  }
}

abstract class _ProgressListener<N extends num> {
  void setProgress(N progress);

  set total(N newValue);
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
  final _eventsController = StreamController<ProgressEvent<N>>.broadcast();
  N? _total;
  ProgressEvent<N>? _lastEvent;
  final ProgressUpdater<N> _updater;

  Stream<ProgressEvent<N>> get events => _eventsController.stream;

  _ProgressFutureImpl(Future<R> future, this._updater)
      : _total = _updater._total,
        super(future) {
    _updater._addListener(this);
    future.whenComplete(_eventsController.close);
  }

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
    return ProgressFuture.wrap(this, updater);
  }

  @override
  void setProgress(N progress) {
    final event = _ProgressEventImpl(progress);

    _eventsController.add(
      event,
    );
    _lastEvent = event;
  }

  set total(N newValue) {
    _total = newValue;
  }
}
