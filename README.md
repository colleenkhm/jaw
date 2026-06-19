# just a word

A Flutter app for looking up word definitions and synonyms. Enter any word and browse all of its definitions and synonyms, pulled live from the free [Dictionary API](https://dictionaryapi.dev).

Live at [just-a-word.com](https://just-a-word.com).

## Features

- Look up a word by typing it and tapping "look it up" (or pressing enter)
- Browse every definition for a word in a swipeable carousel — swipe, drag, or use the arrow buttons
- See all synonyms for the word as chips; click a synonym chip to search for that word instead
- Responsive layout that works on both mobile and desktop/web

## Getting started

**Prerequisites:** Flutter SDK installed ([flutter.dev](https://flutter.dev/docs/get-started/install))

```bash
flutter pub get
flutter run
```

To run as a website locally:

```bash
flutter run -d chrome
```

## Deployment

Pushes to `main` are automatically built and deployed to GitHub Pages via [`.github/workflows/deploy.yml`](.github/workflows/deploy.yml).

## Tech

- Flutter / Dart
- [dictionaryapi.dev](https://dictionaryapi.dev) — free, no API key required
