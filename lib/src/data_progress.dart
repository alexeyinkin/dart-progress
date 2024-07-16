import 'dart:async';

import 'package:async/async.dart';
import 'package:clock/clock.dart';

import 'progress.dart';

/// A [Future] that reports the progress of its completion as an integer
/// and intermediate data.
typedef DataIntProgressFuture<R, D> = DataProgressFuture<R, int, D>;

/// A sink for the code wrapped in [DataIntProgressFuture] to report
/// its progress.
typedef DataIntProgressUpdater<D> = DataProgressUpdater<int, D>;

/// A [Future] that reports the progress of its completion as a double
/// and intermediate data.
typedef DataDoubleProgressFuture<R, D> = DataProgressFuture<R, double, D>;

/// A sink for the code wrapped in [DoubleProgressFuture] to report
/// its progress and intermediate data.
typedef DataDoubleProgressUpdater<D> = DataProgressUpdater<double, D>;

/// A [Future] that reports the progress of its completion
/// and intermediate data.
abstract class DataProgressFuture<R, N extends num, D>
    implements ProgressFuture<R, N> {
  @override
  Stream<DataProgressEvent<N, D>> get events;

  @override
  DataProgressFuture<R, double, D> get fractions;

  /// Wraps a regular [future] and listen to the progress and intermediate data
  /// reported by [updater].
  factory DataProgressFuture.wrap(
    Future<R> future,
    DataProgressUpdater<N, D> updater,
  ) =>
      _DataProgressFutureImpl(future, updater);
}

/// A sink for the code wrapped in [DataProgressFuture] to report its progress
/// and intermediate data.
class DataProgressUpdater<N extends num, D> {
  final _listeners = <_ProgressListener>[];
  N? _total;

  DataProgressUpdater({N? total}) : _total = total;

  void _addListener(_ProgressListener<N, D> listener) {
    _listeners.add(listener);
  }

  /// Reports the [progress] and intermediate [data].
  void setProgress(N progress, D data) {
    for (final listener in _listeners) {
      listener.setProgress(progress, data);
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

abstract class _ProgressListener<N extends num, D> {
  void setProgress(N progress, D data);

  set total(N newValue);
}

/// An event produced by changing the progress of [DataProgressUpdater]
/// and reported by [DataProgressFuture.events].
abstract class DataProgressEvent<N extends num, D> extends ProgressEvent<N> {
  /// The intermediate data reported with this event.
  D get data;
}

class _DataProgressEventImpl<N extends num, D>
    implements DataProgressEvent<N, D> {
  @override
  final D data;

  @override
  final DateTime dateTime;

  @override
  final N progress;

  _DataProgressEventImpl(this.progress, this.data) : dateTime = clock.now();
}

class _DataProgressFutureImpl<R, N extends num, D> extends DelegatingFuture<R>
    implements DataProgressFuture<R, N, D>, _ProgressListener<N, D> {
  final _eventsController =
      StreamController<DataProgressEvent<N, D>>.broadcast();
  N? _total;
  DataProgressEvent<N, D>? _lastEvent;
  final DataProgressUpdater<N, D> _updater;

  Stream<DataProgressEvent<N, D>> get events => _eventsController.stream;

  _DataProgressFutureImpl(Future<R> future, this._updater)
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
  DataProgressFuture<R, double, D> get fractions {
    final updater = DataProgressUpdater<double, D>(total: 1);
    events.listen((e) {
      final fraction = this.fraction;
      if (fraction == null) {
        return;
      }
      updater.setProgress(fraction, e.data);
    });
    return DataProgressFuture.wrap(this, updater);
  }

  @override
  void setProgress(N progress, D data) {
    final event = _DataProgressEventImpl(progress, data);

    _eventsController.add(
      event,
    );
    _lastEvent = event;
  }

  set total(N newValue) {
    _total = newValue;
  }
}
