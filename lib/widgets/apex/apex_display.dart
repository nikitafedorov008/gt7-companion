import '../gt_loading_indicator.dart';
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
import 'apex_theme.dart';
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
  Widget build(BuildContext context) {
    return Theme(
      data: apexMagazineTheme(Theme.of(context)),
      child: Builder(
        builder: (context) => Consumer<ApexService>(
          builder: (context, service, _) {
            return LayoutBuilder(
              builder: (context, constraints) {
                final wide =
                    constraints.maxWidth >= 1000 &&
                    MediaQuery.textScalerOf(context).scale(1) <= 1.25;
                return Scaffold(
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
                  body: SafeArea(
                    top: true,
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Beyond the Apex',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (!wide)
                                Builder(
                                  builder: (context) => IconButton(
                                    key: const ValueKey('apex-contents-button'),
                                    tooltip: context.tr(
                                      service.label('Содержание', 'Contents'),
                                    ),
                                    icon: const Icon(Icons.menu_book_outlined),
                                    onPressed: () =>
                                        Scaffold.of(context).openEndDrawer(),
                                  ),
                                ),
                              IconButton(
                                tooltip: context.tr(
                                  service.label(
                                    'Открыть оригинал',
                                    'Open original',
                                  ),
                                ),
                                icon: const Icon(Icons.open_in_new),
                                onPressed: () =>
                                    _openOriginal(context, service),
                              ),
                              IconButton(
                                key: const ValueKey('apex-close'),
                                tooltip: MaterialLocalizations.of(
                                  context,
                                ).closeButtonTooltip,
                                icon: const Icon(Icons.close_sharp),
                                onPressed: () => context.router.maybePop(),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (wide) ...[
                                SizedBox(
                                  key: const ValueKey('apex-contents-rail'),
                                  width: 350,
                                  child: _ApexContents(
                                    service: service,
                                    onSelect: (reference) => unawaited(
                                      service.selectArticle(reference),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                              ],
                              Expanded(
                                child: service.isLoading
                                    ? const Center(child: GtLoadingIndicator())
                                    : service.error != null
                                    ? _ReaderError(service: service)
                                    : service.article == null
                                    ? const SizedBox.shrink()
                                    : _ArticleView(
                                        key: ValueKey(service.selected.path),
                                        service: service,
                                        wide: wide,
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
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
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: InkWell(
            key: const ValueKey('apex-cover'),
            onTap: () => onSelect(ApexArticleRef.introduction),
            child: Row(
              children: [
                const Icon(Icons.menu_book_outlined, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    context.tr(service.label('Содержание', 'Contents')),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Divider(height: 4, thickness: 4, color: theme.colorScheme.onSurface),
        const SizedBox(height: 16),
        for (var i = 0; i < service.chapters.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Material(
              key: ValueKey('apex-chapter-$i'),
              color: theme.colorScheme.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
                side: BorderSide(color: theme.colorScheme.outline),
              ),
              clipBehavior: Clip.antiAlias,
              child: ExpansionTile(
                key: ValueKey(
                  'chapter-$i-${service.chapters[i].sections.any((s) => s.articles.any((a) => a.path == service.selected.path))}',
                ),
                initiallyExpanded: service.chapters[i].sections.any(
                  (s) => s.articles.any((a) => a.path == service.selected.path),
                ),
                tilePadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                title: _ChapterTitle(
                  title: context.tr(service.chapters[i].title),
                ),
                childrenPadding: const EdgeInsets.only(bottom: 8),
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
                            foregroundColor:
                                service.selected.path == article.path
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface,
                            backgroundColor:
                                service.selected.path == article.path
                                ? theme.colorScheme.surfaceContainer
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
            ),
          ),
        const SizedBox(height: 20),
        Divider(height: 4, thickness: 4, color: theme.colorScheme.onSurface),
      ],
    );
  }
}

class _ChapterTitle extends StatelessWidget {
  const _ChapterTitle({required this.title});
  final String title;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final split = title.indexOf(':');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (split >= 0) ...[
          Text(
            title.substring(0, split + 1).toUpperCase(),
            style: theme.textTheme.labelSmall,
          ),
          const SizedBox(height: 4),
        ],
        Text(
          split >= 0 ? title.substring(split + 1).trim() : title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
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
  const _ArticleView({super.key, required this.service, this.wide = false});
  final ApexService service;
  final bool wide;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final blocks = service.article!.blocks;
    final sectionHeading = blocks
        .where(
          (block) =>
              block.kind == ApexBlockKind.heading && block.headingLevel == 4,
        )
        .firstOrNull;
    final articles = [ApexArticleRef.introduction, ...service.articles];
    final index = articles.indexWhere((a) => a.path == service.selected.path);
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 880),
        child: ListView.builder(
          key: const ValueKey('apex-article-scroll'),
          padding: EdgeInsets.fromLTRB(
            24,
            service.selected.path == '/top' && wide ? 64 : 24,
            24,
            40,
          ),
          itemCount: blocks.length + 2,
          itemBuilder: (context, i) {
            if (i == 0) {
              if (service.selected.path == '/top')
                return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr(
                        sectionHeading?.text ?? 'THE GRAN TURISMO MAGAZINE',
                      ),
                      style: theme.textTheme.labelMedium?.copyWith(
                        letterSpacing: .5,
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
                    Divider(color: theme.colorScheme.onSurface, thickness: 3),
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
            if (identical(blocks[i - 1], sectionHeading))
              return const SizedBox.shrink();
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
                  child: Center(child: GtLoadingIndicator()),
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
