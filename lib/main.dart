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
      theme: ThemeData(useMaterial3: true, primarySwatch: Colors.blue),
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
  final _pageController = PageController();
  String? _word;
  List<Map<String, dynamic>>? _definitions;
  List<String>? _synonyms;
  String? _error;
  bool _loading = false;
  int _currentPage = 0;

  @override
  void dispose() {
    _controller.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _searchFor(String term) async {
    _controller.text = term;
    await _getWord();
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
        _word = entry['word'] as String;
        _definitions = entry['definitions'] as List<Map<String, dynamic>>;
        _synonyms = entry['synonyms'] as List<String>;
        _currentPage = 0;
      });
      if (_pageController.hasClients) _pageController.jumpToPage(0);
    } catch (_) {
      setState(() => _error = 'Word not found. Try another one.');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(centerTitle: true, title: const Text('just a word')),
      body: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (_word != null && !_loading && _definitions != null) ...[
              Text(
                _word!,
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 140,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _definitions!.length,
                  onPageChanged: (index) =>
                      setState(() => _currentPage = index),
                  itemBuilder: (context, index) {
                    final def = _definitions![index];
                    final partOfSpeech = def['partOfSpeech'] as String;
                    final definitionText = def['definition'] as String;
                    return SingleChildScrollView(
                      child: Column(
                        children: [
                          if (partOfSpeech.isNotEmpty)
                            Text(
                              partOfSpeech,
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(
                                    fontStyle: FontStyle.italic,
                                    color: Colors.grey,
                                  ),
                            ),
                          const SizedBox(height: 4),
                          Text(definitionText, textAlign: TextAlign.center),
                        ],
                      ),
                    );
                  },
                ),
              ),
              if (_definitions!.length > 1) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_definitions!.length, (index) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: index == _currentPage
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey.shade300,
                      ),
                    );
                  }),
                ),
              ],
              if (_synonyms != null && _synonyms!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: _synonyms!
                      .map(
                        (s) => ActionChip(
                          label: Text(s),
                          onPressed: () => _searchFor(s),
                        ),
                      )
                      .toList(),
                ),
              ],
              const SizedBox(height: 24),
            ],
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
          ],
        ),
      ),
    );
  }
}
