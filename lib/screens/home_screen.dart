import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import '../providers/cart_provider.dart';
import '../models/pizza.dart';
import '../services/translation_service.dart';
import '../widgets/language_selector_button.dart';
import 'cart_screen.dart';
import 'fidelity_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const Color _pinkPrimary = Color(0xFFF06292);

  // Pizzas telles que reçues du Google Sheet, toujours en français : c'est
  // la source de vérité. `_allPizzas` / `_filteredPizzas` sont dérivées de
  // cette liste pour l'affichage (catégorie + ingrédients traduits dans la
  // langue courante ; le nom de la pizza, lui, n'est jamais traduit).
  List<Pizza> _allPizzasRaw = [];
  List<Pizza> _allPizzas = [];
  List<Pizza> _filteredPizzas = [];
  bool _isLoading = true;
  String _errorMessage = "";
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  // Filtre par catégorie (valeur brute française : 'tomate', 'crème',
  // 'mixte', 'boissons', 'calzone'). null = "Toutes".
  String? _selectedCategoryKey;

  static const List<String> _filterCategoryKeys = [
    'tomate',
    'crème',
    'mixte',
    'boissons',
    'calzone',
  ];

  // Libellés des chips de filtre dans les 3 langues supportées par l'app.
  // Fixe et très court : pas besoin de passer par l'API de traduction pour
  // ça, contrairement aux données du Google Sheet.
  static const Map<String, Map<String, String>> _categoryLabels = {
    'all': {'fr': 'Toutes', 'en': 'All', 'es': 'Todas'},
    'tomate': {'fr': 'Tomate', 'en': 'Tomato', 'es': 'Tomate'},
    'crème': {'fr': 'Crème', 'en': 'Cream', 'es': 'Crema'},
    'mixte': {'fr': 'Mixte', 'en': 'Mixed', 'es': 'Mixta'},
    'boissons': {'fr': 'Boissons', 'en': 'Drinks', 'es': 'Bebidas'},
    'calzone': {'fr': 'Calzone', 'en': 'Calzone', 'es': 'Calzone'},
  };

  String _categoryLabel(String key, String lang) {
    final entry = _categoryLabels[key];
    return entry?[lang] ?? entry?['fr'] ?? key;
  }

  /// Normalise une catégorie pour comparaison, en ignorant la casse et les
  /// accents (ex : 'crème' et 'Creme' doivent être considérés identiques).
  String _normalizeCategory(String value) {
    return value
        .toLowerCase()
        .replaceAll('è', 'e')
        .replaceAll('é', 'e')
        .trim();
  }

  // Langue pour laquelle `_allPizzas` est actuellement traduite. Permet de
  // ne relancer une traduction que quand la langue change réellement (pas à
  // chaque rebuild), et de ne jamais retraduire deux fois pour rien.
  String? _translatedForLocale;

  // Ces 3 valeurs viennent maintenant TOUTES du document Firestore
  // users/$_parentDocId, mis à jour en temps réel par l'app Maître.
  String? _exceptionalMessage;
  bool _exceptionalMessageDismissedLocally = false;

  // null  = aucun override actif : le statut suit l'horaire fixe ci-dessous.
  // true  = le gérant a forcé "ouvert" depuis l'app Maître.
  // false = le gérant a forcé "fermé" depuis l'app Maître.
  //
  // C'est ce champ (et non plus `isOpen` directement) qui pilote la priorité
  // manuel > horaire : le calcul d'horaire ci-dessous tourne donc en
  // continu, côté client, sans dépendre de l'app Maître pour se déclencher.
  bool? _manualOverride;

  /// Horodatage d'activation de l'override en cours, utilisé pour la
  /// sécurité anti-oubli (voir _buildOpeningStatus) : un override activé
  /// tard le soir reste valide jusqu'au 21h du lendemain, il n'est jamais
  /// ignoré immédiatement juste parce qu'il est tard.
  DateTime? _manualOverrideSetAt;

  // Numéro affiché tant que Firestore n'a pas encore répondu (1er lancement,
  // hors-ligne...). Le gérant peut ensuite le changer à distance depuis
  // l'app Maître : le champ `phone` du document users/$_parentDocId prime
  // toujours dès qu'il est disponible.
  String _phoneNumber = "+33619474466";

  static const String _parentDocId = "7TFknuq2ZcgFvO9czyq8gtQSELH2";

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
      _restaurantConfigSubscription;

  // Ces clés restent en français : elles doivent correspondre aux
  // ingrédients (en français) provenant du tableur Google Sheets. Le nom
  // affiché à l'écran est traduit via `AppLocalizations.supplementName`.
  final List<String> _availableSupplements = [
    "Ananas",
    "Anchois",
    "Ail",
    "Aneth",
    "Bœuf",
    "Bœuf épicé",
    "Camembert",
    "Câpres",
    "Champignons",
    "Cheddar",
    "Chèvre",
    "Chorizo",
    "Ciboulette",
    "Coulis d'olives",
    "Curry",
    "Emmental",
    "Gorgonzola",
    "Jambon",
    "Kebab (Viande)",
    "Lardons",
    "Maïs",
    "Merguez",
    "Miel",
    "Moutarde",
    "Mozzarella",
    "Noix",
    "Noix de St Jacques",
    "Oignons",
    "Origan",
    "Persillade",
    "Poivrons",
    "Pomme",
    "Pommes de terre",
    "Poulet",
    "Raclette",
    "Ravioles",
    "Reblochon",
    "Roquefort",
    "St Marcellin",
    "Tomates",
    "Truite fumée"
  ];

  @override
  void initState() {
    super.initState();
    _fetchPizzas();
    _startRestaurantConfigListener();
  }

  @override
  void dispose() {
    _restaurantConfigSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Se déclenche au premier build ET à chaque changement de langue (via le
    // sélecteur ou un changement de langue système), car `AppLocalizations`
    // est une InheritedWidget dont cette méthode dépend.
    _translateCurrentLocale();
  }

  /// Traduit catégorie + ingrédients de chaque pizza vers la langue
  /// actuellement affichée, à partir de la liste française brute
  /// `_allPizzasRaw`. Ne fait rien si on a déjà traduit pour cette langue.
  ///
  /// Les noms de pizzas ne sont JAMAIS traduits : ce sont des noms de marque
  /// ("La Casita Spéciale"...) qu'une traduction mot-à-mot dénaturerait. Les
  /// menus multilingues gardent en général le nom du produit tel quel et ne
  /// traduisent que la catégorie et les ingrédients — c'est ce choix qui est
  /// fait ici.
  Future<void> _translateCurrentLocale() async {
    if (_allPizzasRaw.isEmpty) return;

    final String lang = AppLocalizations.of(context)!.languageCode;
    if (lang == _translatedForLocale) return;
    _translatedForLocale = lang;

    if (lang == 'fr') {
      setState(() {
        _allPizzas = _allPizzasRaw;
        _filteredPizzas = _applyFilters(_allPizzas);
      });
      return;
    }

    // On ne traduit qu'une fois chaque texte distinct : un ingrédient
    // partagé par dix pizzas (ex. "Tomates") n'est envoyé qu'une seule fois
    // à l'API, ce qui économise le quota gratuit de MyMemory. Le cache
    // interne au service évite ensuite tout appel réseau si ce texte a déjà
    // été traduit lors d'un lancement précédent et n'a pas changé côté
    // Google Sheet.
    final Set<String> distinctTexts = {};
    for (final pizza in _allPizzasRaw) {
      distinctTexts.add(pizza.category);
      distinctTexts.addAll(pizza.ingredients);
    }

    final Map<String, String> translations = {};
    await Future.wait(distinctTexts.map((text) async {
      translations[text] =
          await TranslationService.instance.translate(text, lang);
    }));

    // La langue a pu changer à nouveau pendant qu'on attendait le réseau
    // (l'utilisateur a tapé vite sur le sélecteur) : dans ce cas on
    // abandonne ce résultat devenu obsolète, une traduction plus récente est
    // déjà en cours.
    if (!mounted || _translatedForLocale != lang) return;

    final List<Pizza> translatedPizzas = _allPizzasRaw.map((pizza) {
      return Pizza(
        id: pizza.id,
        name: pizza.name, // nom de marque : jamais traduit
        category: translations[pizza.category] ?? pizza.category,
        ingredients:
            pizza.ingredients.map((ing) => translations[ing] ?? ing).toList(),
        price: pizza.price,
        imageUrl: pizza.imageUrl,
        selectedSupplements: pizza.selectedSupplements,
      );
    }).toList();

    setState(() {
      _allPizzas = translatedPizzas;
      _filteredPizzas = _applyFilters(translatedPizzas);
    });
  }

  /// Écoute en temps réel le document parent pour récupérer :
  /// - le numéro de téléphone (`phone`)
  /// - l'éventuel override manuel du statut ouvert/fermé (`manualOverride`) ;
  ///   s'il est absent (null), le statut suit l'horaire fixe calculé
  ///   localement dans `_buildOpeningStatus`.
  /// - le message exceptionnel actif (`exceptionalMessage` / `exceptionalMessageType`)
  /// Tout ça est piloté depuis l'app Maître.
  void _startRestaurantConfigListener() {
    _restaurantConfigSubscription = FirebaseFirestore.instance
        .doc("users/$_parentDocId")
        .snapshots()
        .listen(
      (snapshot) {
        if (!mounted) return;
        final data = snapshot.data();
        if (data == null) return;

        final phone = data['phone'] as String?;
        final manualOverride = data['manualOverride'] as bool?;
        final manualOverrideSetAtTs =
            data['manualOverrideSetAt'] as Timestamp?;
        final messageType = data['exceptionalMessageType'] as String?;
        final message = data['exceptionalMessage'] as String?;

        setState(() {
          if (phone != null && phone.trim().isNotEmpty) {
            _phoneNumber = phone.trim();
          }
          _manualOverride = manualOverride;
          _manualOverrideSetAt = manualOverrideSetAtTs?.toDate();
          final bool hasActiveMessage = messageType != null &&
              messageType != 'none' &&
              message != null &&
              message.trim().isNotEmpty;
          final String? newMessage = hasActiveMessage ? message.trim() : null;
          // Si le gérant envoie un NOUVEAU message, on ré-affiche la bannière
          // même si le client avait masqué le précédent.
          if (newMessage != _exceptionalMessage) {
            _exceptionalMessageDismissedLocally = false;
          }
          _exceptionalMessage = newMessage;
        });
      },
      onError: (error) {
        debugPrint("Erreur écoute config restaurant : $error");
      },
    );
  }

  /// Nettoie un numéro saisi librement par le gérant (espaces, tirets,
  /// éventuel "0" initial) pour produire un format exploitable par `tel:`
  /// et par WhatsApp (ex : "06 12 34 56 78" -> "+33612345678").
  String _sanitizePhoneForUri(String raw) {
    String digits = raw.replaceAll(RegExp(r'[\s\.\-]'), '');
    if (digits.startsWith('0')) {
      digits = '+33${digits.substring(1)}';
    }
    return digits;
  }

  Future<void> _makePhoneCall() async {
    final Uri phoneUri = Uri(
      scheme: 'tel',
      path: _sanitizePhoneForUri(_phoneNumber),
    );
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  Widget _buildOpeningStatus(AppLocalizations t) {
    final now = DateTime.now();

    final int weekday = now.weekday;
    final int minutesNow = now.hour * 60 + now.minute;

    const int openMinutes = 18 * 60 + 30;
    const int fridaySaturdayCloseMinutes = 21 * 60;
    const int sundayCloseMinutes = 20 * 60 + 30;

    bool scheduleIsOpen = false;
    final String openingText = t.openingScheduleText;

    if ((weekday == DateTime.friday || weekday == DateTime.saturday) &&
        minutesNow >= openMinutes &&
        minutesNow < fridaySaturdayCloseMinutes) {
      scheduleIsOpen = true;
    }

    if (weekday == DateTime.sunday &&
        minutesNow >= openMinutes &&
        minutesNow < sundayCloseMinutes) {
      scheduleIsOpen = true;
    }

    // L'override manuel de l'app Maître (`manualOverride`) prime toujours sur
    // l'horaire fixe ci-dessus : c'est ce qui permet au gérant de fermer
    // manuellement même pendant un créneau normalement ouvert (ou
    // l'inverse). Tant qu'aucun override n'est actif, le statut suit
    // l'horaire, recalculé en continu ici — donc toujours à jour même si
    // l'app Maître reste fermée pendant des heures.
    //
    // Sécurité anti-oubli : un override "forcé ouvert" resté actif après
    // 21h (heure de fermeture) est ignoré, pour ne pas afficher le
    // restaurant ouvert toute la nuit si le gérant a oublié de repasser en
    // automatique. Un override "forcé fermé", lui, n'expire jamais tout
    // seul : fermer exceptionnellement ne doit jamais se rouvrir sans
    // action du gérant.
    // Sécurité anti-oubli : un override "forcé ouvert" resté actif au-delà
    // du prochain 21h suivant SON ACTIVATION (pas juste "il est 21h passé")
    // est ignoré — donc un override activé à 23h30 reste bien valide
    // jusqu'au 21h du lendemain, il n'est jamais ignoré immédiatement sous
    // prétexte qu'il est tard. Un override "forcé fermé", lui, n'expire
    // jamais tout seul : fermer exceptionnellement ne doit jamais se
    // rouvrir sans action du gérant.
    bool? effectiveOverride = _manualOverride;
    if (effectiveOverride == true) {
      final setAt = _manualOverrideSetAt;
      DateTime nextReset;
      if (setAt == null) {
        // Pas d'horodatage connu (anciennes données) : on retombe sur
        // l'ancienne règle par sécurité.
        nextReset = DateTime(now.year, now.month, now.day, 21, 0);
      } else {
        nextReset = DateTime(setAt.year, setAt.month, setAt.day, 21, 0);
        if (!setAt.isBefore(nextReset)) {
          nextReset = nextReset.add(const Duration(days: 1));
        }
      }
      if (!now.isBefore(nextReset)) {
        effectiveOverride = null;
      }
    }
    final bool isOpen = effectiveOverride ?? scheduleIsOpen;

    // Ouverture/fermeture "exceptionnelle" = un override manuel actif qui
    // contredit l'horaire habituel (ouvert un jour normalement fermé, ou
    // fermé pendant un créneau normalement ouvert). Dans ce cas, afficher
    // les horaires habituels en dessous serait trompeur — on affiche plutôt
    // un texte dédié.
    final bool isExceptional =
        effectiveOverride != null && effectiveOverride != scheduleIsOpen;

    final String subtitleText = isExceptional
        ? (isOpen ? t.exceptionalOpenText : t.exceptionalClosedText)
        : openingText;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isOpen ? Colors.green.shade50 : Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isOpen ? Colors.green : Colors.red,
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              isExceptional ? Icons.star : Icons.circle,
              size: isExceptional ? 14 : 10,
              color: isOpen ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isOpen ? t.openNow : t.closedNow,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color:
                          isOpen ? Colors.green.shade800 : Colors.red.shade800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitleText,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          isExceptional ? FontWeight.bold : FontWeight.normal,
                      color: isExceptional
                          ? (isOpen ? Colors.green.shade800 : Colors.red.shade800)
                          : Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _fetchPizzas() async {
    final Uri url = Uri.parse(
      'https://docs.google.com/spreadsheets/d/e/2PACX-1vQGNPINjsEFyWSYpCCjK9wneSvhhSgA6Ww1krcTzUUT7Oyz6pXK5lvEkMBMVfmxf2ymLu5VNBDlQa4g/pub?gid=0&single=true&output=tsv',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final csvRawText = utf8.decode(response.bodyBytes);
        final List<String> lines = csvRawText.split(RegExp(r'\r?\n'));
        final List<Pizza> loadedPizzas = [];

        for (int i = 1; i < lines.length; i++) {
          final String line = lines[i].trim();
          if (line.isEmpty) continue;

          final List<String> columns = line.split('\t');

          if (columns.length >= 4) {
            final String name = columns[0].trim().replaceAll('"', '');
            if (name.isEmpty) continue;

            final String category = columns[1].trim().replaceAll('"', '');

            final String rawIngredients = columns[2].trim().replaceAll('"', '');
            final List<String> ingredients = rawIngredients
                .split(',')
                .map((ing) => ing.trim())
                .where((ing) => ing.isNotEmpty)
                .toList();

            String rawPrice = columns[3].trim().replaceAll('"', '');
            rawPrice = rawPrice
                .replaceAll('€', '')
                .replaceAll(',', '.')
                .replaceAll(RegExp(r'\s+'), '')
                .trim();

            final double price = double.tryParse(rawPrice) ?? 0.0;

            loadedPizzas.add(
              Pizza(
                id: i.toString(),
                name: name,
                category: category,
                ingredients: ingredients,
                price: price,
                imageUrl:
                    'https://pizzaslacasita.fr/assets/pizza_placeholder.png',
              ),
            );
          }
        }

        setState(() {
          _allPizzasRaw = loadedPizzas;
          // En attendant la traduction (qui se fait de façon asynchrone),
          // on affiche tout de suite la version française : jamais d'écran
          // vide ou de blocage le temps que l'API MyMemory réponde.
          _allPizzas = loadedPizzas;
          _filteredPizzas = _applyFilters(loadedPizzas);
          _isLoading = false;
          _errorMessage = "";
        });
        // Force une nouvelle tentative de traduction même si on avait déjà
        // traduit pour cette langue (ex. rafraîchissement manuel) : les
        // données du Google Sheet ont pu changer.
        _translatedForLocale = null;
        _translateCurrentLocale();
      } else {
        setState(() {
          _errorMessage =
              AppLocalizations.of(context)!.syncErrorCode(response.statusCode);
          _isLoading = false;
        });
      }
    } catch (error) {
      setState(() {
        _errorMessage = AppLocalizations.of(context)!.connectionError;
        _isLoading = false;
      });
    }
  }

  void _filterPizzas(String query) {
    setState(() {
      _searchQuery = query;
      _filteredPizzas = _applyFilters(_allPizzas);
    });
  }

  void _selectCategory(String? key) {
    setState(() {
      _selectedCategoryKey = key;
      _filteredPizzas = _applyFilters(_allPizzas);
    });
  }

  /// Combine le filtre texte (recherche) et le filtre catégorie (chips).
  /// La comparaison de catégorie se fait toujours sur la valeur BRUTE
  /// française (via `_rawCategoryForId`), pas sur `pizza.category` qui peut
  /// être traduit à l'affichage.
  List<Pizza> _applyFilters(List<Pizza> pizzas) {
    Iterable<Pizza> result = pizzas;

    final String? categoryKey = _selectedCategoryKey;
    if (categoryKey != null) {
      result = result.where((pizza) =>
          _normalizeCategory(_rawCategoryForId(pizza.id)) ==
          _normalizeCategory(categoryKey));
    }

    final String query = _searchQuery;
    if (query.isNotEmpty) {
      result = result.where((pizza) {
        final nameMatch =
            pizza.name.toLowerCase().contains(query.toLowerCase());
        final ingredientMatch = pizza.ingredients.any(
          (ing) => ing.toLowerCase().contains(query.toLowerCase()),
        );
        final categoryMatch =
            pizza.category.toLowerCase().contains(query.toLowerCase());
        return nameMatch || ingredientMatch || categoryMatch;
      });
    }

    return result.toList();
  }

  void _showSupplementDialog(
      BuildContext context, Pizza pizza, CartProvider cart) {
    final t = AppLocalizations.of(context)!;
    List<String> selectedSupplements = [];
    double supplementPrice = 1.50;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(t.customizeYourPizza(pizza.name)),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      t.baseIngredients,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      pizza.ingredients.join(', '),
                      style: const TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                      ),
                    ),
                    const Divider(height: 25),
                    Text(
                      t.addSupplement,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    ..._availableSupplements.map((supplement) {
                      final bool alreadyHasIt = pizza.ingredients.any(
                        (ing) => ing.toLowerCase() == supplement.toLowerCase(),
                      );
                      final String displayName = t.supplementName(supplement);

                      return CheckboxListTile(
                        title: Text(
                          alreadyHasIt
                              ? "$displayName ${t.alreadyIncluded}"
                              : displayName,
                        ),
                        value: selectedSupplements.contains(supplement),
                        activeColor: _pinkPrimary,
                        onChanged: (bool? checked) {
                          setDialogState(() {
                            if (checked == true) {
                              selectedSupplements.add(supplement);
                            } else {
                              selectedSupplements.remove(supplement);
                            }
                          });
                        },
                      );
                    }),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(
                    t.cancel,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _pinkPrimary,
                  ),
                  onPressed: () {
                    double finalPrice =
                        pizza.price + (selectedSupplements.length * supplementPrice);

                    final customizedPizza = pizza.copyWith(
                      selectedSupplements: selectedSupplements,
                      price: finalPrice,
                    );

                    cart.addItem(customizedPizza);

                    // Le client vient de trouver sa pizza via la recherche :
                    // on réaffiche la liste complète pour qu'il puisse
                    // continuer à parcourir le menu sans devoir re-effacer
                    // sa recherche lui-même.
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                      _filteredPizzas = _applyFilters(_allPizzas);
                    });

                    Navigator.of(dialogContext).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          selectedSupplements.isNotEmpty
                              ? t.pizzaAddedWithSupplements(pizza.name)
                              : t.pizzaAdded(pizza.name),
                        ),
                        duration: const Duration(seconds: 2),
                        backgroundColor: _pinkPrimary,
                      ),
                    );
                  },
                  child: Text(
                    t.addToCart,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Retrouve la catégorie brute (en français, telle que dans le Google
  /// Sheet) d'une pizza à partir de son id. Nécessaire car `pizza.category`
  /// peut être traduit pour l'affichage, alors que `_getCategoryColor`
  /// doit continuer à comparer des valeurs françaises ('tomate', 'crème',
  /// 'mixte'), quelle que soit la langue affichée.
  String _rawCategoryForId(String id) {
    for (final raw in _allPizzasRaw) {
      if (raw.id == id) return raw.category;
    }
    return '';
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'tomate':
        return Colors.red.shade700;
      case 'crème':
      case 'creme':
        return Colors.amber.shade600;
      case 'mixte':
        return Colors.orange.shade800;
      case 'boissons':
        return Colors.blue.shade700;
      case 'calzone':
        return Colors.brown.shade600;
      default:
        return Colors.blueGrey;
    }
  }

  Widget _buildCategoryChip(String? key) {
    final String lang = AppLocalizations.of(context)!.languageCode;
    final bool selected = _selectedCategoryKey == key;
    final String label = _categoryLabel(key ?? 'all', lang);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => _selectCategory(key),
        selectedColor: _pinkPrimary,
        labelStyle: TextStyle(
          color: selected ? Colors.white : Colors.black87,
          fontWeight: FontWeight.w600,
        ),
        backgroundColor: Colors.white,
        side: BorderSide(color: _pinkPrimary.withValues(alpha: 0.4)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'La Casita',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: _pinkPrimary,
        actions: [
          const LanguageSelectorButton(),
          IconButton(
            icon: const Icon(Icons.phone, color: Colors.white),
            tooltip: t.callTooltip,
            onPressed: _makePhoneCall,
          ),
          IconButton(
            icon: const Icon(Icons.badge, color: Colors.white),
            tooltip: t.fidelityTooltip,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const FidelityScreen()),
            ),
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart, color: Colors.white),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CartScreen()),
                ),
              ),
              if (cart.itemCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: CircleAvatar(
                    radius: 8,
                    backgroundColor: Colors.red,
                    child: Text(
                      '${cart.itemCount}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                      ),
                    ),
                  ),
                )
            ],
          )
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: _pinkPrimary),
            )
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                      _errorMessage,
                      style: const TextStyle(color: Colors.red, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : Column(
                  children: [
                    _buildOpeningStatus(t),
                    if (_exceptionalMessage != null &&
                        _exceptionalMessage!.isNotEmpty &&
                        !_exceptionalMessageDismissedLocally)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          color: _pinkPrimary,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star, color: Colors.white),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _exceptionalMessage!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => setState(() {
                                _exceptionalMessageDismissedLocally = true;
                              }),
                              icon:
                                  const Icon(Icons.close, color: Colors.white),
                              tooltip: t.hideExceptionalOpening,
                            ),
                          ],
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: TextField(
                        controller: _searchController,
                        onChanged: _filterPizzas,
                        decoration: InputDecoration(
                          labelText: t.searchHint,
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  tooltip: t.cancel,
                                  onPressed: () {
                                    _searchController.clear();
                                    _filterPizzas('');
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: const BorderSide(color: _pinkPrimary),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 40,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        children: [
                          _buildCategoryChip(null),
                          for (final key in _filterCategoryKeys)
                            _buildCategoryChip(key),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Expanded(
                      child: _filteredPizzas.isEmpty
                          ? Center(
                              child: Text(
                                t.noPizzaMatch,
                              ),
                            )
                          : ListView.builder(
                              itemCount: _filteredPizzas.length,
                              itemBuilder: (ctx, i) {
                                final pizza = _filteredPizzas[i];
                                return Card(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8.0,
                                    ),
                                    child: ListTile(
                                      title: Row(
                                        children: [
                                          Text(
                                            pizza.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _getCategoryColor(
                                                _rawCategoryForId(pizza.id),
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              pizza.category.toUpperCase(),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      subtitle: Padding(
                                        padding:
                                            const EdgeInsets.only(top: 4.0),
                                        child:
                                            Text(pizza.ingredients.join(', ')),
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            '${pizza.price.toStringAsFixed(2)} €',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.add_shopping_cart,
                                              color: _pinkPrimary,
                                            ),
                                            onPressed: () =>
                                                _showSupplementDialog(
                                              context,
                                              pizza,
                                              cart,
                                            ),
                                          )
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
    );
  }
}
