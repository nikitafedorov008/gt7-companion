import 'package:gt7_companion/widgets/window_navigation_safe_area.dart';
import 'package:gt7_companion/l10n/ui_messages.dart';
// START_MODULE_CONTRACT
// PURPOSE: GT7-style global application settings with immediate locale changes.
// SCOPE: Language selection, existing audio preferences and source credits.
// DEPENDS: M-SETTINGS, M-LOCALIZATION, M-SOUND
// LINKS: M-SETTINGS, V-M-SETTINGS
// END_MODULE_CONTRACT
// START_MODULE_MAP
// SettingsDisplay - independent routed settings screen.
// END_MODULE_MAP
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/app_settings_service.dart';
import '../../services/music_service.dart';
import '../../services/sound_service.dart';
import '../telemetry/telemetry_connection_dialog.dart';

@RoutePage()
class SettingsDisplay extends StatefulWidget {
  const SettingsDisplay({super.key});
  @override
  State<SettingsDisplay> createState() => _SettingsDisplayState();
}

class _SettingsDisplayState extends State<SettingsDisplay> {
  int _section = 0;
  bool _languageDetail = false;
  bool _telemetryDetail = false;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: Color.alphaBlend(
        theme.colorScheme.onSurface.withValues(alpha: .035),
        theme.colorScheme.surface,
      ),
      body: SafeArea(
        child: Column(
          children: [
            WindowNavigationSafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    if (_section == 0 && (_languageDetail || _telemetryDetail))
                      IconButton(
                        key: const ValueKey('settings-back'),
                        tooltip: context.tr('Back'),
                        onPressed: () => setState(() {
                          _languageDetail = false;
                          _telemetryDetail = false;
                        }),
                        icon: const Icon(Icons.arrow_back),
                      ),
                    Expanded(
                      child: Text(
                        context.tr(l10n.settings),
                        style: theme.textTheme.titleLarge,
                      ),
                    ),
                    IconButton(
                      key: const ValueKey('settings-close'),
                      tooltip: context.tr(l10n.close),
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_sharp),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 740),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          theme.colorScheme.surfaceContainerHighest,
                          theme.colorScheme.surfaceContainerLow,
                        ],
                      ),
                    ),
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final entry in [
                            l10n.general,
                            l10n.audio,
                            l10n.about,
                          ].indexed)
                            Expanded(
                              child: Material(
                                color: _section == entry.$1
                                    ? theme.colorScheme.onSurface.withValues(
                                        alpha: .20,
                                      )
                                    : Colors.transparent,
                                child: InkWell(
                                  key: ValueKey('settings-tab-${entry.$1}'),
                                  onTap: () => setState(() {
                                    _section = entry.$1;
                                    _languageDetail = false;
                                    _telemetryDetail = false;
                                  }),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 14,
                                    ),
                                    child: Center(
                                      child: Text(
                                        entry.$2,
                                        textAlign: TextAlign.center,
                                        style: theme.textTheme.labelLarge
                                            ?.copyWith(
                                              color: theme.colorScheme.onSurface
                                                  .withValues(
                                                    alpha: _section == entry.$1
                                                        ? 1
                                                        : .65,
                                                  ),
                                            ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1000),
                    child: switch (_section) {
                      0 =>
                        _telemetryDetail
                            ? _Panel(
                                icon: Icons.sensors_outlined,
                                title: l10n.telemetryTitle,
                                description: l10n.telemetrySettingsDescription,
                                child: const TelemetryAutoSettings(),
                              )
                            : _languageDetail
                            ? _Panel(
                                icon: Icons.language_outlined,
                                title: context.tr('Application language'),
                                description: context.tr(
                                  'Choose the language used throughout the app.',
                                ),
                                child: const _LanguageSettings(),
                              )
                            : _SettingsCategories(
                                onLanguage: () =>
                                    setState(() => _languageDetail = true),
                                onTelemetry: () =>
                                    setState(() => _telemetryDetail = true),
                                onAudio: () => setState(() => _section = 1),
                                onAbout: () => setState(() => _section = 2),
                              ),
                      1 => const _AudioSettings(),
                      _ => _Panel(
                        icon: Icons.info_outline,
                        title: l10n.about,
                        description: 'Gran Turismo 7 Companion',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.tr('Sources and licences'),
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: 12),
                            SelectableText(
                              context.tr(
                                'Car data & photography: Polyphony Digital / gran-turismo.com.\nGTPlus · GT7 Info · GTDB · DG-Edge · GTSh.\nNatural Earth: public domain.',
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              context.tr('Music credits'),
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: 12),
                            SelectableText(context.tr(MusicService.credits)),
                            const SizedBox(height: 12),
                            TextButton.icon(
                              key: const ValueKey('settings-licences'),
                              onPressed: () => showLicensePage(
                                context: context,
                                applicationName: 'GT7 Companion',
                              ),
                              icon: const Icon(Icons.article_outlined),
                              label: Text(context.tr('Licences')),
                            ),
                          ],
                        ),
                      ),
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageSettings extends StatelessWidget {
  const _LanguageSettings();
  @override
  Widget build(BuildContext context) => Consumer<AppSettingsService>(
    builder: (context, settings, _) {
      final theme = Theme.of(context);
      final l10n = context.l10n;
      final labels = {
        AppLanguage.system: l10n.systemLanguage,
        AppLanguage.russian: 'Русский',
        AppLanguage.english: 'English',
      };
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final value in AppLanguage.values)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: settings.language == value
                    ? theme.colorScheme.onSurface.withValues(alpha: .12)
                    : theme.colorScheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                  side: BorderSide(color: theme.colorScheme.outlineVariant),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  key: ValueKey('settings-language-${value.name}'),
                  onTap: () => settings.setLanguage(value),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          settings.language == value
                              ? Icons.radio_button_checked
                              : Icons.radio_button_off,
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            context.tr(labels[value]!),
                            style: theme.textTheme.bodyLarge,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 8),
          Text(
            context.tr(
              'Changes apply immediately and are saved on this device.',
            ),
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Text(
            context.tr('Unsupported system languages use English.'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (settings.storageError != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                context.tr(settings.storageError!),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
        ],
      );
    },
  );
}

class _AudioSettings extends StatelessWidget {
  const _AudioSettings();
  @override
  Widget build(BuildContext context) => Consumer2<SoundService, MusicService>(
    builder: (context, sound, music, _) => _Panel(
      icon: Icons.tune,
      title: context.l10n.audio,
      description: context.tr('Menu music and interface feedback.'),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: Text(context.tr('Interface sounds'))),
              Switch(
                key: const ValueKey('settings-sound'),
                value: sound.enabled,
                onChanged: sound.setEnabled,
              ),
            ],
          ),
          const Divider(),
          Row(
            children: [
              Expanded(child: Text(context.tr('Ambient music'))),
              Switch(
                key: const ValueKey('settings-music'),
                value: music.enabled,
                onChanged: music.setEnabled,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            context.tr(
              'Music and effects keep their existing balanced levels.',
            ),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    ),
  );
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.icon,
    required this.title,
    required this.description,
    required this.child,
  });
  final IconData icon;
  final String title;
  final String description;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: .4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 40, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(height: 16),
          Text(context.tr(title), style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            context.tr(description),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }
}

class _SettingsCategories extends StatelessWidget {
  const _SettingsCategories({
    required this.onLanguage,
    required this.onAudio,
    required this.onAbout,
    required this.onTelemetry,
  });
  final VoidCallback onLanguage, onAudio, onAbout, onTelemetry;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = constraints.maxWidth >= 840
          ? 3
          : constraints.maxWidth >= 480
          ? 2
          : 1;
      final width = (constraints.maxWidth - 12 * (columns - 1)) / columns;
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _SettingsCategory(
            controlKey: const ValueKey('settings-telemetry-card'),
            width: width,
            icon: Icons.sensors_outlined,
            title: context.l10n.telemetryTitle,
            description: context.l10n.telemetrySettingsDescription,
            onTap: onTelemetry,
          ),
          _SettingsCategory(
            controlKey: const ValueKey('settings-language-card'),
            width: width,
            icon: Icons.language_outlined,
            title: context.tr('Application language'),
            description: context.tr(
              'Choose the language used throughout the app.',
            ),
            onTap: onLanguage,
          ),
          _SettingsCategory(
            controlKey: const ValueKey('settings-audio-card'),
            width: width,
            icon: Icons.tune_outlined,
            title: context.l10n.audio,
            description: context.tr('Menu music and interface feedback.'),
            onTap: onAudio,
          ),
          _SettingsCategory(
            controlKey: const ValueKey('settings-about-card'),
            width: width,
            icon: Icons.info_outline,
            title: context.l10n.about,
            description: context.tr('Sources and licences'),
            onTap: onAbout,
          ),
        ],
      );
    },
  );
}

class _SettingsCategory extends StatelessWidget {
  const _SettingsCategory({
    this.controlKey,
    required this.width,
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });
  final Key? controlKey;
  final double width;
  final IconData icon;
  final String title, description;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: width,
      child: Material(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: controlKey,
          onTap: onTap,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: 270 * MediaQuery.textScalerOf(context).scale(1),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Icon(
                    icon,
                    size: 56,
                    color: theme.colorScheme.onSurface.withValues(alpha: .55),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    description,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: .6),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
