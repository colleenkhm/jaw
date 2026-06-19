import 'package:flutter/gestures.dart';
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
  List<Map<String, String>>? _definitions;
  String? _error;
  bool _loading = false;
  int _currentPage = 0;

  @override
  void dispose() {
    _controller.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Widget _buildCarousel() {
    final pageView = SizedBox(
      height: 160,
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
            return SingleChildScrollView(
              child: Column(
                children: [
                  if (def['partOfSpeech']!.isNotEmpty)
                    Text(
                      def['partOfSpeech']!,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(def['definition']!, textAlign: TextAlign.center),
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
        _definitions = entry['definitions'] as List<Map<String, String>>;
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
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
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
                if (_word != null && !_loading && _definitions != null) ...[
                  const SizedBox(height: 24),
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
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
