import 'package:flutter/material.dart';

class JawAppBar extends StatelessWidget implements PreferredSizeWidget {
  const JawAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      centerTitle: false,
      automaticallyImplyLeading: false,
      title: GestureDetector(
        onTap: () => Navigator.popUntil(context, (route) => route.isFirst),
        child: const Text('just a word'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pushNamed(context, '/about'),
          child: const Text('about'),
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}
