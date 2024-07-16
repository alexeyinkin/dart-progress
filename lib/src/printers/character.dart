import 'dart:io';

import '../progress.dart';

/// Prints a character or string for each event. A dot is the default.
class CharacterProgressPrinter<N extends num> {
  /// The future to track progress.
  final ProgressFuture<Object?, N> future;

  /// The callback to produce a character or a string instead of the default dot
  /// for [event].
  final String? Function(ProgressEvent<N> event)? eventToString;

  /// Whether to add a newline character when the future completes.
  final bool newline;

  CharacterProgressPrinter(
    this.future, {
    this.eventToString,
    this.newline = true,
  }) {
    if (newline) {
      future.then((_) => stdout.writeln());
    }

    future.events.listen(_onEvent);
  }

  void _onEvent(ProgressEvent<N> event) {
    stdout.write(_getCharacter(event));
  }

  String _getCharacter(ProgressEvent<N> event) {
    return eventToString?.call(event) ?? '.';
  }
}
