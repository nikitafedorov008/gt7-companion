import 'dart:ui';

/// Content editions exposed by the official Apex country/language selector.
class ApexLanguage {
  const ApexLanguage(
    this.siteLocale,
    this.name,
    this.languageCode, {
    this.countryCode,
  });
  final String siteLocale;
  final String name;
  final String languageCode;
  final String? countryCode;
  bool get isRtl => languageCode == 'ar';

  static const supported = [
    ApexLanguage('gb', 'English (UK)', 'en', countryCode: 'GB'),
    ApexLanguage('us', 'English (US)', 'en', countryCode: 'US'),
    ApexLanguage('ru', 'Русский', 'ru'),
    ApexLanguage('de', 'Deutsch', 'de'),
    ApexLanguage('fr', 'Français', 'fr'),
    ApexLanguage('es', 'Español', 'es', countryCode: 'ES'),
    ApexLanguage('mx', 'Español (México)', 'es', countryCode: 'MX'),
    ApexLanguage('it', 'Italiano', 'it'),
    ApexLanguage('pt', 'Português', 'pt', countryCode: 'PT'),
    ApexLanguage('br', 'Português (Brasil)', 'pt', countryCode: 'BR'),
    ApexLanguage('nl', 'Nederlands', 'nl'),
    ApexLanguage('pl', 'Polski', 'pl'),
    ApexLanguage('cz', 'Čeština', 'cs'),
    ApexLanguage('gr', 'Ελληνικά', 'el'),
    ApexLanguage('tr', 'Türkçe', 'tr'),
    ApexLanguage('sa', 'العربية', 'ar'),
    ApexLanguage('jp', '日本語', 'ja'),
    ApexLanguage('kr', '한국어', 'ko'),
    ApexLanguage('cn', '简体中文', 'zh', countryCode: 'CN'),
    ApexLanguage('tw', '繁體中文', 'zh', countryCode: 'TW'),
    ApexLanguage('th', 'ภาษาไทย', 'th'),
  ];

  static ApexLanguage? fromSiteLocale(String? code) {
    for (final language in supported) {
      if (language.siteLocale == code) return language;
    }
    return null;
  }

  static ApexLanguage fromSystem(List<Locale> locales) {
    for (final locale in locales) {
      final candidates = supported.where(
        (l) => l.languageCode == locale.languageCode,
      );
      if (candidates.isEmpty) continue;
      if (locale.languageCode == 'zh') {
        return fromSiteLocale(
          locale.scriptCode == 'Hant' ||
                  ['TW', 'HK', 'MO'].contains(locale.countryCode)
              ? 'tw'
              : 'cn',
        )!;
      }
      for (final candidate in candidates) {
        if (candidate.countryCode == locale.countryCode) return candidate;
      }
      return candidates.first;
    }
    return supported.first;
  }
}
