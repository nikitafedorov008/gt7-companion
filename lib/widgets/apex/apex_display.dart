import 'package:gt7_companion/widgets/window_navigation_safe_area.dart';
import 'package:gt7_companion/l10n/ui_messages.dart';
// START_MODULE_CONTRACT
// PURPOSE: Read Beyond the Apex inside the application at any window width.
// SCOPE: Chapter navigation, article rendering and loading/error presentation.
// DEPENDS: M-SERVICE-APEX, M-MODEL-APEX
// LINKS: M-WIDGET-APEX, V-M-WIDGET-APEX
// END_MODULE_CONTRACT
// START_MODULE_MAP
// ApexDisplay - adaptive magazine reader with contents sidebar or drawer.
// END_MODULE_MAP
import 'dart:async';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/apex/apex_content.dart';
import '../../services/apex_service.dart';

@RoutePage()
class ApexDisplay extends StatefulWidget {
  const ApexDisplay({super.key});
  @override
  State<ApexDisplay> createState() => _ApexDisplayState();
}

class _ApexDisplayState extends State<ApexDisplay> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.microtask(() {
      if (mounted) unawaited(context.read<ApexService>().load());
    });
  }

  @override
  void didChangeLocales(List<Locale>? locales) {
    if (locales != null) {
      unawaited(context.read<ApexService>().updateSystemLocales(locales));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Consumer<ApexService>(
    builder: (context, service, _) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 880;
          return Scaffold(
            appBar: WindowNavigationAppBar(
              child: AppBar(
                leading: BackButton(onPressed: () => context.router.maybePop()),
                title: Text(
                  context.tr('Beyond the Apex'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                actions: [
                  if (!wide)
                    Builder(
                      builder: (context) => IconButton(
                        key: const ValueKey('apex-contents-button'),
                        tooltip: context.tr(
                          service.label('Содержание', 'Contents'),
                        ),
                        icon: const Icon(Icons.menu_book_outlined),
                        onPressed: () => Scaffold.of(context).openEndDrawer(),
                      ),
                    ),
                  IconButton(
                    tooltip: context.tr(
                      service.label('Открыть оригинал', 'Open original'),
                    ),
                    icon: const Icon(Icons.open_in_new),
                    onPressed: () => _openOriginal(context, service),
                  ),
                ],
              ),
            ),
            endDrawer: wide
                ? null
                : Drawer(
                    child: SafeArea(
                      child: _ApexContents(
                        service: service,
                        onSelect: (reference) {
                          Navigator.of(context).pop();
                          unawaited(service.selectArticle(reference));
                        },
                      ),
                    ),
                  ),
            body: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (wide) ...[
                  SizedBox(
                    width: 280,
                    child: _ApexContents(
                      service: service,
                      onSelect: (reference) =>
                          unawaited(service.selectArticle(reference)),
                    ),
                  ),
                  const VerticalDivider(width: 1),
                ],
                Expanded(
                  child: service.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : service.error != null
                      ? _ReaderError(service: service)
                      : service.article == null
                      ? const SizedBox.shrink()
                      : _ArticleView(
                          key: ValueKey(service.selected.path),
                          service: service,
                        ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

Future<void> _openOriginal(BuildContext context, ApexService service) async {
  final reference = service.selected;
  final url = reference.path == '/top'
      ? service.sourceUrl
      : service.sourceUrl.resolve('.${reference.path}');
  try {
    if (await launchUrl(url)) return;
  } catch (_) {
    /* Show the same recoverable message for an unavailable handler. */
  }
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          context.tr(
            service.label(
              'Не удалось открыть сайт. Попробуйте ещё раз.',
              'Could not open the website. Please retry.',
            ),
          ),
        ),
      ),
    );
  }
}

class _ApexContents extends StatelessWidget {
  const _ApexContents({required this.service, required this.onSelect});
  final ApexService service;
  final ValueChanged<ApexArticleRef> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 20, 12, 112),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
          child: Text(
            context.tr(service.label('Содержание', 'Contents')),
            style: theme.textTheme.titleLarge,
          ),
        ),
        TextButton(
          onPressed: () => onSelect(ApexArticleRef.introduction),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(context.tr('The Gran Turismo Magazine')),
          ),
        ),
        const Divider(),
        for (var i = 0; i < service.chapters.length; i++)
          ExpansionTile(
            key: ValueKey(
              'chapter-$i-${service.chapters[i].sections.any((s) => s.articles.any((a) => a.path == service.selected.path))}',
            ),
            initiallyExpanded: service.chapters[i].sections.any(
              (s) => s.articles.any((a) => a.path == service.selected.path),
            ),
            tilePadding: const EdgeInsets.symmetric(horizontal: 8),
            title: Text(
              context.tr(service.chapters[i].title),
              style: theme.textTheme.titleSmall,
            ),
            children: [
              for (final section in service.chapters[i].sections) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 16, 12, 6),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      context.tr(section.title),
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                for (final article in section.articles)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: TextButton(
                      key: ValueKey('apex-article-${article.path}'),
                      style: TextButton.styleFrom(
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        foregroundColor: service.selected.path == article.path
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface,
                        backgroundColor: service.selected.path == article.path
                            ? theme.colorScheme.primary.withValues(alpha: .10)
                            : null,
                      ),
                      onPressed: () => onSelect(article),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(context.tr(article.title)),
                      ),
                    ),
                  ),
              ],
            ],
          ),
      ],
    );
  }
}

