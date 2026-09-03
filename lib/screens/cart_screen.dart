import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import '../models/pizza.dart';
import '../providers/cart_provider.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  // Numéro de secours si Firestore est injoignable ou pas encore configuré.
  static const String _fallbackPhoneNumber = "+33619474466";
  static const String _parentDocId = "7TFknuq2ZcgFvO9czyq8gtQSELH2";

  // 🎯 TA COULEUR ROSE DE MARQUE ICI :
  static const Color _pinkPrimary = Color(0xFFF06292);

  static const String _favoriteOrderKey = "favorite_order";
  static const String _lastOrderKey = "last_order";

  /// Récupère le numéro actuel du restaurant, saisi par le gérant depuis
  /// l'app Maître (document parent, champ `phone`). Simple lecture ponctuelle
  /// (pas de stream ici) car ce numéro n'est utilisé qu'au moment de l'action.
  Future<String> _fetchPhoneNumber() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.doc("users/$_parentDocId").get();
      final phone = snapshot.data()?['phone'] as String?;
      if (phone != null && phone.trim().isNotEmpty) {
        return phone.trim();
      }
    } catch (error) {
      debugPrint("Erreur lecture téléphone restaurant : $error");
    }
    return _fallbackPhoneNumber;
  }

  /// Nettoie un numéro saisi librement par le gérant pour un usage `tel:`
  /// ou WhatsApp (ex : "06 12 34 56 78" -> "+33612345678").
  String _sanitizePhoneForUri(String raw) {
    String digits = raw.replaceAll(RegExp(r'[\s\.\-]'), '');
    if (digits.startsWith('0')) {
      digits = '+33${digits.substring(1)}';
    }
    return digits;
  }

  Future<void> _makePhoneCall(BuildContext context) async {
    final rawPhone = await _fetchPhoneNumber();
    final Uri phoneUri = Uri(
      scheme: 'tel',
      path: _sanitizePhoneForUri(rawPhone),
    );

    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.cannotMakeCall)),
      );
    }
  }

  Future<void> _sendWhatsApp(
    BuildContext context,
    Map<String, CartItem> items,
    double total,
  ) async {
    final t = AppLocalizations.of(context)!;
    StringBuffer message = StringBuffer();
    message.writeln(t.whatsappGreeting);
    message.writeln("------------------------------");

    items.forEach((key, item) {
      message.writeln("• ${item.quantity}x ${item.pizza.name}");
      if (item.pizza.selectedSupplements.isNotEmpty) {
        message.writeln(
          "  └ ${t.whatsappSupplements} : ${item.pizza.selectedSupplements.join(', ')}",
        );
      }
    });

    message.writeln("------------------------------");
    message.writeln("${t.whatsappTotal} : ${total.toStringAsFixed(2)} €");
    message.writeln(
      "\n${t.whatsappPickupTime}",
    );

    final rawPhone = await _fetchPhoneNumber();
    // wa.me attend le numéro sans "+" (indicatif pays + numéro collés).
    final String whatsappNumber =
        _sanitizePhoneForUri(rawPhone).replaceFirst('+', '');

    final Uri whatsappUri = Uri.parse(
      "https://wa.me/$whatsappNumber?text=${Uri.encodeComponent(message.toString())}",
    );

    if (await canLaunchUrl(whatsappUri)) {
      await _saveLastOrder(items);
      await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.cannotOpenWhatsapp)),
      );
    }
  }

  Future<bool> _confirmClearCart(BuildContext context) async {
    final t = AppLocalizations.of(context)!;
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(t.clearCartTitle),
          content: Text(
            t.clearCartConfirm,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(t.cancel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text(t.clear),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  Future<void> _clearCartWithConfirmation(BuildContext context) async {
    final t = AppLocalizations.of(context)!;
    final cart = Provider.of<CartProvider>(context, listen: false);

    if (cart.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.cartAlreadyEmpty)),
      );
      return;
    }

    final bool confirmed = await _confirmClearCart(context);

    if (!confirmed) return;

    cart.clearCart();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.cartCleared)),
      );
    }
  }

  List<Map<String, dynamic>> _cartToJsonList(Map<String, CartItem> items) {
    return items.values.map((item) {
      return {
        'pizza': item.pizza.toJson(),
        'quantity': item.quantity,
      };
    }).toList();
  }

  List<CartItem> _jsonListToCartItems(List<dynamic> decodedList) {
    return decodedList.map((entry) {
      final map = Map<String, dynamic>.from(entry as Map);
      return CartItem(
        pizza: Pizza.fromJson(Map<String, dynamic>.from(map['pizza'])),
        quantity: map['quantity'] as int,
      );
    }).toList();
  }

  Future<void> _saveFavoriteOrder(
    BuildContext context,
    Map<String, CartItem> items,
  ) async {
    final t = AppLocalizations.of(context)!;
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.yourCartEmpty)),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(_cartToJsonList(items));
    await prefs.setString(_favoriteOrderKey, jsonString);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.favoriteOrderSaved)),
      );
    }
  }

  Future<void> _saveLastOrder(Map<String, CartItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(_cartToJsonList(items));
    await prefs.setString(_lastOrderKey, jsonString);
  }

  Future<void> _loadFavoriteOrder(BuildContext context) async {
    final t = AppLocalizations.of(context)!;
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_favoriteOrderKey);

    if (jsonString == null || jsonString.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.noFavoriteOrderSaved)),
        );
      }
      return;
    }

    final decoded = jsonDecode(jsonString) as List<dynamic>;
    final restoredItems = _jsonListToCartItems(decoded);

    if (context.mounted) {
      final cart = Provider.of<CartProvider>(context, listen: false);
      cart.restoreCart(restoredItems);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.favoriteOrderLoaded)),
      );
    }
  }

  Future<void> _loadLastOrder(BuildContext context) async {
    final t = AppLocalizations.of(context)!;
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_lastOrderKey);

    if (jsonString == null || jsonString.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.noLastOrderSaved)),
        );
      }
      return;
    }

    final decoded = jsonDecode(jsonString) as List<dynamic>;
    final restoredItems = _jsonListToCartItems(decoded);

    if (context.mounted) {
      final cart = Provider.of<CartProvider>(context, listen: false);
      cart.restoreCart(restoredItems);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.lastOrderLoaded)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          t.myCart,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        // 🎨 Applique le rose sur l'appbar
        backgroundColor: _pinkPrimary,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: t.clearCartTooltip,
            onPressed: () => _clearCartWithConfirmation(context),
          ),
          IconButton(
            icon: const Icon(Icons.phone),
            tooltip: t.callTooltipShort,
            onPressed: () => _makePhoneCall(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: cart.items.isEmpty
                  ? Center(
                      child: Text(t.yourCartEmpty),
                    )
                  : ListView.builder(
                      itemCount: cart.items.length,
                      itemBuilder: (ctx, i) {
                        final entry = cart.items.entries.toList()[i];
                        final cartKey = entry.key;
                        final item = entry.value;

                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          child: ListTile(
                            title: Text(
                              item.pizza.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${t.baseLabel} : ${item.pizza.category.toUpperCase()}',
                                ),
                                if (item.pizza.selectedSupplements.isNotEmpty)
                                  Text(
                                    '${t.supplementsLabel} : ${item.pizza.selectedSupplements.join(', ')}',
                                    style: const TextStyle(
                                      // 🎨 Applique le rose sur les suppléments
                                      color: _pinkPrimary,
                                    ),
                                  ),
                                Text('${t.quantityLabel} : ${item.quantity}'),
                              ],
                            ),
                            trailing: Text(
                              '${(item.pizza.price * item.quantity).toStringAsFixed(2)} €',
                            ),
                            leading: IconButton(
                              icon: const Icon(
                                Icons.remove_circle_outline,
                                color: Colors.red,
                              ),
                              onPressed: () => cart.removeSingleItem(cartKey),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${t.totalLabel}: ${cart.totalAmount.toStringAsFixed(2)} €',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: cart.items.isEmpty
                              ? null
                              : () => _saveFavoriteOrder(context, cart.items),
                          icon: const Icon(Icons.favorite, color: Colors.white),
                          label: Text(t.saveButton),
                          style: ElevatedButton.styleFrom(
                            // 🎨 Applique le rose sur le bouton Enregistrer
                            backgroundColor: _pinkPrimary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _loadFavoriteOrder(context),
                          icon: const Icon(Icons.star, color: Colors.white),
                          label: Text(t.usualButton),
                          style: ElevatedButton.styleFrom(
                            // 🎨 Applique le rose sur le bouton Habituelle
                            backgroundColor: _pinkPrimary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _loadLastOrder(context),
                          icon: const Icon(Icons.history, color: Colors.white),
                          label: Text(t.lastButton),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueGrey,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: cart.items.isEmpty
                              ? null
                              : () => _sendWhatsApp(
                                    context,
                                    cart.items,
                                    cart.totalAmount,
                                  ),
                          icon: const Icon(Icons.send, color: Colors.white),
                          label: Text(t.whatsappButton),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
