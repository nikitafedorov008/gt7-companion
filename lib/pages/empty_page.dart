import 'package:flutter/material.dart';
import 'package:auto_route/annotations.dart';

@RoutePage()
class EmptyPage extends StatelessWidget {
  final String title;
  const EmptyPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: Center(
        child: Text(title, style: Theme.of(context).textTheme.headlineSmall),
      ),
    );
  }
}

/// Simple typed wrappers so routes can be declared without requiring args.
@RoutePage()
class ScreenA extends StatelessWidget {
  const ScreenA({super.key});

  @override
  Widget build(BuildContext context) => const EmptyPage(title: 'Screen A');
}

@RoutePage()
class ScreenB extends StatelessWidget {
  const ScreenB({super.key});

  @override
  Widget build(BuildContext context) => const EmptyPage(title: 'Screen B');
}
