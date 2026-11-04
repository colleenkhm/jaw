import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'about_page.dart';
import 'app_header.dart';
import 'link_span.dart';
import 'utils/etymology_utils.dart';
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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        scaffoldBackgroundColor: Colors.lightBlue[50],
        appBarTheme: AppBarTheme(backgroundColor: Colors.lightBlue[50]),
      ),
      home: const HomePage(),
      routes: {'/about': (context) => const AboutPage()},
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
  List<Etymology>? _etymologies;
  int _lookupId = 0;
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

  Widget _buildCarousel() {
    final pageView = SizedBox(
      height: 140,
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(
          dragDevices: {
            PointerDeviceKind.touch,
            PointerDeviceKind.mouse,
            PointerDeviceKind.trackpad,
            PointerDeviceKind.stylus,
          },
        ),
        child: PageView.builder(
          controller: _pageController,
          itemCount: _definitions!.length,
          onPageChanged: (index) => setState(() => _currentPage = index),
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
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
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
    );

    if (_definitions!.length <= 1) return pageView;

    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: _currentPage > 0
              ? () => _pageController.previousPage(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                )
              : null,
        ),
        Expanded(child: pageView),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: _currentPage < _definitions!.length - 1
              ? () => _pageController.nextPage(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                )
              : null,
        ),
      ],
    );
  }

  /// Loaded after the definitions so the extra request doesn't delay them.
  Future<void> _loadEtymologies(String word, int lookupId) async {
    final etymologies = await fetchEtymologies(word);
    // Ignore the result if the user has looked up another word since.
    if (!mounted || lookupId != _lookupId) return;
    setState(() => _etymologies = etymologies);
  }

  /// A labelled list of one part (origin or cognates) of each etymology.
  /// When a word has several origins, entries keep the origin's number so
  /// cognates line up with the origin they belong to.
  Widget _buildEtymologySection(String label, String Function(Etymology) part) {
    final theme = Theme.of(context);
    final numbered = _etymologies!.length > 1;
    final entries = [
      for (final (i, etymology) in _etymologies!.indexed)
        if (part(etymology).isNotEmpty)
          numbered ? '${i + 1}. ${part(etymology)}' : part(etymology),
    ];
    if (entries.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              fontStyle: FontStyle.italic,
              color: Colors.grey,
            ),
          ),
          for (final entry in entries) ...[
            const SizedBox(height: 6),
            Text(
              entry,
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAttribution() {
    final style = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600);
    final wordUrl =
        'https://en.wiktionary.org/wiki/${Uri.encodeComponent(_word!)}';
    return Text.rich(
      TextSpan(
        style: style,
        children: [
          const TextSpan(text: 'from '),
          linkSpan(context, 'Wiktionary', wordUrl, style: style),
          const TextSpan(text: ' · '),
          linkSpan(
            context,
            'CC BY-SA 4.0',
            'https://creativecommons.org/licenses/by-sa/4.0/',
            style: style,
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }

  Future<void> _getWord() async {
    final input = _controller.text.trim();
    if (input.isEmpty) return;

    final lookupId = ++_lookupId;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final entry = await fetchWord(input);
      final word = entry['word'] as String;
      setState(() {
        _word = word;
        _definitions = entry['definitions'] as List<Map<String, dynamic>>;
        _synonyms = entry['synonyms'] as List<String>;
        _etymologies = null;
        _currentPage = 0;
      });
      if (_pageController.hasClients) _pageController.jumpToPage(0);
      _loadEtymologies(word, lookupId);
    } on WordNotFoundException {
      setState(() => _error = 'Word not found. Try another one.');
    } on DictionaryUnavailableException {
      setState(
        () => _error = 'Dictionary service unavailable. Try again in a moment.',
      );
    } catch (_) {
      setState(() => _error = 'Something went wrong. Try again.');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const JawAppBar(),
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
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
                    _buildCarousel(),
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
                    if (_etymologies != null) ...[
                      _buildEtymologySection('origin', (e) => e.origin),
                      _buildEtymologySection('cognates', (e) => e.cognates),
                    ],
                    const SizedBox(height: 16),
                    _buildAttribution(),
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
          ),
        ),
      ),
    );
  }
}
