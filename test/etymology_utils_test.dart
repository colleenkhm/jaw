import 'package:flutter_test/flutter_test.dart';
import 'package:jaw/utils/etymology_utils.dart';

void main() {
  group('parseEtymologies', () {
    test('reads a single English etymology, splitting out cognates', () {
      const extract = '''
== English ==


=== Alternative forms ===
rin, ren (dialectal)


=== Etymology ===
From Middle English runnen, rennen (“to run”), alteration (due to the past participle runne, runnen,
yronne) of Middle English rinnen (“to run”).
Cognate with Scots rin (“to run”).


=== Pronunciation ===
IPA(key): /ɹʌn/
''';
      expect(parseEtymologies(extract), [
        const Etymology(
          origin:
              'From Middle English runnen, rennen (“to run”), alteration (due '
              'to the past participle runne, runnen, yronne) of Middle '
              'English rinnen (“to run”).',
          cognates: 'Cognate with Scots rin (“to run”).',
        ),
      ]);
    });

    test('reads each numbered etymology in order', () {
      const extract = '''
== English ==

=== Etymology 1 ===
From Old Norse bakki.

==== Noun ====
bank

=== Etymology 2 ===
From Italian banca.

==== Noun ====
bank
''';
      expect(parseEtymologies(extract), [
        const Etymology(origin: 'From Old Norse bakki.'),
        const Etymology(origin: 'From Italian banca.'),
      ]);
    });

    test('ignores other languages', () {
      const extract = '''
== German ==

=== Etymology ===
From English run.

== English ==

=== Etymology ===
From Middle English runnen.

== Dutch ==

=== Etymology ===
Borrowed from English.
''';
      expect(parseEtymologies(extract), [
        const Etymology(origin: 'From Middle English runnen.'),
      ]);
    });

    test('returns nothing without an English section', () {
      const extract = '''
== German ==

=== Etymology ===
From English run.
''';
      expect(parseEtymologies(extract), isEmpty);
    });

    test('splits cognates that start mid-paragraph', () {
      const extract = '''
== English ==

=== Etymology ===
From Old English ǣt (“food”). Cognate with West Frisian iten (“food”), German Aas (“carrion”).
''';
      expect(parseEtymologies(extract), [
        const Etymology(
          origin: 'From Old English ǣt (“food”).',
          cognates:
              'Cognate with West Frisian iten (“food”), German Aas (“carrion”).',
        ),
      ]);
    });

    test('treats "Akin to" and "… cognates include" as cognates', () {
      const extract = '''
== English ==

=== Etymology 1 ===
From Old French banc (“bench”). Akin to Old English benċ (“bench”).

=== Etymology 2 ===
From Proto-Germanic *rinnaną.
Non-Germanic cognates include Albanian rend (“to run”).
''';
      expect(parseEtymologies(extract), [
        const Etymology(
          origin: 'From Old French banc (“bench”).',
          cognates: 'Akin to Old English benċ (“bench”).',
        ),
        const Etymology(
          origin: 'From Proto-Germanic *rinnaną.',
          cognates: 'Non-Germanic cognates include Albanian rend (“to run”).',
        ),
      ]);
    });

    test('keeps doublets and comparisons in the origin', () {
      const extract = '''
== English ==

=== Etymology ===
From Old English heorte. Doublet of cardia. Compare Dutch hart.
''';
      expect(parseEtymologies(extract), [
        const Etymology(
          origin:
              'From Old English heorte. Doublet of cardia. Compare Dutch hart.',
        ),
      ]);
    });

    test('drops notices aimed at Wiktionary editors', () {
      const extract = '''
== English ==

=== Etymology 1 ===
From Old English settan.

=== Etymology 2 ===
(This etymology is missing or incomplete. Please add to it, or discuss it at the Etymology scriptorium.)

=== Noun ===
set
''';
      expect(parseEtymologies(extract), [
        const Etymology(origin: 'From Old English settan.'),
      ]);
    });

    test('skips empty etymology sections', () {
      const extract = '''
== English ==

=== Etymology ===

=== Noun ===
word
''';
      expect(parseEtymologies(extract), isEmpty);
    });
  });
}
