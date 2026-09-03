import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';

/// Gère la langue de l'application.
///
/// - Si l'utilisateur n'a jamais choisi de langue manuellement, l'app suit
///   automatiquement la langue du téléphone (si elle est supportée, sinon
///   on retombe sur le français).
/// - Si l'utilisateur choisit une langue via le bouton de sélection, ce
///   choix est mémorisé (SharedPreferences) et prime sur la langue système,
///   même après un redémarrage de l'app.
class LocaleProvider extends ChangeNotifier {
  static const String _prefsKey = 'app_locale_code';

  Locale? _locale; // null = suit la langue du téléphone
  bool _isLoaded = false;

  Locale? get locale => _locale;
  bool get isLoaded => _isLoaded;

  /// true si l'utilisateur suit la langue du téléphone (pas de choix manuel).
  bool get followsSystemLanguage => _locale == null;

  LocaleProvider() {
    _loadSavedLocale();
  }

  Future<void> _loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCode = prefs.getString(_prefsKey);
    if (savedCode != null &&
        AppLocalizations.supportedLocales
            .any((l) => l.languageCode == savedCode)) {
      _locale = Locale(savedCode);
    }
    _isLoaded = true;
    notifyListeners();
  }

  /// Choisit une langue manuellement et la mémorise.
  Future<void> setLocale(Locale locale) async {
    _locale = locale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, locale.languageCode);
  }

  /// Repasse en mode "suivre la langue du téléphone".
  Future<void> useSystemLanguage() async {
    _locale = null;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }

  /// Utilisé par `MaterialApp.localeResolutionCallback` : si l'utilisateur
  /// n'a pas fait de choix manuel, on essaie de matcher la langue du
  /// téléphone parmi les langues supportées, sinon on retombe sur le
  /// français.
  Locale resolveLocale(Locale? deviceLocale) {
    if (_locale != null) return _locale!;
    if (deviceLocale != null) {
      for (final supported in AppLocalizations.supportedLocales) {
        if (supported.languageCode == deviceLocale.languageCode) {
          return supported;
        }
      }
    }
    return const Locale('fr');
  }
}
