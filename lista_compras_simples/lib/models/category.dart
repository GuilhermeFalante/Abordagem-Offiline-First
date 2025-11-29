class Category {
  final String id;
  final String name;
  final String color;
  final String icon;

  const Category({
    required this.id,
    required this.name,
    required this.color,
    required this.icon,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'color': color,
      'icon': icon,
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'],
      name: map['name'],
      color: map['color'],
      icon: map['icon'],
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Category && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class DefaultCategories {
  static final List<Category> categories = [
    Category(
      id: 'work',
      name: 'Trabalho',
      color: 'FF4285F4', 
      icon: 'work',
    ),
    Category(
      id: 'personal',
      name: 'Pessoal',
      color: 'FF34A853',
      icon: 'person',
    ),
    Category(
      id: 'study',
      name: 'Estudo',
      color: 'FFFBBB05', 
      icon: 'school',
    ),
    Category(
      id: 'health',
      name: 'Saúde',
      color: 'FFEA4335',
      icon: 'favorite',
    ),
    Category(
      id: 'shopping',
      name: 'Compras',
      color: 'FF8E44AD', 
      icon: 'shopping_cart',
    ),
    Category(
      id: 'home',
      name: 'Casa',
      color: 'FFFF6B35', 
      icon: 'home',
    ),
    Category(
      id: 'other',
      name: 'Outros',
      color: 'FF95A5A6',
      icon: 'category',
    ),
  ];

  static Category get defaultCategory => categories.firstWhere((c) => c.id == 'personal');
}