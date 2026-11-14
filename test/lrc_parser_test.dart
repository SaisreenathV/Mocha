import 'package:flutter_test/flutter_test.dart';
import 'package:mocha/domain/lrc_parser.dart';

void main() {
  group('LrcParser', () {
    test('parses metadata tags correctly', () {
      const lrcContent = '''
[ti:Espresso Flow]
[ar:Coffee Beats]
[al:Mocha Sessions]
[offset:250]
[00:01.00]First line
''';

      final doc = LrcParser.parse(lrcContent);
      expect(doc.title, 'Espresso Flow');
      expect(doc.artist, 'Coffee Beats');
      expect(doc.album, 'Mocha Sessions');
      expect(doc.offsetMs, 250);
      expect(doc.lines.length, 1);
      // 1000ms + 250ms offset = 1250ms
      expect(doc.lines.first.timestamp, const Duration(milliseconds: 1250));
      expect(doc.lines.first.text, 'First line');
    });

    test('parses 2-digit and 3-digit fractions', () {
      const lrcContent = '''
[00:05.50]Two digit fraction
[00:10.125]Three digit fraction
''';

      final doc = LrcParser.parse(lrcContent);
      expect(doc.lines.length, 2);
      expect(doc.lines[0].timestamp, const Duration(milliseconds: 5500));
      expect(doc.lines[1].timestamp, const Duration(milliseconds: 10125));
    });

    test('parses multi-timestamp lines and sorts chronologically', () {
      const lrcContent = '''
[00:20.00][00:05.00]Repeated hook
[00:12.00]Interlude
''';

      final doc = LrcParser.parse(lrcContent);
      expect(doc.lines.length, 3);
      expect(doc.lines[0].timestamp, const Duration(milliseconds: 5000));
      expect(doc.lines[0].text, 'Repeated hook');
      expect(doc.lines[1].timestamp, const Duration(milliseconds: 12000));
      expect(doc.lines[1].text, 'Interlude');
      expect(doc.lines[2].timestamp, const Duration(milliseconds: 20000));
      expect(doc.lines[2].text, 'Repeated hook');
    });

    test('getActiveIndex returns correct line index by playback position', () {
      const lrcContent = '''
[00:05.00]Line 1
[00:10.00]Line 2
[00:20.00]Line 3
''';

      final doc = LrcParser.parse(lrcContent);

      // Before first line
      expect(doc.getActiveIndex(const Duration(seconds: 2)), -1);

      // Exactly at first line
      expect(doc.getActiveIndex(const Duration(seconds: 5)), 0);

      // Between line 1 and line 2
      expect(doc.getActiveIndex(const Duration(seconds: 7)), 0);

      // Exactly at line 2
      expect(doc.getActiveIndex(const Duration(seconds: 10)), 1);

      // Between line 2 and line 3
      expect(doc.getActiveIndex(const Duration(seconds: 18)), 1);

      // After last line
      expect(doc.getActiveIndex(const Duration(seconds: 45)), 2);
    });
  });
}
