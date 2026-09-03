import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Traduit à la volée les données "métier" qui viennent du Google Sheet
/// (catégories et ingrédients) via l'API gratuite MyMemory.
///
/// Règles importantes :
/// - On ne traduit JAMAIS les noms de pizzas ici. Ce sont des noms de marque
///   ("La Casita Spéciale", "La Reine"...) qu'une traduction mot-à-mot
///   dénaturerait (ex. "La Casita Spéciale" -> "The Little House Special" en
///   anglais). Comme la plupart des menus multilingues, on garde le nom de
///   la pizza tel quel dans toutes les langues et on ne traduit que la
///   catégorie et les ingrédients. C'est donc à l'appelant de ne jamais
///   passer un nom de pizza à ce service.
/// - Chaque traduction est mise en cache dans SharedPreferences, avec le
///   texte source associé. On ne rappelle l'API que si le texte français a
///   changé depuis la dernière fois (ex. le gérant modifie un ingrédient
///   dans le Google Sheet) ou si on n'a encore jamais traduit ce texte dans
///   cette langue. Cela évite de retraduire tout le menu à chaque lancement
///   de l'app, ce qui serait inutile, plus lent, et gaspillerait le quota
///   gratuit de l'API pour rien.
class TranslationService {
  TranslationService._();

  static final TranslationService instance = TranslationService._();

  static const String _cachePrefix = 'translation_cache_v1_';

  SharedPreferences? _prefs;

  /// Déduplique les appels concurrents pour le même (texte, langue) — utile
  /// car plusieurs pizzas partagent souvent le même ingrédient et sont
  /// traduites en parallèle au chargement du menu.
  final Map<String, Future<String>> _inFlight = {};

  Future<SharedPreferences> get _prefsInstance async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  String _cacheKey(String sourceText, String targetLang) {
    return '$_cachePrefix${targetLang}_${sourceText.hashCode}';
  }

  /// Traduit [sourceText] (toujours en français dans le Google Sheet) vers
  /// [targetLang]. Ne doit jamais être appelé avec un nom de pizza : ceux-ci
  /// doivent rester identiques dans toutes les langues.
  ///
  /// Retourne le texte source si :
  /// - la langue cible est le français (rien à traduire),
  /// - le texte est vide,
  /// - la traduction échoue (pas de réseau, quota MyMemory dépassé...) :
  ///   mode dégradé, on ne bloque jamais l'affichage du menu.
  Future<String> translate(String sourceText, String targetLang) async {
    final String trimmed = sourceText.trim();
    if (trimmed.isEmpty || targetLang == 'fr') return sourceText;

    final String key = _cacheKey(trimmed, targetLang);

    final Future<String>? pending = _inFlight[key];
    if (pending != null) return pending;

    final Future<String> future = _translateWithCache(trimmed, targetLang, key);
    _inFlight[key] = future;
    try {
      return await future;
    } finally {
      _inFlight.remove(key);
    }
  }

  /// Traduit une liste de textes (catégories et/ou ingrédients) vers
  /// [targetLang]. Les appels sont dédupliqués et mis en cache comme dans
  /// [translate].
  Future<List<String>> translateAll(
    List<String> sourceTexts,
    String targetLang,
  ) {
    return Future.wait(sourceTexts.map((t) => translate(t, targetLang)));
  }

  Future<String> _translateWithCache(
    String sourceText,
    String targetLang,
    String key,
  ) async {
    final prefs = await _prefsInstance;
    final String? cachedRaw = prefs.getString(key);

    if (cachedRaw != null) {
      try {
        final Map<String, dynamic> cached =
            jsonDecode(cachedRaw) as Map<String, dynamic>;
        // On ne réutilise le cache que si le texte source n'a pas changé
        // dans le Google Sheet depuis la dernière traduction. Si le gérant a
        // renommé un ingrédient, on retraduit.
        if (cached['source'] == sourceText &&
            cached['translation'] is String) {
          return cached['translation'] as String;
        }
      } catch (_) {
        // Cache corrompu (ancien format, JSON invalide...) : on ignore et on
        // retraduit normalement.
      }
    }

    try {
      final Uri url = Uri.https('api.mymemory.translated.net', '/get', {
        'q': sourceText,
        'langpair': 'fr|$targetLang',
      });
      final response = await http.get(url).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data =
            jsonDecode(response.body) as Map<String, dynamic>;
        final String? translated =
            (data['responseData'] as Map<String, dynamic>?)?['translatedText']
                as String?;

        if (translated != null && translated.trim().isNotEmpty) {
          await prefs.setString(
            key,
            jsonEncode({'source': sourceText, 'translation': translated}),
          );
          return translated;
        }
      }
    } catch (_) {
      // Hors-ligne, timeout, quota MyMemory dépassé... on retombe sur le
      // texte source français plutôt que de planter l'affichage du menu.
    }

    return sourceText;
  }
}
