import 'dart:convert';
import 'package:http/http.dart' as http;

Future<Map<String, String>> fetchWord(String word) async {
  final uri = Uri.parse('https://api.dictionaryapi.dev/api/v2/entries/en/$word');
  final response = await http.get(uri);

  if (response.statusCode != 200) {
    throw Exception('Word not found');
  }

  final data = jsonDecode(response.body) as List;
  if (data.isEmpty) throw Exception('Word not found');

  final entry = data[0] as Map<String, dynamic>;
  final meanings = entry['meanings'] as List? ?? [];
  if (meanings.isEmpty) throw Exception('No meanings found');

  final definitions = meanings[0]['definitions'] as List? ?? [];
  if (definitions.isEmpty) throw Exception('No definitions found');

  return {
    'word': entry['word'] as String,
    'definition': definitions[0]['definition'] as String,
  };
}
