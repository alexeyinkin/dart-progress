import 'dart:async';

import 'package:async/async.dart';
import 'package:clock/clock.dart';

import 'progress.dart';
import 'util.dart';

/// A [Future] that reports the progress of its completion
/// as an integer and intermediate data.
typedef DataIntProgressFuture<R, D> = DataProgressFuture<R, int, D>;

/// A sink for the code wrapped in [DataIntProgressFuture] to report
/// its progress.
typedef DataIntProgressUpdater<D> = DataProgressUpdater<int, D>;

/// A [Future] that reports the progress of its completion
/// as a double and intermediate data.
typedef DataDoubleProgressFuture<R, D> = DataProgressFuture<R, double, D>;

/// A sink for the code wrapped in [DoubleProgressFuture] to report
/// its progress and intermediate data.
typedef DataDoubleProgressUpdater<D> = DataProgressUpdater<double, D>;

/// A [Future] that reports the progress
/// of its completion and intermediate data.
abstract class DataProgressFuture<R, N extends num, D>
    implements ProgressFuture<R, N> {
  @override
  Stream<DataProgressEvent<N, D>> get events;

  @override
  DataProgressFuture<R, double, D> get fractions;

  /// Wraps a regular [future] and listens to the progress
  /// and intermediate data reported by [updater].
  factory DataProgressFuture.wrap(
    Future<R> future,
    DataProgressUpdater<N, D> updater,
  ) =>
      _DataProgressFutureImpl(future, updater);

  @override
  DataProgressFuture<R2, N, D> then<R2>(
    FutureOr<R2> Function(R value) onValue, {
    Function? onError,
  });
}

/// A sink for the code wrapped in [DataProgressFuture] to report
/// its progress and intermediate data.
class DataProgressUpdater<N extends num, D> {
  final _listeners = <_ProgressListener>[];
  N? _total;

  /// A sink for the code wrapped in [DataProgressFuture] to report its progress
  /// as a fraction of [total] and intermediate data.
  DataProgressUpdater({N? total}) : _total = total;

  /// A sink for the code wrapped in [DataProgressFuture] to report its progress
  /// as a fraction of one and intermediate data.
  DataProgressUpdater.normalized() : _total = one<N>();

  void _addListener(_ProgressListener<N, D> listener) {
    _listeners.add(listener);
  }

  /// Reports the [progress] and intermediate [data].
  void setProgress(N progress, D data) {
    for (final listener in _listeners) {
      listener.setProgress(progress, data);
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

abstract class _ProgressListener<N extends num, D> {
  void setProgress(N progress, D data);

  N? get total;

  set total(N? newValue);
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
  final StreamController<DataProgressEvent<N, D>> _eventsController;
  N? _total;
  DataProgressEvent<N, D>? _lastEvent;
  final DataProgressUpdater<N, D> _updater;

  @override
  Stream<DataProgressEvent<N, D>> get events => _eventsController.stream;

  factory _DataProgressFutureImpl(
    Future<R> future,
    DataProgressUpdater<N, D> updater,
  ) {
    final eventsController =
        StreamController<DataProgressEvent<N, D>>.broadcast();
    final result = _DataProgressFutureImpl._(future, updater, eventsController);

    // ignore: discarded_futures
    future.whenComplete(() {
      // Sync because of the bug: https://github.com/dart-lang/sdk/issues/56806
      unawaited(eventsController.close());
    }).ignore();
    return result;
  }

  _DataProgressFutureImpl._(
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

  @override
  set total(N? newValue) {
    _total = newValue;
  }

  @override
  DataProgressFuture<R2, N, D> then<R2>(
    FutureOr<R2> Function(R value) onValue, {
    Function? onError,
  }) {
    // ignore: discarded_futures
    final future = super.then(onValue, onError: onError);
    return DataProgressFuture<R2, N, D>.wrap(future, _updater);
  }
}
