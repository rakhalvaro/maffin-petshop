class Product {
  String id;
  String name;
  int stock;
  double buyPrice;
  double sellPrice;
  String? imageUrl; // TAMBAHAN: URL gambar produk dari Firebase Storage

  Product({
    required this.id,
    required this.name,
    required this.stock,
    required this.buyPrice,
    required this.sellPrice,
    this.imageUrl, // Opsional, bisa null jika belum ada gambar
  });

  // Konversi dari Product ke Map (untuk save ke Firebase)
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'stock': stock,
      'buyPrice': buyPrice,
      'sellPrice': sellPrice,
      'imageUrl': imageUrl, // Simpan imageUrl ke Firestore
    };
  }

  // Konversi dari Map ke Product (untuk read dari Firebase)
  factory Product.fromMap(String id, Map<String, dynamic> map) {
    return Product(
      id: id,
      name: map['name'] ?? '',
      stock: map['stock'] ?? 0,
      buyPrice: (map['buyPrice'] ?? 0).toDouble(),
      sellPrice: (map['sellPrice'] ?? 0).toDouble(),
      imageUrl: map['imageUrl'], // Baca imageUrl, bisa null
    );
  }
}

class CartItem {
  Product product;
  int quantity;

  CartItem({required this.product, required this.quantity});
}

class Order {
  String id;
  List<CartItem> items;
  double total;
  String paymentMethod;
  DateTime dateTime;

  Order({
    required this.id,
    required this.items,
    required this.total,
    required this.paymentMethod,
    required this.dateTime,
  });

  // Konversi dari Order ke Map (untuk save ke Firebase)
  Map<String, dynamic> toMap() {
    return {
      'items':
          items
              .map(
                (item) => {
                  'productName': item.product.name,
                  'quantity': item.quantity,
                  'price': item.product.sellPrice,
                },
              )
              .toList(),
      'total': total,
      'paymentMethod': paymentMethod,
      'dateTime': dateTime.toIso8601String(),
    };
  }
}