class _ReaderError extends StatelessWidget {
  const _ReaderError({required this.service});
  final ApexService service;
  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.cloud_off_outlined,
            color: Theme.of(context).colorScheme.error,
            size: 32,
          ),
          const SizedBox(height: 16),
          Text(
            context.tr(service.error!),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            key: const ValueKey('apex-retry'),
            icon: const Icon(Icons.refresh),
            label: Text(context.tr(service.label('Повторить', 'Retry'))),
            onPressed: () => service.chapters.isEmpty
                ? service.load(forceRefresh: true)
                : service.selectArticle(service.selected, forceRefresh: true),
          ),
          TextButton(
            onPressed: () => _openOriginal(context, service),
            child: Text(
              context.tr(
                service.label(
                  'Открыть официальный сайт',
                  'Open official website',
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _ArticleView extends StatelessWidget {
  const _ArticleView({super.key, required this.service});
  final ApexService service;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final blocks = service.article!.blocks;
    final articles = [ApexArticleRef.introduction, ...service.articles];
    final index = articles.indexWhere((a) => a.path == service.selected.path);
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 880),
        child: ListView.builder(
          key: const ValueKey('apex-article-scroll'),
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 112),
          itemCount: blocks.length + 2,
          itemBuilder: (context, i) {
            if (i == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('THE GRAN TURISMO MAGAZINE'),
                      style: theme.textTheme.labelMedium?.copyWith(
                        letterSpacing: 2,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.tr(service.selected.title),
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                  ],
                ),
              );
            }
            if (i == blocks.length + 1) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  const Divider(),
                  Text(
                    context.tr(
                      '${service.label('Источник', 'Source')}: gran-turismo.com · © Sony Interactive Entertainment / Polyphony Digital',
                    ),
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      if (index > 0)
                        Expanded(
                          child: TextButton.icon(
                            key: const ValueKey('apex-previous'),
                            onPressed: () =>
                                service.selectArticle(articles[index - 1]),
                            icon: const Icon(Icons.arrow_back),
                            label: Text(
                              context.tr(service.label('Назад', 'Previous')),
                            ),
                          ),
                        ),
                      if (index < articles.length - 1)
                        Expanded(
                          child: TextButton.icon(
                            key: const ValueKey('apex-next'),
                            onPressed: () =>
                                service.selectArticle(articles[index + 1]),
                            icon: const Icon(Icons.arrow_forward),
                            label: Text(
                              context.tr(service.label('Далее', 'Next')),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              );
            }
            return Directionality(
              textDirection: service.language.isRtl
                  ? TextDirection.rtl
                  : TextDirection.ltr,
              child: _ArticleBlock(block: blocks[i - 1]),
            );
          },
        ),
      ),
    );
  }
}

class _ArticleBlock extends StatelessWidget {
  const _ArticleBlock({required this.block});
  final ApexBlock block;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (block.kind == ApexBlockKind.image) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            block.imageUrl.toString(),
            fit: BoxFit.contain,
            semanticLabel: block.text.isEmpty
                ? context.read<ApexService>().label(
                    'Иллюстрация Beyond the Apex',
                    'Beyond the Apex illustration',
                  )
                : block.text,
            loadingBuilder: (context, child, progress) => progress == null
                ? child
                : const SizedBox(
                    height: 180,
                    child: Center(child: CircularProgressIndicator()),
                  ),
            errorBuilder: (context, error, stack) => Container(
              padding: const EdgeInsets.all(24),
              color: theme.colorScheme.surfaceContainerHighest,
              child: Column(
                children: [
                  const Icon(Icons.image_not_supported_outlined),
                  const SizedBox(height: 8),
                  Text(
                    context.tr(
                      context.read<ApexService>().label(
                        'Иллюстрация недоступна',
                        'Illustration unavailable',
                      ),
                    ),
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    final heading = block.kind == ApexBlockKind.heading;
    final caption = block.kind == ApexBlockKind.caption;
    // The screen already owns the article title; keep section headings only.
    if (heading && block.headingLevel == 1) return const SizedBox.shrink();
    final style = heading
        ? (block.headingLevel >= 4
              ? theme.textTheme.labelLarge
              : theme.textTheme.titleLarge)
        : caption
        ? theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          )
        : theme.textTheme.bodyLarge?.copyWith(height: 1.65);
    final text = SelectableText(context.tr(block.text), style: style);
    return Padding(
      padding: EdgeInsets.only(
        top: heading ? 20 : 0,
        bottom: caption ? 24 : 16,
      ),
      child: block.kind == ApexBlockKind.callout
          ? Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: .07),
                border: Border(
                  left: BorderSide(color: theme.colorScheme.primary, width: 3),
                ),
              ),
              child: text,
            )
          : text,
    );
  }
}
