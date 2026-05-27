import 'package:flutter/material.dart';
import 'utils/word_utils.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'just a word',
      theme: ThemeData(
        useMaterial3: true,
        primarySwatch: Colors.blue,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _controller = TextEditingController();
  String? _word;
  String? _definition;
  String? _error;
  bool _loading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _getWord() async {
    final input = _controller.text.trim();
    if (input.isEmpty) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final entry = await fetchWord(input);
      setState(() {
        _word = entry['word'];
        _definition = entry['definition'];
      });
    } catch (_) {
      setState(() => _error = 'Word not found. Try another one.');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('just a word'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: 'enter a word',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _getWord(),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loading ? null : _getWord,
              child: const Text('look it up'),
            ),
            if (_loading) ...[
              const SizedBox(height: 24),
              const CircularProgressIndicator(),
            ],
            if (_error != null) ...[
              const SizedBox(height: 24),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            if (_word != null && !_loading) ...[
              const SizedBox(height: 24),
              Text(
                _word!,
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              if (_definition != null) ...[
                const SizedBox(height: 12),
                Text(_definition!, textAlign: TextAlign.center),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
