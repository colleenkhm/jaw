import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// The dictionary has no entry for the requested word.
class WordNotFoundException implements Exception {
  const WordNotFoundException();
}

/// The dictionary service couldn't be reached or returned a server error.
class DictionaryUnavailableException implements Exception {
  const DictionaryUnavailableException();
}

const _baseUrl = 'https://freedictionaryapi.com/api/v1/entries/en/';
const _timeout = Duration(seconds: 10);
const _maxSynonyms = 12;
const _maxDefinitionsPerPartOfSpeech = 3;

Future<http.Response?> _get(String word) async {
  final uri = Uri.parse('$_baseUrl${Uri.encodeComponent(word)}');
  try {
    return await http.get(uri).timeout(_timeout);
  } on TimeoutException {
    return null;
  } on http.ClientException {
    return null;
  }
}

Future<Map<String, dynamic>> fetchWord(String word) async {
  var response = await _get(word);

  // Retry once on network errors and 5xx responses.
  if (response == null || response.statusCode >= 500) {
    response = await _get(word);
  }

  if (response == null || response.statusCode >= 500) {
    throw const DictionaryUnavailableException();
  }
  if (response.statusCode == 404) throw const WordNotFoundException();
  if (response.statusCode != 200) throw const DictionaryUnavailableException();

  final Map<String, dynamic> data;
  try {
    data = jsonDecode(response.body) as Map<String, dynamic>;
  } on FormatException {
    throw const DictionaryUnavailableException();
  }

  final entries = data['entries'] as List? ?? [];
  final definitions = <Map<String, dynamic>>[];
  final synonyms = <String>{};
  final countByPartOfSpeech = <String, int>{};
  for (final entry in entries) {
    final partOfSpeech = entry['partOfSpeech'] as String? ?? '';
    synonyms.addAll((entry['synonyms'] as List?)?.cast<String>() ?? []);
    final senses = entry['senses'] as List? ?? [];
    for (final sense in senses) {
      final text = sense['definition'] as String?;
      if (text == null || text.isEmpty) continue;
      final count = countByPartOfSpeech[partOfSpeech] ?? 0;
      if (count >= _maxDefinitionsPerPartOfSpeech) break;
      countByPartOfSpeech[partOfSpeech] = count + 1;
      synonyms.addAll((sense['synonyms'] as List?)?.cast<String>() ?? []);
      definitions.add({'partOfSpeech': partOfSpeech, 'definition': text});
    }
  }
  if (definitions.isEmpty) throw const WordNotFoundException();

  return {
    'word': data['word'] as String? ?? word,
    'definitions': definitions,
    'synonyms': synonyms.take(_maxSynonyms).toList(),
  };
}
