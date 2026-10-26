// START_MODULE_CONTRACT
// PURPOSE: Load the official Beyond the Apex in the selected language menu and articles.
// SCOPE: HTTP, parsing, in-memory cache and current reader selection.
// DEPENDS: M-MODEL-APEX
// LINKS: M-SERVICE-APEX, V-M-SERVICE-APEX
// END_MODULE_CONTRACT
// START_MODULE_MAP
// ApexService - observable reader data and official content parsing.
// END_MODULE_MAP
import 'dart:convert';
import 'dart:async';
import 'app_settings_service.dart';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/apex/apex_content.dart';
import '../models/apex/apex_language.dart';

class ApexService extends ChangeNotifier {
  ApexService({
    http.Client? httpClient,
    AppSettingsService? appSettings,
    List<Locale>? systemLocales,
    this.timeout = const Duration(seconds: 15),
  }) : _appSettings = appSettings,
       _http = httpClient ?? http.Client(),
       _ownsClient = httpClient == null,
       _systemLocales = systemLocales ?? PlatformDispatcher.instance.locales,
       _language = ApexLanguage.fromSystem(
         systemLocales ?? PlatformDispatcher.instance.locales,
       ) {
    _appSettings?.addListener(_applyAppLocale);
    _applyAppLocale();
  }
  final AppSettingsService? _appSettings;
  void _applyAppLocale() {
    final settings = _appSettings;
    if (settings == null || _disposed) return;
    _preferencesLoaded = true;
    _restoringPreferences = Future.value();
    final resolved = ApexLanguage.fromSiteLocale(
      settings.effectiveLocale.languageCode == 'ru' ? 'ru' : 'us',
    )!;
    _languageOverride = resolved;
    if (resolved.siteLocale == _language.siteLocale) return;
    final wasActive =
        _menuLoading ||
        _articleLoading ||
        _chapters.isNotEmpty ||
        _article != null;
    _language = resolved;
    _resetLanguageContent();
    notifyListeners();
    if (wasActive) unawaited(load(forceRefresh: true));
  }

  static final source = Uri.parse('https://www.gran-turismo.com/ru/gt7/apex/');
  static const languagePrefsKey = 'apex_content_language';
  List<Locale> _systemLocales;
  ApexLanguage _language;
  ApexLanguage? _languageOverride;
  bool _preferencesLoaded = false;
  Future<void>? _restoringPreferences;
  int _menuRequest = 0;
  ApexLanguage get language => _language;
  bool get followsSystem => _languageOverride == null;
  Uri get sourceUrl =>
      Uri.https('www.gran-turismo.com', '/${_language.siteLocale}/gt7/apex/');
  String label(String russian, String english) =>
      _language.languageCode == 'ru' ? russian : english;

  final http.Client _http;
  final bool _ownsClient;
  final Duration timeout;
  final Map<String, ApexArticle> _cache = {};
  List<ApexChapter> _chapters = [];
  ApexArticleRef _selected = ApexArticleRef.introduction;
  ApexArticle? _article;
  String? _error;
  bool _menuLoading = false;
  bool _articleLoading = false;
  bool _disposed = false;
  int _request = 0;
  List<ApexChapter> get chapters => List.unmodifiable(_chapters);
  ApexArticleRef get selected => _selected;
  ApexArticle? get article => _article;
  String? get error => _error;
  bool get isLoading => _menuLoading || _articleLoading;
  List<ApexArticleRef> get articles => [
    for (final chapter in _chapters)
      for (final section in chapter.sections) ...section.articles,
  ];

