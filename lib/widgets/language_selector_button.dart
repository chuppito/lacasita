import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/locale_provider.dart';

/// Bouton (icône globe) à poser dans une AppBar : ouvre une feuille en bas
/// d'écran permettant de choisir la langue de l'application, ou de revenir
/// au suivi automatique de la langue du téléphone.
class LanguageSelectorButton extends StatelessWidget {
  const LanguageSelectorButton({super.key, this.iconColor = Colors.white});

  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.language, color: iconColor),
      tooltip: AppLocalizations.of(context)?.chooseLanguage ?? 'Language',
      onPressed: () => _showLanguagePicker(context),
    );
  }

  void _showLanguagePicker(BuildContext context) {
    final localeProvider = context.read<LocaleProvider>();
    final t = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Text(
                  t.chooseLanguage,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.smartphone),
                title: Text(t.systemLanguage),
                trailing: localeProvider.followsSystemLanguage
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () {
                  localeProvider.useSystemLanguage();
                  Navigator.of(sheetContext).pop();
                },
              ),
              const Divider(height: 1),
              ...AppLocalizations.supportedLocales.map((locale) {
                final code = locale.languageCode;
                final isSelected = !localeProvider.followsSystemLanguage &&
                    localeProvider.locale?.languageCode == code;
                return ListTile(
                  leading: Text(
                    AppLocalizations.flagEmojis[code] ?? '',
                    style: const TextStyle(fontSize: 22),
                  ),
                  title: Text(AppLocalizations.displayNames[code] ?? code),
                  trailing: isSelected
                      ? const Icon(Icons.check, color: Colors.green)
                      : null,
                  onTap: () {
                    localeProvider.setLocale(locale);
                    Navigator.of(sheetContext).pop();
                  },
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}
