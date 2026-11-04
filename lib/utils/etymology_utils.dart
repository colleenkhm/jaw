import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

const _apiUrl = 'https://en.wiktionary.org/w/api.php';
const _timeout = Duration(seconds: 10);

// Wikimedia's API policy asks clients to identify themselves. Browsers don't
// allow setting User-Agent, so Api-User-Agent is the supported alternative.
const _userAgent = 'just-a-word (https://just-a-word.com)';

final _englishHeading = RegExp(r'^== English ==\s*$', multiLine: true);
final _languageHeading = RegExp(r'^== [^=].* ==\s*$', multiLine: true);
final _anyHeading = RegExp(r'^=+ .* =+\s*$', multiLine: true);
final _etymologyHeading = RegExp(
  r'^={3,4} Etymology(?: \d+)? ={3,4}\s*$',
  multiLine: true,
);

/// One origin of a word, with its cognates (related words in other
/// languages) split out. Either part may be empty, but not both.
class Etymology {
  const Etymology({required this.origin, this.cognates = ''});

  final String origin;
  final String cognates;

  @override
  bool operator ==(Object other) =>
      other is Etymology &&
      other.origin == origin &&
      other.cognates == cognates;

  @override
  int get hashCode => Object.hash(origin, cognates);

  @override
  String toString() => 'Etymology(origin: $origin, cognates: $cognates)';
}

/// Fetches the English etymologies for [word] from Wiktionary.
///
/// Returns one entry per "Etymology" section (words like "bank" have several
/// unrelated origins). Etymology is supplementary, so any failure returns an
/// empty list instead of throwing.
Future<List<Etymology>> fetchEtymologies(String word) async {
  final uri = Uri.parse(_apiUrl).replace(
    queryParameters: {
      'action': 'query',
      'prop': 'extracts',
      'explaintext': '1',
      'exsectionformat': 'wiki',
      'titles': word,
      'format': 'json',
      'formatversion': '2',
      'origin': '*',
    },
  );
  try {
    final response = await http
        .get(uri, headers: {'Api-User-Agent': _userAgent})
        .timeout(_timeout);
    if (response.statusCode != 200) return [];
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final pages = data['query']?['pages'] as List? ?? [];
    if (pages.isEmpty) return [];
    final extract = pages.first['extract'] as String?;
    if (extract == null) return [];
    return parseEtymologies(extract);
  } catch (_) {
    return [];
  }
}

/// Pulls the etymology text out of a Wiktionary plain-text page extract.
///
/// Only the English section is used. Paragraphs within an origin or cognates
/// text are separated by '\n'.
List<Etymology> parseEtymologies(String extract) {
  final englishStart = _englishHeading.firstMatch(extract);
  if (englishStart == null) return [];

  var english = extract.substring(englishStart.end);
  final nextLanguage = _languageHeading.firstMatch(english);
  if (nextLanguage != null) english = english.substring(0, nextLanguage.start);

  final etymologies = <Etymology>[];
  for (final heading in _etymologyHeading.allMatches(english)) {
    var body = english.substring(heading.end);
    final nextHeading = _anyHeading.firstMatch(body);
    if (nextHeading != null) body = body.substring(0, nextHeading.start);

    final etymology = _splitCognates(_joinParagraphs(body));
    if (etymology.origin.isNotEmpty || etymology.cognates.isNotEmpty) {
      etymologies.add(etymology);
    }
  }
  return etymologies;
}

// A sentence introducing cognates, at the start of a paragraph or sentence:
// "Cognate with…", "Cognates include…", "Akin to…", "Non-Germanic cognates
// include…". "Doublet of…" isn't matched: doublets are English words.
final _cognatesStart = RegExp(
  r'(?:^|(?<=[.;] ))(?:Cognate with|Cognates|Akin to|[A-Z][\w-]* cognates)\b',
);

/// Moves each paragraph's cognates, from the sentence that introduces them to
/// the end of the paragraph, out of the origin.
Etymology _splitCognates(List<String> paragraphs) {
  final origin = <String>[];
  final cognates = <String>[];
  for (final paragraph in paragraphs) {
    final start = _cognatesStart.firstMatch(paragraph)?.start;
    if (start == null) {
      origin.add(paragraph);
      continue;
    }
    final before = paragraph.substring(0, start).trim();
    if (before.isNotEmpty) origin.add(before);
    cognates.add(paragraph.substring(start).trim());
  }
  return Etymology(origin: origin.join('\n'), cognates: cognates.join('\n'));
}

final _sentenceEnd = RegExp(r'[.!?:;)”"]$');

/// Extracts sometimes break lines mid-sentence, so a line is only treated as
/// the end of a paragraph when it ends like a sentence.
List<String> _joinParagraphs(String body) {
  final paragraphs = <String>[];
  var current = '';
  for (final raw in body.split('\n')) {
    final line = raw.trim();
    if (line.isEmpty) continue;
    current = current.isEmpty ? line : '$current $line';
    if (_sentenceEnd.hasMatch(line)) {
      paragraphs.add(current);
      current = '';
    }
  }
  if (current.isNotEmpty) paragraphs.add(current);
  return paragraphs.where((p) => !_isEditorNotice(p)).toList();
}

/// Wiktionary marks incomplete etymologies with requests aimed at editors,
/// e.g. "(This etymology is missing or incomplete. Please add to it, …)".
bool _isEditorNotice(String paragraph) =>
    paragraph.startsWith('(') &&
    (paragraph.contains('Please add to it') ||
        paragraph.contains('Etymology scriptorium'));