  Future<void> load({bool forceRefresh = false}) async {
    if (_disposed) return;
    await (_restoringPreferences ??= _restoreLanguage());
    if (_disposed || (_menuLoading && !forceRefresh)) return;
    if (_chapters.isNotEmpty && !forceRefresh) {
      if (_article == null) await selectArticle(_selected);
      return;
    }
    final menuRequest = ++_menuRequest;
    final siteLocale = _language.siteLocale;
    _menuLoading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _getJson(
        Uri.https('www.gran-turismo.com', '/$siteLocale/gt7/api/apex/'),
      );
      final chapters = (data as List<dynamic>)
          .map((item) => ApexChapter.fromJson(item as Map<String, dynamic>))
          .toList();
      if (chapters.isEmpty || chapters.every((c) => c.sections.isEmpty)) {
        throw const FormatException('Empty Apex contents');
      }
      if (_disposed || menuRequest != _menuRequest) return;
      _chapters = chapters;
      _selected =
          articles.where((a) => a.path == _selected.path).firstOrNull ??
          ApexArticleRef.introduction;
    } catch (e) {
      if (!_disposed && menuRequest == _menuRequest) {
        _error = label(
          'Не удалось загрузить оглавление. Проверьте подключение и повторите.',
          'Could not load contents. Check your connection and retry.',
        );
        debugPrint('ApexService: menu load failed: $e');
      }
    } finally {
      if (!_disposed && menuRequest == _menuRequest) {
        _menuLoading = false;
        notifyListeners();
      }
    }
    if (!_disposed && menuRequest == _menuRequest && _error == null) {
      await selectArticle(_selected, forceRefresh: forceRefresh);
    }
  }

  Future<void> selectArticle(
    ApexArticleRef reference, {
    bool forceRefresh = false,
  }) async {
    if (_disposed) return;
    if (reference.path != '/top' &&
        !RegExp(r'^/[a-z0-9_]+/[a-z0-9_]+/[0-9]+$').hasMatch(reference.path)) {
      throw ArgumentError.value(
        reference.path,
        'path',
        'Invalid Apex article path',
      );
    }
    final request = ++_request;
    final languageId = _language.siteLocale;
    _selected = reference;
    _error = null;
    _article = forceRefresh ? null : _cache[reference.path];
    _articleLoading = _article == null;
    notifyListeners();
    if (!_articleLoading) return;
    try {
      final uri = Uri.https(
        'www.gran-turismo.com',
        '/$languageId/gt7/api/apex_v2/',
        {'u': reference.path},
      );
      final data = await _getJson(uri) as Map<String, dynamic>;
      final parsed = parseArticle(reference, data['html'] as String);
      if (_disposed || languageId != _language.siteLocale) return;
      _cache[reference.path] = parsed;
      if (request == _request) _article = parsed;
    } catch (e) {
      if (!_disposed && request == _request) {
        _error = label(
          'Не удалось загрузить статью. Попробуйте ещё раз.',
          'Could not load this article. Please retry.',
        );
        debugPrint('ApexService: article load failed: $e');
      }
    } finally {
      if (!_disposed && request == _request) {
        _articleLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> _restoreLanguage() async {
    if (_preferencesLoaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_disposed || _preferencesLoaded) return;
      _languageOverride = ApexLanguage.fromSiteLocale(
        prefs.getString(languagePrefsKey),
      );
      _language = _languageOverride ?? ApexLanguage.fromSystem(_systemLocales);
    } catch (e) {
      debugPrint('ApexService: could not restore language: $e');
    }
    _preferencesLoaded = true;
  }

  /// Null returns to following the system; a manual choice survives restarts.
  Future<void> setLanguage(ApexLanguage? language) async {
    if (_appSettings != null) return;
    if (_disposed) return;
    _preferencesLoaded = true;
    _languageOverride = language;
    final resolved = language ?? ApexLanguage.fromSystem(_systemLocales);
    final changed = resolved.siteLocale != _language.siteLocale;
    _language = resolved;
    if (changed) _resetLanguageContent();
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      if (language == null) {
        await prefs.remove(languagePrefsKey);
      } else {
        await prefs.setString(languagePrefsKey, language.siteLocale);
      }
    } catch (e) {
      debugPrint('ApexService: could not store language: $e');
    }
    if (changed && !_disposed) await load(forceRefresh: true);
  }

  Future<void> updateSystemLocales(List<Locale> locales) async {
    if (_appSettings != null) return;
    _systemLocales = locales;
    if (!followsSystem || _disposed) return;
    final resolved = ApexLanguage.fromSystem(locales);
    if (resolved.siteLocale == _language.siteLocale) return;
    _language = resolved;
    _resetLanguageContent();
    notifyListeners();
    await load(forceRefresh: true);
  }

  void _resetLanguageContent() {
    _request++;
    _menuRequest++;
    _menuLoading = false;
    _articleLoading = false;
    _chapters = [];
    _article = null;
    _error = null;
    _cache.clear();
  }

  Future<dynamic> _getJson(Uri uri) async {
    final response = await _http
        .get(uri, headers: {'Accept': 'application/json'})
        .timeout(timeout);
    if (response.statusCode != 200) {
      throw http.ClientException('HTTP ${response.statusCode}', uri);
    }
    return jsonDecode(utf8.decode(response.bodyBytes));
  }

  /// Consume only reading blocks. Never execute scripts, buttons or inline handlers.
  static ApexArticle parseArticle(ApexArticleRef reference, String markup) {
    final document = html.parse(markup);
    final root = document.querySelector('.manual_detail');
    if (root == null) throw const FormatException('Missing Apex article');
    for (final element in root.querySelectorAll(
      'script, style, button, .qrlink',
    )) {
      element.remove();
    }
    final blocks = <ApexBlock>[];
    String text(dom.Element element) {
      final clone = element.clone(true);
      for (final br in clone.querySelectorAll('br')) {
        br.replaceWith(dom.Text('\n'));
      }
      return clone.text.replaceAll(RegExp(r'[ \t]+'), ' ').trim();
    }

    void visit(dom.Element element) {
      final tag = element.localName;
      if (tag == 'img') {
        final raw = element.attributes['src'];
        if (raw == null) return;
        final uri = source.resolve(raw);
        if (uri.scheme == 'https' &&
            (uri.host == source.host || uri.host == 'www.gran-turismo.com')) {
          blocks.add(
            ApexBlock(
              kind: ApexBlockKind.image,
              imageUrl: uri,
              text: element.attributes['alt'] ?? '',
            ),
          );
        }
        return;
      }
      if (RegExp(r'^h[1-6]$').hasMatch(tag ?? '') ||
          tag == 'p' ||
          tag == 'li' ||
          tag == 'table') {
        final value = tag == 'table'
            ? element
                  .querySelectorAll('tr')
                  .map(
                    (row) =>
                        row.querySelectorAll('th, td').map(text).join('  ·  '),
                  )
                  .join('\n')
            : text(element);
        if (value.isNotEmpty) {
          final kind = (tag?.startsWith('h') ?? false)
              ? ApexBlockKind.heading
              : element.classes.contains('caption')
              ? ApexBlockKind.caption
              : element.classes.any((c) => c.startsWith('block_'))
              ? ApexBlockKind.callout
              : ApexBlockKind.paragraph;
          blocks.add(
            ApexBlock(
              kind: kind,
              text: tag == 'li' ? '• $value' : value,
              headingLevel: int.tryParse(tag?.substring(1) ?? '') ?? 2,
            ),
          );
        }
        // A paragraph can contain an illustration or a responsive picture.
        for (final image in element.querySelectorAll('img')) {
          visit(image);
        }
        return;
      }
      for (final child in element.children) {
        visit(child);
      }
    }

    visit(root);
    if (blocks.isEmpty) throw const FormatException('Empty Apex article');
    return ApexArticle(reference: reference, blocks: List.unmodifiable(blocks));
  }

  @override
  void dispose() {
    _appSettings?.removeListener(_applyAppLocale);
    _disposed = true;
    _request++;
    if (_ownsClient) _http.close();
    super.dispose();
  }
}
