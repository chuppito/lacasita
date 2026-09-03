import 'package:flutter/material.dart';

/// Système de traduction "fait main" pour La Casita.
///
/// Volontairement écrit sans `flutter gen-l10n` (pas de fichiers .arb, pas de
/// build_runner) : une seule classe Dart normale, donc aucune étape de
/// régénération à refaire à chaque changement de texte. Il suffit d'ajouter
/// une clé dans `_localizedValues` puis un getter/méthode ci-dessous.
class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  /// Langues disponibles dans l'application.
  static const List<Locale> supportedLocales = [
    Locale('fr'),
    Locale('en'),
    Locale('it'),
    Locale('es'),
    Locale('de'),
    Locale('pl'),
    Locale('nl'),
  ];

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// Nom affiché de chaque langue, dans sa propre langue (pour le sélecteur).
  static const Map<String, String> displayNames = {
    'fr': 'Français',
    'en': 'English',
    'it': 'Italiano',
    'es': 'Español',
    'de': 'Deutsch',
    'pl': 'Polski',
    'nl': 'Nederlands',
  };

  static const Map<String, String> flagEmojis = {
    'fr': '🇫🇷',
    'en': '🇬🇧',
    'it': '🇮🇹',
    'es': '🇪🇸',
    'de': '🇩🇪',
    'pl': '🇵🇱',
    'nl': '🇳🇱',
  };

  String get languageCode => locale.languageCode;

  String _t(String key) {
    final lang = locale.languageCode;
    return _localizedValues[lang]?[key] ?? _localizedValues['fr']![key] ?? key;
  }

  String _tFmt(String key, Map<String, String> params) {
    var text = _t(key);
    params.forEach((k, v) {
      text = text.replaceAll('{$k}', v);
    });
    return text;
  }

  // ---------------------------------------------------------------------
  // Général / sélecteur de langue
  // ---------------------------------------------------------------------
  String get chooseLanguage => _t('chooseLanguage');
  String get systemLanguage => _t('systemLanguage');

  // ---------------------------------------------------------------------
  // Home screen
  // ---------------------------------------------------------------------
  String get callTooltip => _t('callTooltip');
  String get openingScheduleText => _t('openingScheduleText');
  String get openNow => _t('openNow');
  String get closedNow => _t('closedNow');
  String get exceptionalOpenText => _t('exceptionalOpenText');
  String get exceptionalClosedText => _t('exceptionalClosedText');
  String syncErrorCode(int code) => _tFmt('syncErrorCode', {'code': '$code'});
  String get connectionError => _t('connectionError');
  String get hideExceptionalOpening => _t('hideExceptionalOpening');
  String get searchHint => _t('searchHint');
  String get noPizzaMatch => _t('noPizzaMatch');
  String customizeYourPizza(String name) =>
      _tFmt('customizeYourPizza', {'name': name});
  String get baseIngredients => _t('baseIngredients');
  String get addSupplement => _t('addSupplement');
  String get alreadyIncluded => _t('alreadyIncluded');
  String get cancel => _t('cancel');
  String get addToCart => _t('addToCart');
  String pizzaAddedWithSupplements(String name) =>
      _tFmt('pizzaAddedWithSupplements', {'name': name});
  String pizzaAdded(String name) => _tFmt('pizzaAdded', {'name': name});
  String get fidelityTooltip => _t('fidelityTooltip');

  /// Traduit le nom d'un supplément (les valeurs stockées côté app restent en
  /// français car elles doivent correspondre aux ingrédients venant du
  /// tableur Google Sheets, qui lui reste en français).
  String supplementName(String frenchName) {
    final lang = locale.languageCode;
    return _supplements[lang]?[frenchName] ?? frenchName;
  }

  // ---------------------------------------------------------------------
  // Cart screen
  // ---------------------------------------------------------------------
  String get myCart => _t('myCart');
  String get clearCartTooltip => _t('clearCartTooltip');
  String get callTooltipShort => _t('callTooltipShort');
  String get cannotMakeCall => _t('cannotMakeCall');
  String get whatsappGreeting => _t('whatsappGreeting');
  String get whatsappSupplements => _t('whatsappSupplements');
  String get whatsappTotal => _t('whatsappTotal');
  String get whatsappPickupTime => _t('whatsappPickupTime');
  String get cannotOpenWhatsapp => _t('cannotOpenWhatsapp');
  String get clearCartTitle => _t('clearCartTitle');
  String get clearCartConfirm => _t('clearCartConfirm');
  String get clear => _t('clear');
  String get cartAlreadyEmpty => _t('cartAlreadyEmpty');
  String get cartCleared => _t('cartCleared');
  String get cartEmptyShort => _t('cartEmptyShort');
  String get favoriteOrderSaved => _t('favoriteOrderSaved');
  String get noFavoriteOrderSaved => _t('noFavoriteOrderSaved');
  String get favoriteOrderLoaded => _t('favoriteOrderLoaded');
  String get noLastOrderSaved => _t('noLastOrderSaved');
  String get lastOrderLoaded => _t('lastOrderLoaded');
  String get yourCartEmpty => _t('yourCartEmpty');
  String get baseLabel => _t('baseLabel');
  String get supplementsLabel => _t('supplementsLabel');
  String get quantityLabel => _t('quantityLabel');
  String get totalLabel => _t('totalLabel');
  String get saveButton => _t('saveButton');
  String get usualButton => _t('usualButton');
  String get lastButton => _t('lastButton');
  String get whatsappButton => _t('whatsappButton');

  // ---------------------------------------------------------------------
  // Fidelity screen
  // ---------------------------------------------------------------------
  String get myLoyalty => _t('myLoyalty');
  String get unlinkCardTooltip => _t('unlinkCardTooltip');
  String get cardNotFound => _t('cardNotFound');
  String get defaultCustomer => _t('defaultCustomer');
  String get customerNotFound => _t('customerNotFound');
  String get accessDenied => _t('accessDenied');
  String get networkError => _t('networkError');
  String get syncError => _t('syncError');
  String get scanError => _t('scanError');
  String get pizzasCardTitle => _t('pizzasCardTitle');
  String get cardBalance => _t('cardBalance');
  String pizzasCount(int current, int target) =>
      _tFmt('pizzasCount', {'current': '$current', 'target': '$target'});
  String get congratsRewardAvailable => _t('congratsRewardAvailable');
  String remainingPizzas(int remaining) =>
      _tFmt('remainingPizzas', {'remaining': '$remaining'});
  String get loyaltyOffer => _t('loyaltyOffer');
  String get retry => _t('retry');
  String get officialQrCode => _t('officialQrCode');
  String get activateCardTitle => _t('activateCardTitle');
  String get activateCardSubtitle => _t('activateCardSubtitle');
  String get scanQrButton => _t('scanQrButton');
  String get enterCodeManually => _t('enterCodeManually');
  String get enterIdDialogTitle => _t('enterIdDialogTitle');
  String get enterIdDialogBody => _t('enterIdDialogBody');
  String get idFieldLabel => _t('idFieldLabel');
  String get validate => _t('validate');
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => AppLocalizations.supportedLocales
      .any((supported) => supported.languageCode == locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

// ===========================================================================
// Traductions
// ===========================================================================

const Map<String, Map<String, String>> _localizedValues = {
  'fr': {
    'chooseLanguage': 'Choisir la langue',
    'systemLanguage': 'Langue du téléphone',
    'callTooltip': 'Appeler La Casita',
    'openingScheduleText':
        'Ouverture : vendredi et samedi 18h30 à 21h00, dimanche 18h30 à 20h30',
    'openNow': 'Ouvert actuellement',
    'closedNow': 'Fermé actuellement',
    'exceptionalOpenText': 'Ouverture exceptionnelle aujourd\'hui',
    'exceptionalClosedText': 'Fermeture exceptionnelle aujourd\'hui',
    'syncErrorCode': 'Erreur de synchronisation (Code: {code})',
    'connectionError': 'Erreur de connexion. Impossible de charger le menu.',
    'hideExceptionalOpening': "Masquer l'ouverture exceptionnelle",
    'searchHint': 'Rechercher une pizza, un ingrédient ou une base...',
    'noPizzaMatch': 'Aucune pizza ne correspond à vos critères.',
    'customizeYourPizza': 'Personnaliser votre {name}',
    'baseIngredients': 'Ingrédients de base :',
    'addSupplement': 'Ajouter un supplément (+1.50€) :',
    'alreadyIncluded': '(Déjà inclus)',
    'cancel': 'Annuler',
    'addToCart': 'Ajouter au panier',
    'pizzaAddedWithSupplements': '{name} ajoutée ! (avec suppléments)',
    'pizzaAdded': '{name} ajoutée !',
    'fidelityTooltip': 'Ma fidélité',
    'myCart': 'Mon Panier',
    'clearCartTooltip': 'Vider le panier',
    'callTooltipShort': 'Appeler',
    'cannotMakeCall': "Impossible de lancer l'appel.",
    'whatsappGreeting': 'Bonjour La Casita ! Voici ma commande :',
    'whatsappSupplements': 'Suppléments',
    'whatsappTotal': 'Total',
    'whatsappPickupTime':
        'Pour quelle heure puis-je passer retirer ma commande SVP ?',
    'cannotOpenWhatsapp': "Impossible d'ouvrir WhatsApp.",
    'clearCartTitle': 'Vider le panier',
    'clearCartConfirm':
        'Voulez-vous vraiment supprimer tous les articles du panier ?',
    'clear': 'Vider',
    'cartAlreadyEmpty': 'Le panier est déjà vide.',
    'cartCleared': 'Panier vidé.',
    'cartEmptyShort': 'Le panier est vide.',
    'favoriteOrderSaved': 'Commande habituelle enregistrée.',
    'noFavoriteOrderSaved': 'Aucune commande habituelle enregistrée.',
    'favoriteOrderLoaded': 'Commande habituelle chargée.',
    'noLastOrderSaved': 'Aucune dernière commande enregistrée.',
    'lastOrderLoaded': 'Dernière commande chargée.',
    'yourCartEmpty': 'Votre panier est vide.',
    'baseLabel': 'Base',
    'supplementsLabel': 'Suppléments',
    'quantityLabel': 'Quantité',
    'totalLabel': 'Total',
    'saveButton': 'Enregistrer',
    'usualButton': 'Habituelle',
    'lastButton': 'Dernière',
    'whatsappButton': 'WhatsApp',
    'myLoyalty': 'Ma Fidélité',
    'unlinkCardTooltip': 'Déconnecter la carte',
    'cardNotFound': 'Carte introuvable',
    'defaultCustomer': 'Client',
    'customerNotFound': 'Client introuvable',
    'accessDenied': 'Accès refusé',
    'networkError': 'Erreur réseau',
    'syncError': 'Erreur de synchronisation',
    'scanError': 'Erreur lors du scan',
    'pizzasCardTitle': 'PIZZAS LA CASITA',
    'cardBalance': 'SOLDE DE VOTRE CARTE',
    'pizzasCount': '{current} / {target} Pizzas',
    'congratsRewardAvailable':
        'FÉLICITATIONS ! VOTRE RÉCOMPENSE EST DISPONIBLE !',
    'remainingPizzas': 'PLUS QUE {remaining} PIZZAS AVANT LA GRATUITE',
    'loyaltyOffer': 'Offre Fidélité',
    'retry': 'Réessayer',
    'officialQrCode': 'Votre QR code officiel de fidélité :',
    'activateCardTitle': 'Activez votre carte La Casita',
    'activateCardSubtitle':
        'Scannez le QR Code de votre application de fidélité pour synchroniser vos points et votre carte en temps réel.',
    'scanQrButton': 'Scanner mon QR Code',
    'enterCodeManually': 'Entrer mon code reçu par SMS/WhatsApp',
    'enterIdDialogTitle': 'Entrer mon identifiant',
    'enterIdDialogBody':
        'Collez ou écrivez le code que la Casita a envoyé (ex : PIZZA:0000000000000000).',
    'idFieldLabel': 'Identifiant',
    'validate': 'Valider',
  },
  'en': {
    'chooseLanguage': 'Choose language',
    'systemLanguage': 'Phone language',
    'callTooltip': 'Call La Casita',
    'openingScheduleText':
        'Open: Friday and Saturday 6:30pm to 9:00pm, Sunday 6:30pm to 8:30pm',
    'openNow': 'Currently open',
    'closedNow': 'Currently closed',
    'exceptionalOpenText': 'Exceptionally open today',
    'exceptionalClosedText': 'Exceptionally closed today',
    'syncErrorCode': 'Sync error (Code: {code})',
    'connectionError': 'Connection error. Unable to load the menu.',
    'hideExceptionalOpening': 'Hide exceptional opening notice',
    'searchHint': 'Search for a pizza, an ingredient or a base...',
    'noPizzaMatch': 'No pizza matches your search.',
    'customizeYourPizza': 'Customize your {name}',
    'baseIngredients': 'Base ingredients:',
    'addSupplement': 'Add a topping (+€1.50):',
    'alreadyIncluded': '(Already included)',
    'cancel': 'Cancel',
    'addToCart': 'Add to cart',
    'pizzaAddedWithSupplements': '{name} added! (with extra toppings)',
    'pizzaAdded': '{name} added!',
    'fidelityTooltip': 'My loyalty card',
    'myCart': 'My Cart',
    'clearCartTooltip': 'Empty cart',
    'callTooltipShort': 'Call',
    'cannotMakeCall': 'Unable to place the call.',
    'whatsappGreeting': 'Hello La Casita! Here is my order:',
    'whatsappSupplements': 'Extra toppings',
    'whatsappTotal': 'Total',
    'whatsappPickupTime': 'What time can I come and pick up my order please?',
    'cannotOpenWhatsapp': 'Unable to open WhatsApp.',
    'clearCartTitle': 'Empty cart',
    'clearCartConfirm':
        'Are you sure you want to remove all items from the cart?',
    'clear': 'Empty',
    'cartAlreadyEmpty': 'The cart is already empty.',
    'cartCleared': 'Cart emptied.',
    'cartEmptyShort': 'The cart is empty.',
    'favoriteOrderSaved': 'Usual order saved.',
    'noFavoriteOrderSaved': 'No usual order saved.',
    'favoriteOrderLoaded': 'Usual order loaded.',
    'noLastOrderSaved': 'No last order saved.',
    'lastOrderLoaded': 'Last order loaded.',
    'yourCartEmpty': 'Your cart is empty.',
    'baseLabel': 'Base',
    'supplementsLabel': 'Extra toppings',
    'quantityLabel': 'Quantity',
    'totalLabel': 'Total',
    'saveButton': 'Save',
    'usualButton': 'Usual',
    'lastButton': 'Last',
    'whatsappButton': 'WhatsApp',
    'myLoyalty': 'My Loyalty',
    'unlinkCardTooltip': 'Unlink card',
    'cardNotFound': 'Card not found',
    'defaultCustomer': 'Customer',
    'customerNotFound': 'Customer not found',
    'accessDenied': 'Access denied',
    'networkError': 'Network error',
    'syncError': 'Sync error',
    'scanError': 'Scan error',
    'pizzasCardTitle': 'LA CASITA PIZZAS',
    'cardBalance': 'YOUR CARD BALANCE',
    'pizzasCount': '{current} / {target} Pizzas',
    'congratsRewardAvailable': 'CONGRATULATIONS! YOUR REWARD IS READY!',
    'remainingPizzas': '{remaining} MORE PIZZAS TO GET A FREE ONE',
    'loyaltyOffer': 'Loyalty Offer',
    'retry': 'Retry',
    'officialQrCode': 'Your official loyalty QR code:',
    'activateCardTitle': 'Activate your La Casita card',
    'activateCardSubtitle':
        'Scan your loyalty app QR code to sync your points and your card in real time.',
    'scanQrButton': 'Scan my QR Code',
    'enterCodeManually': 'Enter the code I received by SMS/WhatsApp',
    'enterIdDialogTitle': 'Enter my ID',
    'enterIdDialogBody':
        'Paste or type the code sent by La Casita (e.g.: PIZZA:0000000000000000).',
    'idFieldLabel': 'ID',
    'validate': 'Confirm',
  },
  'it': {
    'chooseLanguage': 'Scegli la lingua',
    'systemLanguage': 'Lingua del telefono',
    'callTooltip': 'Chiama La Casita',
    'openingScheduleText':
        'Apertura: venerdì e sabato dalle 18:30 alle 21:00, domenica dalle 18:30 alle 20:30',
    'openNow': 'Attualmente aperto',
    'closedNow': 'Attualmente chiuso',
    'exceptionalOpenText': 'Eccezionalmente aperto oggi',
    'exceptionalClosedText': 'Eccezionalmente chiuso oggi',
    'syncErrorCode': 'Errore di sincronizzazione (Codice: {code})',
    'connectionError': 'Errore di connessione. Impossibile caricare il menu.',
    'hideExceptionalOpening': "Nascondi l'apertura eccezionale",
    'searchHint': 'Cerca una pizza, un ingrediente o una base...',
    'noPizzaMatch': 'Nessuna pizza corrisponde ai tuoi criteri.',
    'customizeYourPizza': 'Personalizza la tua {name}',
    'baseIngredients': 'Ingredienti di base:',
    'addSupplement': 'Aggiungi un ingrediente extra (+1,50€):',
    'alreadyIncluded': '(Già incluso)',
    'cancel': 'Annulla',
    'addToCart': 'Aggiungi al carrello',
    'pizzaAddedWithSupplements': '{name} aggiunta! (con ingredienti extra)',
    'pizzaAdded': '{name} aggiunta!',
    'fidelityTooltip': 'La mia fidelity card',
    'myCart': 'Il Mio Carrello',
    'clearCartTooltip': 'Svuota il carrello',
    'callTooltipShort': 'Chiama',
    'cannotMakeCall': 'Impossibile effettuare la chiamata.',
    'whatsappGreeting': 'Ciao La Casita! Ecco il mio ordine:',
    'whatsappSupplements': 'Ingredienti extra',
    'whatsappTotal': 'Totale',
    'whatsappPickupTime': 'A che ora posso venire a ritirare il mio ordine?',
    'cannotOpenWhatsapp': 'Impossibile aprire WhatsApp.',
    'clearCartTitle': 'Svuota il carrello',
    'clearCartConfirm':
        'Vuoi davvero rimuovere tutti gli articoli dal carrello?',
    'clear': 'Svuota',
    'cartAlreadyEmpty': 'Il carrello è già vuoto.',
    'cartCleared': 'Carrello svuotato.',
    'cartEmptyShort': 'Il carrello è vuoto.',
    'favoriteOrderSaved': 'Ordine abituale salvato.',
    'noFavoriteOrderSaved': 'Nessun ordine abituale salvato.',
    'favoriteOrderLoaded': 'Ordine abituale caricato.',
    'noLastOrderSaved': 'Nessun ultimo ordine salvato.',
    'lastOrderLoaded': 'Ultimo ordine caricato.',
    'yourCartEmpty': 'Il tuo carrello è vuoto.',
    'baseLabel': 'Base',
    'supplementsLabel': 'Ingredienti extra',
    'quantityLabel': 'Quantità',
    'totalLabel': 'Totale',
    'saveButton': 'Salva',
    'usualButton': 'Abituale',
    'lastButton': 'Ultimo',
    'whatsappButton': 'WhatsApp',
    'myLoyalty': 'La Mia Fidelity',
    'unlinkCardTooltip': 'Scollega la carta',
    'cardNotFound': 'Carta non trovata',
    'defaultCustomer': 'Cliente',
    'customerNotFound': 'Cliente non trovato',
    'accessDenied': 'Accesso negato',
    'networkError': 'Errore di rete',
    'syncError': 'Errore di sincronizzazione',
    'scanError': 'Errore durante la scansione',
    'pizzasCardTitle': 'PIZZE LA CASITA',
    'cardBalance': 'SALDO DELLA TUA CARTA',
    'pizzasCount': '{current} / {target} Pizze',
    'congratsRewardAvailable': 'COMPLIMENTI! LA TUA RICOMPENSA È DISPONIBILE!',
    'remainingPizzas': 'ANCORA {remaining} PIZZE PRIMA DI QUELLA GRATUITA',
    'loyaltyOffer': 'Offerta Fidelity',
    'retry': 'Riprova',
    'officialQrCode': 'Il tuo QR code ufficiale fidelity:',
    'activateCardTitle': 'Attiva la tua carta La Casita',
    'activateCardSubtitle':
        "Scansiona il QR Code della tua app fidelity per sincronizzare punti e carta in tempo reale.",
    'scanQrButton': 'Scansiona il mio QR Code',
    'enterCodeManually': 'Inserisci il codice ricevuto per SMS/WhatsApp',
    'enterIdDialogTitle': 'Inserisci il mio identificativo',
    'enterIdDialogBody':
        'Incolla o scrivi il codice inviato da La Casita (es: PIZZA:0000000000000000).',
    'idFieldLabel': 'Identificativo',
    'validate': 'Confermare',
  },
  'es': {
    'chooseLanguage': 'Elegir idioma',
    'systemLanguage': 'Idioma del teléfono',
    'callTooltip': 'Llamar a La Casita',
    'openingScheduleText':
        'Horario: viernes y sábado de 18:30 a 21:00, domingo de 18:30 a 20:30',
    'openNow': 'Actualmente abierto',
    'closedNow': 'Actualmente cerrado',
    'exceptionalOpenText': 'Excepcionalmente abierto hoy',
    'exceptionalClosedText': 'Excepcionalmente cerrado hoy',
    'syncErrorCode': 'Error de sincronización (Código: {code})',
    'connectionError': 'Error de conexión. No se pudo cargar el menú.',
    'hideExceptionalOpening': 'Ocultar apertura excepcional',
    'searchHint': 'Buscar una pizza, un ingrediente o una base...',
    'noPizzaMatch': 'Ninguna pizza coincide con tu búsqueda.',
    'customizeYourPizza': 'Personaliza tu {name}',
    'baseIngredients': 'Ingredientes base:',
    'addSupplement': 'Añadir un ingrediente extra (+1,50€):',
    'alreadyIncluded': '(Ya incluido)',
    'cancel': 'Cancelar',
    'addToCart': 'Añadir al carrito',
    'pizzaAddedWithSupplements': '¡{name} añadida! (con ingredientes extra)',
    'pizzaAdded': '¡{name} añadida!',
    'fidelityTooltip': 'Mi tarjeta de fidelidad',
    'myCart': 'Mi Carrito',
    'clearCartTooltip': 'Vaciar el carrito',
    'callTooltipShort': 'Llamar',
    'cannotMakeCall': 'No se pudo iniciar la llamada.',
    'whatsappGreeting': '¡Hola La Casita! Aquí está mi pedido:',
    'whatsappSupplements': 'Ingredientes extra',
    'whatsappTotal': 'Total',
    'whatsappPickupTime':
        '¿A qué hora puedo pasar a recoger mi pedido, por favor?',
    'cannotOpenWhatsapp': 'No se pudo abrir WhatsApp.',
    'clearCartTitle': 'Vaciar el carrito',
    'clearCartConfirm':
        '¿Seguro que quieres eliminar todos los artículos del carrito?',
    'clear': 'Vaciar',
    'cartAlreadyEmpty': 'El carrito ya está vacío.',
    'cartCleared': 'Carrito vaciado.',
    'cartEmptyShort': 'El carrito está vacío.',
    'favoriteOrderSaved': 'Pedido habitual guardado.',
    'noFavoriteOrderSaved': 'No hay pedido habitual guardado.',
    'favoriteOrderLoaded': 'Pedido habitual cargado.',
    'noLastOrderSaved': 'No hay último pedido guardado.',
    'lastOrderLoaded': 'Último pedido cargado.',
    'yourCartEmpty': 'Tu carrito está vacío.',
    'baseLabel': 'Base',
    'supplementsLabel': 'Ingredientes extra',
    'quantityLabel': 'Cantidad',
    'totalLabel': 'Total',
    'saveButton': 'Guardar',
    'usualButton': 'Habitual',
    'lastButton': 'Último',
    'whatsappButton': 'WhatsApp',
    'myLoyalty': 'Mi Fidelidad',
    'unlinkCardTooltip': 'Desvincular tarjeta',
    'cardNotFound': 'Tarjeta no encontrada',
    'defaultCustomer': 'Cliente',
    'customerNotFound': 'Cliente no encontrado',
    'accessDenied': 'Acceso denegado',
    'networkError': 'Error de red',
    'syncError': 'Error de sincronización',
    'scanError': 'Error al escanear',
    'pizzasCardTitle': 'PIZZAS LA CASITA',
    'cardBalance': 'SALDO DE TU TARJETA',
    'pizzasCount': '{current} / {target} Pizzas',
    'congratsRewardAvailable': '¡FELICIDADES! TU RECOMPENSA ESTÁ DISPONIBLE!',
    'remainingPizzas': 'FALTAN {remaining} PIZZAS PARA LA GRATIS',
    'loyaltyOffer': 'Oferta de Fidelidad',
    'retry': 'Reintentar',
    'officialQrCode': 'Tu código QR oficial de fidelidad:',
    'activateCardTitle': 'Activa tu tarjeta La Casita',
    'activateCardSubtitle':
        'Escanea el código QR de tu app de fidelidad para sincronizar tus puntos y tu tarjeta en tiempo real.',
    'scanQrButton': 'Escanear mi código QR',
    'enterCodeManually': 'Introducir el código recibido por SMS/WhatsApp',
    'enterIdDialogTitle': 'Introducir mi identificador',
    'enterIdDialogBody':
        'Pega o escribe el código enviado por La Casita (ej.: PIZZA:0000000000000000).',
    'idFieldLabel': 'Identificador',
    'validate': 'Confirmar',
  },
  'de': {
    'chooseLanguage': 'Sprache wählen',
    'systemLanguage': 'Telefonsprache',
    'callTooltip': 'La Casita anrufen',
    'openingScheduleText':
        'Öffnungszeiten: Freitag und Samstag 18:30 bis 21:00 Uhr, Sonntag 18:30 bis 20:30 Uhr',
    'openNow': 'Derzeit geöffnet',
    'closedNow': 'Derzeit geschlossen',
    'exceptionalOpenText': 'Heute außerplanmäßig geöffnet',
    'exceptionalClosedText': 'Heute außerplanmäßig geschlossen',
    'syncErrorCode': 'Synchronisierungsfehler (Code: {code})',
    'connectionError':
        'Verbindungsfehler. Die Speisekarte konnte nicht geladen werden.',
    'hideExceptionalOpening': 'Sonderöffnung ausblenden',
    'searchHint': 'Nach einer Pizza, einer Zutat oder einem Boden suchen...',
    'noPizzaMatch': 'Keine Pizza entspricht deiner Suche.',
    'customizeYourPizza': 'Passe deine {name} an',
    'baseIngredients': 'Grundzutaten:',
    'addSupplement': 'Extra-Zutat hinzufügen (+1,50€):',
    'alreadyIncluded': '(Bereits enthalten)',
    'cancel': 'Abbrechen',
    'addToCart': 'In den Warenkorb',
    'pizzaAddedWithSupplements': '{name} hinzugefügt! (mit Extra-Zutaten)',
    'pizzaAdded': '{name} hinzugefügt!',
    'fidelityTooltip': 'Meine Treuekarte',
    'myCart': 'Mein Warenkorb',
    'clearCartTooltip': 'Warenkorb leeren',
    'callTooltipShort': 'Anrufen',
    'cannotMakeCall': 'Der Anruf konnte nicht gestartet werden.',
    'whatsappGreeting': 'Hallo La Casita! Hier ist meine Bestellung:',
    'whatsappSupplements': 'Extra-Zutaten',
    'whatsappTotal': 'Gesamt',
    'whatsappPickupTime': 'Um welche Uhrzeit kann ich meine Bestellung abholen?',
    'cannotOpenWhatsapp': 'WhatsApp konnte nicht geöffnet werden.',
    'clearCartTitle': 'Warenkorb leeren',
    'clearCartConfirm':
        'Möchtest du wirklich alle Artikel aus dem Warenkorb entfernen?',
    'clear': 'Leeren',
    'cartAlreadyEmpty': 'Der Warenkorb ist bereits leer.',
    'cartCleared': 'Warenkorb geleert.',
    'cartEmptyShort': 'Der Warenkorb ist leer.',
    'favoriteOrderSaved': 'Stammbestellung gespeichert.',
    'noFavoriteOrderSaved': 'Keine Stammbestellung gespeichert.',
    'favoriteOrderLoaded': 'Stammbestellung geladen.',
    'noLastOrderSaved': 'Keine letzte Bestellung gespeichert.',
    'lastOrderLoaded': 'Letzte Bestellung geladen.',
    'yourCartEmpty': 'Dein Warenkorb ist leer.',
    'baseLabel': 'Boden',
    'supplementsLabel': 'Extra-Zutaten',
    'quantityLabel': 'Menge',
    'totalLabel': 'Gesamt',
    'saveButton': 'Speichern',
    'usualButton': 'Stammbestellung',
    'lastButton': 'Letzte',
    'whatsappButton': 'WhatsApp',
    'myLoyalty': 'Meine Treuekarte',
    'unlinkCardTooltip': 'Karte trennen',
    'cardNotFound': 'Karte nicht gefunden',
    'defaultCustomer': 'Kunde',
    'customerNotFound': 'Kunde nicht gefunden',
    'accessDenied': 'Zugriff verweigert',
    'networkError': 'Netzwerkfehler',
    'syncError': 'Synchronisierungsfehler',
    'scanError': 'Fehler beim Scannen',
    'pizzasCardTitle': 'PIZZAS LA CASITA',
    'cardBalance': 'GUTHABEN DEINER KARTE',
    'pizzasCount': '{current} / {target} Pizzen',
    'congratsRewardAvailable':
        'GLÜCKWUNSCH! DEINE PRÄMIE IST VERFÜGBAR!',
    'remainingPizzas': 'NOCH {remaining} PIZZEN BIS ZUR GRATIS-PIZZA',
    'loyaltyOffer': 'Treueangebot',
    'retry': 'Erneut versuchen',
    'officialQrCode': 'Dein offizieller Treue-QR-Code:',
    'activateCardTitle': 'Aktiviere deine La Casita Karte',
    'activateCardSubtitle':
        'Scanne den QR-Code deiner Treue-App, um deine Punkte und deine Karte in Echtzeit zu synchronisieren.',
    'scanQrButton': 'Meinen QR-Code scannen',
    'enterCodeManually': 'Per SMS/WhatsApp erhaltenen Code eingeben',
    'enterIdDialogTitle': 'Meine ID eingeben',
    'enterIdDialogBody':
        'Füge den von La Casita gesendeten Code ein oder tippe ihn ein (z. B.: PIZZA:0000000000000000).',
    'idFieldLabel': 'ID',
    'validate': 'Bestätigen',
  },
  'pl': {
    'chooseLanguage': 'Wybierz język',
    'systemLanguage': 'Język telefonu',
    'callTooltip': 'Zadzwoń do La Casita',
    'openingScheduleText':
        'Godziny otwarcia: piątek i sobota 18:30–21:00, niedziela 18:30–20:30',
    'openNow': 'Obecnie otwarte',
    'closedNow': 'Obecnie zamknięte',
    'exceptionalOpenText': 'Dziś wyjątkowo otwarte',
    'exceptionalClosedText': 'Dziś wyjątkowo zamknięte',
    'syncErrorCode': 'Błąd synchronizacji (Kod: {code})',
    'connectionError': 'Błąd połączenia. Nie można wczytać menu.',
    'hideExceptionalOpening': 'Skryj wyjątkowe otwarcie',
    'searchHint': 'Szukaj pizzy, składnika lub bazy...',
    'noPizzaMatch': 'Żadna pizza nie spełnia Twoich kryteriów.',
    'customizeYourPizza': 'Dostosuj swoją {name}',
    'baseIngredients': 'Podstawowe składniki:',
    'addSupplement': 'Dodaj dodatkowy składnik (+1,50€):',
    'alreadyIncluded': '(Już zawarte)',
    'cancel': 'Anuluj',
    'addToCart': 'Dodaj do koszyka',
    'pizzaAddedWithSupplements': '{name} dodana! (z dodatkami)',
    'pizzaAdded': '{name} dodana!',
    'fidelityTooltip': 'Moja karta lojalnościowa',
    'myCart': 'Mój Koszyk',
    'clearCartTooltip': 'Wyczyść koszyk',
    'callTooltipShort': 'Zadzwoń',
    'cannotMakeCall': 'Nie można wykonać połączenia.',
    'whatsappGreeting': 'Witaj La Casita! Moje zamówienie:',
    'whatsappSupplements': 'Dodatki',
    'whatsappTotal': 'Razem',
    'whatsappPickupTime':
        'O której godzinie mogę odebrać zamówienie?',
    'cannotOpenWhatsapp': 'Nie można otworzyć WhatsApp.',
    'clearCartTitle': 'Wyczyść koszyk',
    'clearCartConfirm':
        'Czy na pewno chcesz usunąć wszystkie produkty z koszyka?',
    'clear': 'Wyczyść',
    'cartAlreadyEmpty': 'Koszyk jest już pusty.',
    'cartCleared': 'Koszyk wyczyszczony.',
    'cartEmptyShort': 'Koszyk jest pusty.',
    'favoriteOrderSaved': 'Stałe zamówienie zapisane.',
    'noFavoriteOrderSaved': 'Brak zapisanego stałego zamówienia.',
    'favoriteOrderLoaded': 'Stałe zamówienie wczytane.',
    'noLastOrderSaved': 'Brak zapisanego ostatniego zamówienia.',
    'lastOrderLoaded': 'Ostatnie zamówienie wczytane.',
    'yourCartEmpty': 'Twój koszyk jest pusty.',
    'baseLabel': 'Baza',
    'supplementsLabel': 'Dodatki',
    'quantityLabel': 'Ilość',
    'totalLabel': 'Razem',
    'saveButton': 'Zapisz',
    'usualButton': 'Stałe',
    'lastButton': 'Ostatnie',
    'whatsappButton': 'WhatsApp',
    'myLoyalty': 'Moja Lojalność',
    'unlinkCardTooltip': 'Odłącz kartę',
    'cardNotFound': 'Karta nie znaleziona',
    'defaultCustomer': 'Klient',
    'customerNotFound': 'Klient nie znaleziony',
    'accessDenied': 'Odmowa dostępu',
    'networkError': 'Błąd sieci',
    'syncError': 'Błąd synchronizacji',
    'scanError': 'Błąd skanowania',
    'pizzasCardTitle': 'PIZZE LA CASITA',
    'cardBalance': 'STAN TWOJEJ KARTY',
    'pizzasCount': '{current} / {target} Pizz',
    'congratsRewardAvailable': 'GRATULACJE! TWOJA NAGRODA JEST DOSTĘPNA!',
    'remainingPizzas': 'JESZCZE {remaining} PIZZ DO DARMOWEJ',
    'loyaltyOffer': 'Oferta Lojalnościowa',
    'retry': 'Spróbuj ponownie',
    'officialQrCode': 'Twój oficjalny kod QR lojalności:',
    'activateCardTitle': 'Aktywuj swoją kartę La Casita',
    'activateCardSubtitle':
        'Zeskanuj kod QR swojej aplikacji lojalnościowej, aby synchronizować punkty i kartę w czasie rzeczywistym.',
    'scanQrButton': 'Zeskanuj mój kod QR',
    'enterCodeManually': 'Wpisz kod otrzymany SMS/WhatsApp',
    'enterIdDialogTitle': 'Wpisz mój identyfikator',
    'enterIdDialogBody':
        'Wklej lub wpisz kod wysłany przez La Casita (np.: PIZZA:0000000000000000).',
    'idFieldLabel': 'Identyfikator',
    'validate': 'Potwierdź',
  },
  'nl': {
    'chooseLanguage': 'Taal kiezen',
    'systemLanguage': 'Telefoontaal',
    'callTooltip': 'Bel La Casita',
    'openingScheduleText':
        'Open: vrijdag en zaterdag 18:30 tot 21:00, zondag 18:30 tot 20:30',
    'openNow': 'Momenteel open',
    'closedNow': 'Momenteel gesloten',
    'exceptionalOpenText': 'Vandaag uitzonderlijk open',
    'exceptionalClosedText': 'Vandaag uitzonderlijk gesloten',
    'syncErrorCode': 'Synchronisatiefout (Code: {code})',
    'connectionError': 'Verbindingsfout. Het menu kan niet worden geladen.',
    'hideExceptionalOpening': 'Uitzonderlijke opening verbergen',
    'searchHint': 'Zoek een pizza, een ingrediënt of een bodem...',
    'noPizzaMatch': 'Geen pizza komt overeen met uw zoekopdracht.',
    'customizeYourPizza': 'Personaliseer uw {name}',
    'baseIngredients': 'Basisingrediënten:',
    'addSupplement': 'Extra topping toevoegen (+1,50€):',
    'alreadyIncluded': '(Al inbegrepen)',
    'cancel': 'Annuleren',
    'addToCart': 'Toevoegen aan winkelwagen',
    'pizzaAddedWithSupplements': '{name} toegevoegd! (met extra toppings)',
    'pizzaAdded': '{name} toegevoegd!',
    'fidelityTooltip': 'Mijn spaarkaart',
    'myCart': 'Mijn Winkelwagen',
    'clearCartTooltip': 'Winkelwagen legen',
    'callTooltipShort': 'Bellen',
    'cannotMakeCall': 'Kan het gesprek niet starten.',
    'whatsappGreeting': 'Hallo La Casita! Hier is mijn bestelling:',
    'whatsappSupplements': 'Extra toppings',
    'whatsappTotal': 'Totaal',
    'whatsappPickupTime': 'Om hoe laat kan ik mijn bestelling komen ophalen?',
    'cannotOpenWhatsapp': 'Kan WhatsApp niet openen.',
    'clearCartTitle': 'Winkelwagen legen',
    'clearCartConfirm':
        'Weet u zeker dat u alle artikelen uit de winkelwagen wilt verwijderen?',
    'clear': 'Legen',
    'cartAlreadyEmpty': 'De winkelwagen is al leeg.',
    'cartCleared': 'Winkelwagen geleegd.',
    'cartEmptyShort': 'De winkelwagen is leeg.',
    'favoriteOrderSaved': 'Vaste bestelling opgeslagen.',
    'noFavoriteOrderSaved': 'Geen vaste bestelling opgeslagen.',
    'favoriteOrderLoaded': 'Vaste bestelling geladen.',
    'noLastOrderSaved': 'Geen laatste bestelling opgeslagen.',
    'lastOrderLoaded': 'Laatste bestelling geladen.',
    'yourCartEmpty': 'Uw winkelwagen is leeg.',
    'baseLabel': 'Bodem',
    'supplementsLabel': 'Extra toppings',
    'quantityLabel': 'Aantal',
    'totalLabel': 'Totaal',
    'saveButton': 'Opslaan',
    'usualButton': 'Vaste',
    'lastButton': 'Laatste',
    'whatsappButton': 'WhatsApp',
    'myLoyalty': 'Mijn Spaarkaart',
    'unlinkCardTooltip': 'Kaart loskoppelen',
    'cardNotFound': 'Kaart niet gevonden',
    'defaultCustomer': 'Klant',
    'customerNotFound': 'Klant niet gevonden',
    'accessDenied': 'Toegang geweigerd',
    'networkError': 'Netwerkfout',
    'syncError': 'Synchronisatiefout',
    'scanError': 'Fout bij het scannen',
    'pizzasCardTitle': 'PIZZA\'S LA CASITA',
    'cardBalance': 'SALDO VAN UW KAART',
    'pizzasCount': '{current} / {target} Pizza\'s',
    'congratsRewardAvailable': 'GEFELICITEERD! UW BELONING IS BESCHIKBAAR!',
    'remainingPizzas': 'NOG {remaining} PIZZA\'S TOT DE GRATIS PIZZA',
    'loyaltyOffer': 'Spaaraanbieding',
    'retry': 'Opnieuw proberen',
    'officialQrCode': 'Uw officiële spaar-QR-code:',
    'activateCardTitle': 'Activeer uw La Casita kaart',
    'activateCardSubtitle':
        'Scan de QR-code van uw spaar-app om uw punten en kaart in realtime te synchroniseren.',
    'scanQrButton': 'Scan mijn QR-code',
    'enterCodeManually': 'Voer de code in die u per SMS/WhatsApp ontving',
    'enterIdDialogTitle': 'Voer mijn ID in',
    'enterIdDialogBody':
        'Plak of typ de code die door La Casita is verzonden (bijv.: PIZZA:0000000000000000).',
    'idFieldLabel': 'ID',
    'validate': 'Bevestigen',
  },
};

/// Traduction des noms de suppléments affichés à l'écran.
/// La clé (français) DOIT rester identique à celle utilisée dans
/// `_availableSupplements` de home_screen.dart, car elle sert aussi à
/// comparer avec les ingrédients (en français) venus du tableur.
const Map<String, Map<String, String>> _supplements = {
  'en': {
    'Ananas': 'Pineapple',
    'Anchois': 'Anchovies',
    'Ail': 'Garlic',
    'Aneth': 'Dill',
    'Bœuf': 'Beef',
    'Bœuf épicé': 'Spicy beef',
    'Camembert': 'Camembert',
    'Câpres': 'Capers',
    'Champignons': 'Mushrooms',
    'Cheddar': 'Cheddar',
    'Chèvre': 'Goat cheese',
    'Chorizo': 'Chorizo',
    'Ciboulette': 'Chives',
    "Coulis d'olives": 'Olive tapenade',
    'Curry': 'Curry',
    'Emmental': 'Emmental',
    'Gorgonzola': 'Gorgonzola',
    'Jambon': 'Ham',
    'Kebab (Viande)': 'Kebab meat',
    'Lardons': 'Bacon bits',
    'Maïs': 'Corn',
    'Merguez': 'Merguez sausage',
    'Miel': 'Honey',
    'Moutarde': 'Mustard',
    'Mozzarella': 'Mozzarella',
    'Noix': 'Walnuts',
    'Noix de St Jacques': 'Scallops',
    'Oignons': 'Onions',
    'Origan': 'Oregano',
    'Persillade': 'Garlic parsley',
    'Poivrons': 'Peppers',
    'Pomme': 'Apple',
    'Pommes de terre': 'Potatoes',
    'Poulet': 'Chicken',
    'Raclette': 'Raclette cheese',
    'Ravioles': 'Ravioli',
    'Reblochon': 'Reblochon',
    'Roquefort': 'Roquefort',
    'St Marcellin': 'Saint-Marcellin',
    'Tomates': 'Tomatoes',
    'Truite fumée': 'Smoked trout',
  },
  'it': {
    'Ananas': 'Ananas',
    'Anchois': 'Acciughe',
    'Ail': 'Aglio',
    'Aneth': 'Aneto',
    'Bœuf': 'Manzo',
    'Bœuf épicé': 'Manzo speziato',
    'Camembert': 'Camembert',
    'Câpres': 'Capperi',
    'Champignons': 'Funghi',
    'Cheddar': 'Cheddar',
    'Chèvre': 'Formaggio di capra',
    'Chorizo': 'Chorizo',
    'Ciboulette': 'Erba cipollina',
    "Coulis d'olives": 'Crema di olive',
    'Curry': 'Curry',
    'Emmental': 'Emmental',
    'Gorgonzola': 'Gorgonzola',
    'Jambon': 'Prosciutto',
    'Kebab (Viande)': 'Carne kebab',
    'Lardons': 'Pancetta a cubetti',
    'Maïs': 'Mais',
    'Merguez': 'Salsiccia merguez',
    'Miel': 'Miele',
    'Moutarde': 'Senape',
    'Mozzarella': 'Mozzarella',
    'Noix': 'Noci',
    'Noix de St Jacques': 'Capesante',
    'Oignons': 'Cipolle',
    'Origan': 'Origano',
    'Persillade': 'Aglio e prezzemolo',
    'Poivrons': 'Peperoni',
    'Pomme': 'Mela',
    'Pommes de terre': 'Patate',
    'Poulet': 'Pollo',
    'Raclette': 'Formaggio raclette',
    'Ravioles': 'Ravioli',
    'Reblochon': 'Reblochon',
    'Roquefort': 'Roquefort',
    'St Marcellin': 'Saint-Marcellin',
    'Tomates': 'Pomodori',
    'Truite fumée': 'Trota affumicata',
  },
  'es': {
    'Ananas': 'Piña',
    'Anchois': 'Anchoas',
    'Ail': 'Ajo',
    'Aneth': 'Eneldo',
    'Bœuf': 'Ternera',
    'Bœuf épicé': 'Ternera especiada',
    'Camembert': 'Camembert',
    'Câpres': 'Alcaparras',
    'Champignons': 'Champiñones',
    'Cheddar': 'Cheddar',
    'Chèvre': 'Queso de cabra',
    'Chorizo': 'Chorizo',
    'Ciboulette': 'Cebollino',
    "Coulis d'olives": 'Paté de aceitunas',
    'Curry': 'Curry',
    'Emmental': 'Emmental',
    'Gorgonzola': 'Gorgonzola',
    'Jambon': 'Jamón',
    'Kebab (Viande)': 'Carne kebab',
    'Lardons': 'Taquitos de bacon',
    'Maïs': 'Maíz',
    'Merguez': 'Salchicha merguez',
    'Miel': 'Miel',
    'Moutarde': 'Mostaza',
    'Mozzarella': 'Mozzarella',
    'Noix': 'Nueces',
    'Noix de St Jacques': 'Vieiras',
    'Oignons': 'Cebollas',
    'Origan': 'Orégano',
    'Persillade': 'Ajo y perejil',
    'Poivrons': 'Pimientos',
    'Pomme': 'Manzana',
    'Pommes de terre': 'Patatas',
    'Poulet': 'Pollo',
    'Raclette': 'Queso raclette',
    'Ravioles': 'Raviolis',
    'Reblochon': 'Reblochon',
    'Roquefort': 'Roquefort',
    'St Marcellin': 'Saint-Marcellin',
    'Tomates': 'Tomates',
    'Truite fumée': 'Trucha ahumada',
  },
  'de': {
    'Ananas': 'Ananas',
    'Anchois': 'Sardellen',
    'Ail': 'Knoblauch',
    'Aneth': 'Dill',
    'Bœuf': 'Rindfleisch',
    'Bœuf épicé': 'Würziges Rindfleisch',
    'Camembert': 'Camembert',
    'Câpres': 'Kapern',
    'Champignons': 'Pilze',
    'Cheddar': 'Cheddar',
    'Chèvre': 'Ziegenkäse',
    'Chorizo': 'Chorizo',
    'Ciboulette': 'Schnittlauch',
    "Coulis d'olives": 'Olivencreme',
    'Curry': 'Curry',
    'Emmental': 'Emmentaler',
    'Gorgonzola': 'Gorgonzola',
    'Jambon': 'Schinken',
    'Kebab (Viande)': 'Kebabfleisch',
    'Lardons': 'Speckwürfel',
    'Maïs': 'Mais',
    'Merguez': 'Merguez-Wurst',
    'Miel': 'Honig',
    'Moutarde': 'Senf',
    'Mozzarella': 'Mozzarella',
    'Noix': 'Walnüsse',
    'Noix de St Jacques': 'Jakobsmuscheln',
    'Oignons': 'Zwiebeln',
    'Origan': 'Oregano',
    'Persillade': 'Knoblauch-Petersilie',
    'Poivrons': 'Paprika',
    'Pomme': 'Apfel',
    'Pommes de terre': 'Kartoffeln',
    'Poulet': 'Hähnchen',
    'Raclette': 'Raclette-Käse',
    'Ravioles': 'Ravioli',
    'Reblochon': 'Reblochon',
    'Roquefort': 'Roquefort',
    'St Marcellin': 'Saint-Marcellin',
    'Tomates': 'Tomaten',
    'Truite fumée': 'Geräucherte Forelle',
  },
  'pl': {
    'Ananas': 'Ananas',
    'Anchois': 'Sardele',
    'Ail': 'Czosnek',
    'Aneth': 'Koperek',
    'Bœuf': 'Wołowina',
    'Bœuf épicé': 'Wołowina pikantna',
    'Camembert': 'Camembert',
    'Câpres': 'Kapary',
    'Champignons': 'Grzyby',
    'Cheddar': 'Cheddar',
    'Chèvre': 'Kozi ser',
    'Chorizo': 'Chorizo',
    'Ciboulette': 'Szczypiorek',
    "Coulis d'olives": 'Krem z oliwek',
    'Curry': 'Curry',
    'Emmental': 'Ementaler',
    'Gorgonzola': 'Gorgonzola',
    'Jambon': 'Szynka',
    'Kebab (Viande)': 'Mięso kebab',
    'Lardons': 'Boczek w kostce',
    'Maïs': 'Kukurydza',
    'Merguez': 'Kiełbasa merguez',
    'Miel': 'Miód',
    'Moutarde': 'Musztarda',
    'Mozzarella': 'Mozzarella',
    'Noix': 'Orzechy włoskie',
    'Noix de St Jacques': 'Przegrzebki',
    'Oignons': 'Cebula',
    'Origan': 'Oregano',
    'Persillade': 'Czosnek z natką pietruszki',
    'Poivrons': 'Papryka',
    'Pomme': 'Jabłko',
    'Pommes de terre': 'Ziemniaki',
    'Poulet': 'Kurczak',
    'Raclette': 'Ser raclette',
    'Ravioles': 'Ravioli',
    'Reblochon': 'Reblochon',
    'Roquefort': 'Roquefort',
    'St Marcellin': 'Saint-Marcellin',
    'Tomates': 'Pomidory',
    'Truite fumée': 'Wędzony pstrąg',
  },
  'nl': {
    'Ananas': 'Ananas',
    'Anchois': 'Ansjovis',
    'Ail': 'Knoflook',
    'Aneth': 'Dille',
    'Bœuf': 'Rundvlees',
    'Bœuf épicé': 'Pikant rundvlees',
    'Camembert': 'Camembert',
    'Câpres': 'Kappertjes',
    'Champignons': 'Champignons',
    'Cheddar': 'Cheddar',
    'Chèvre': 'Geitenkaas',
    'Chorizo': 'Chorizo',
    'Ciboulette': 'Bieslook',
    "Coulis d'olives": 'Olijventapenade',
    'Curry': 'Curry',
    'Emmental': 'Emmentaler',
    'Gorgonzola': 'Gorgonzola',
    'Jambon': 'Ham',
    'Kebab (Viande)': 'Kebabvlees',
    'Lardons': 'Spekjes',
    'Maïs': 'Mais',
    'Merguez': 'Merguezworst',
    'Miel': 'Honing',
    'Moutarde': 'Mosterd',
    'Mozzarella': 'Mozzarella',
    'Noix': 'Walnoten',
    'Noix de St Jacques': 'Sint-jakobsschelpen',
    'Oignons': 'Uien',
    'Origan': 'Oregano',
    'Persillade': 'Peterselie-knoflook',
    'Poivrons': 'Paprika',
    'Pomme': 'Appel',
    'Pommes de terre': 'Aardappelen',
    'Poulet': 'Kip',
    'Raclette': 'Raclettekaas',
    'Ravioles': 'Ravioli',
    'Reblochon': 'Reblochon',
    'Roquefort': 'Roquefort',
    'St Marcellin': 'Saint-Marcellin',
    'Tomates': 'Tomaten',
    'Truite fumée': 'Gerookte forel',
  },
};
