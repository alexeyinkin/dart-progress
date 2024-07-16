import 'package:print_buffer/print_buffer.dart';
import 'package:progress/printers.dart';
import 'package:test/test.dart';

import '../common.dart';

const _delay = Duration(milliseconds: 1);

void main() {
  group('CharacterProgressPrinter', () {
    test('all dots by default', () async {
      const count = 3;
      final buffered = <String>[];
      final buffer = PrintBuffer();

      await buffer.overrideStdout(() async {
        final future = runIntsWithProgressAndData(count: count, delay: _delay);
        CharacterProgressPrinter(future);

        future.events.listen((e) {
          buffered.add(buffer.buffer.toString());
        });

        await future;
      });

      await Future.delayed(Duration.zero); // Let it print \n
      buffered.add(buffer.buffer.toString());

      expect(
        buffered,
        [
          '.',
          '..',
          '...',
          '...\n',
        ],
      );
    });

    test('override a character', () async {
      const count = 3;
      final buffered = <String>[];
      final buffer = PrintBuffer();

      await buffer.overrideStdout(() async {
        final future = runIntsWithProgressAndData(count: count, delay: _delay);
        CharacterProgressPrinter(
          future,
          eventToString: (event) => event.progress == 2 ? 'two' : null,
          newline: false,
        );

        future.events.listen((e) {
          buffered.add(buffer.buffer.toString());
        });

        await future;
      });

      await Future.delayed(Duration.zero); // Make sure no \n added
      buffered.add(buffer.buffer.toString());

      expect(
        buffered,
        [
          '.',
          '.two',
          '.two.',
          '.two.',
        ],
      );
    });
  });
}
