import 'package:flutter/material.dart';
import 'package:url_launcher/link.dart';

/// An inline hyperlink for use inside [Text.rich]. Renders a real anchor on
/// web, so it supports middle-click and "open in new tab".
WidgetSpan linkSpan(
  BuildContext context,
  String text,
  String url, {
  TextStyle? style,
}) {
  final base = style ?? DefaultTextStyle.of(context).style;
  return WidgetSpan(
    alignment: PlaceholderAlignment.baseline,
    baseline: TextBaseline.alphabetic,
    child: Link(
      uri: Uri.parse(url),
      target: LinkTarget.blank,
      builder: (context, followLink) => MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: followLink,
          child: Text(
            text,
            style: base.copyWith(
              color: Theme.of(context).colorScheme.primary,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ),
    ),
  );
}
