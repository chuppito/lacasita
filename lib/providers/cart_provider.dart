import 'package:flutter/material.dart';
import '../models/pizza.dart';

class CartItem {
  final Pizza pizza;
  int quantity;

  CartItem({required this.pizza, this.quantity = 1});
}

class CartProvider with ChangeNotifier {
  final Map<String, CartItem> _items = {};

  Map<String, CartItem> get items => {..._items};

  int get itemCount => _items.values.fold(0, (sum, item) => sum + item.quantity);

  double get totalAmount {
    return _items.values.fold(
      0.0,
      (sum, item) => sum + (item.pizza.price * item.quantity),
    );
  }

  String _buildCartKey(Pizza pizza) {
    final supplements = [...pizza.selectedSupplements]..sort();
    return '${pizza.id}__${supplements.join('_')}__${pizza.price}';
  }

  void addItem(Pizza pizza) {
    final cartKey = _buildCartKey(pizza);

    if (_items.containsKey(cartKey)) {
      _items[cartKey]!.quantity++;
    } else {
      _items.putIfAbsent(cartKey, () => CartItem(pizza: pizza));
    }
    notifyListeners();
  }

  void removeSingleItem(String cartKey) {
    if (!_items.containsKey(cartKey)) return;

    if (_items[cartKey]!.quantity > 1) {
      _items[cartKey]!.quantity--;
    } else {
      _items.remove(cartKey);
    }
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }

  void restoreCart(List<CartItem> restoredItems) {
    _items.clear();

    for (final item in restoredItems) {
      final cartKey = _buildCartKey(item.pizza);
      _items[cartKey] = CartItem(
        pizza: item.pizza,
        quantity: item.quantity,
      );
    }

    notifyListeners();
  }
}