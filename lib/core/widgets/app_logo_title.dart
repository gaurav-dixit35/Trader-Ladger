import 'package:flutter/material.dart';

class AppLogoTitle extends StatelessWidget {
  const AppLogoTitle({
    this.title = 'Trader Ledger App',
    super.key,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 150;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'others/logo.png',
              width: 30,
              height: 30,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.storefront_outlined);
              },
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                compact ? 'Ledger' : title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
      },
    );
  }
}
