import 'package:flutter/material.dart';
import 'app_header.dart';
import 'link_span.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const JawAppBar(),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(25),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'just a word',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 16),
                Text(
                  'search any word to see its definitions, swipe through '
                  'multiple meanings, and tap a synonym chip to look that '
                  'word up next.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                Builder(
                  builder: (context) {
                    final style = Theme.of(context).textTheme.bodyMedium;
                    return Text.rich(
                      TextSpan(
                        style: style,
                        children: [
                          const TextSpan(
                            text: 'definitions and synonyms come from ',
                          ),
                          linkSpan(
                            context,
                            'Wiktionary',
                            'https://en.wiktionary.org',
                            style: style,
                          ),
                          const TextSpan(text: ', via the '),
                          linkSpan(
                            context,
                            'Free Dictionary API',
                            'https://freedictionaryapi.com',
                            style: style,
                          ),
                          const TextSpan(text: '. they are licensed under '),
                          linkSpan(
                            context,
                            'CC BY-SA 4.0',
                            'https://creativecommons.org/licenses/by-sa/4.0/',
                            style: style,
                          ),
                          const TextSpan(
                            text:
                                '. this app shows a shortened selection '
                                'of each entry.',
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
