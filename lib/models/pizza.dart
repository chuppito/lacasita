class Pizza {
  final String id;
  final String name;
  final String category;
  final List<String> ingredients;
  final double price;
  final String imageUrl;
  final List<String> selectedSupplements;

  const Pizza({
    required this.id,
    required this.name,
    required this.category,
    required this.ingredients,
    required this.price,
    required this.imageUrl,
    this.selectedSupplements = const [],
  });

  Pizza copyWith({
    List<String>? selectedSupplements,
    double? price,
  }) {
    return Pizza(
      id: id,
      name: name,
      category: category,
      ingredients: ingredients,
      price: price ?? this.price,
      imageUrl: imageUrl,
      selectedSupplements: selectedSupplements ?? this.selectedSupplements,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'ingredients': ingredients,
      'price': price,
      'imageUrl': imageUrl,
      'selectedSupplements': selectedSupplements,
    };
  }

  factory Pizza.fromJson(Map<String, dynamic> json) {
    return Pizza(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      ingredients: List<String>.from(json['ingredients'] ?? []),
      price: (json['price'] as num).toDouble(),
      imageUrl: json['imageUrl'] as String,
      selectedSupplements: List<String>.from(json['selectedSupplements'] ?? []),
    );
  }
}