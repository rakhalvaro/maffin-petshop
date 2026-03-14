import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';

class OrderScreen extends StatefulWidget {
  @override
  _OrderScreenState createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<CartItem> _cart = [];

  double get _cartTotal {
    return _cart.fold(
      0,
      (sum, item) => sum + (item.product.sellPrice * item.quantity),
    );
  }

  List<Product> _filterProducts(List<Product> products) {
    if (_searchQuery.isEmpty) return products;
    return products
        .where(
          (product) =>
              product.name.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Header keranjang
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.orange[50],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.shopping_cart, color: Colors.orange[700]),
                    SizedBox(width: 8),
                    Text(
                      'Keranjang (${_cart.length} item)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (_cart.isNotEmpty)
                  ElevatedButton.icon(
                    onPressed: () => _showCartDialog(context),
                    icon: Icon(Icons.visibility, size: 16),
                    label: Text('Lihat'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[700],
                      foregroundColor: Colors.white,
                    ),
                  ),
              ],
            ),
          ),
          // Search Bar
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari produk untuk dipesan...',
                prefixIcon: Icon(Icons.search),
                suffixIcon:
                    _searchController.text.isNotEmpty
                        ? IconButton(
                          icon: Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              _searchQuery = '';
                            });
                          },
                        )
                        : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          // Daftar produk
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  _firestore
                      .collection('products')
                      .orderBy('name')
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                final allProducts =
                    snapshot.data!.docs
                        .map(
                          (doc) => Product.fromMap(
                            doc.id,
                            doc.data() as Map<String, dynamic>,
                          ),
                        )
                        .toList();

                final filteredProducts = _filterProducts(allProducts);

                if (filteredProducts.isEmpty && _searchQuery.isNotEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Produk tidak ditemukan',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        Text(
                          'Coba kata kunci lain',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: filteredProducts.length,
                  itemBuilder: (context, index) {
                    final product = filteredProducts[index];
                    // Cek apakah produk sudah ada di keranjang
                    final cartItem = _cart.firstWhere(
                      (item) => item.product.id == product.id,
                      orElse: () => CartItem(product: product, quantity: 0),
                    );
                    final inCart = cartItem.quantity > 0;

                    return Card(
                      margin: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      // Highlight jika sudah di keranjang
                      color: inCart ? Colors.orange[50] : null,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side:
                            inCart
                                ? BorderSide(
                                  color: Colors.orange[300]!,
                                  width: 1.5,
                                )
                                : BorderSide.none,
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: Row(
                          children: [
                            // Gambar produk
                            _buildProductImage(product),
                            SizedBox(width: 12),
                            // Info produk
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product.name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Rp ${product.sellPrice.toStringAsFixed(0)}',
                                    style: TextStyle(
                                      color: Colors.green[700],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        'Stok: ${product.stock}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      if (product.stock <= 0)
                                        Container(
                                          margin: EdgeInsets.only(left: 8),
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.red,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            'Habis',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // Tombol tambah / counter jika sudah di keranjang
                            inCart
                                ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.orange[700],
                                        shape: BoxShape.circle,
                                      ),
                                      child: IconButton(
                                        onPressed: () =>
                                            _removeFromCart(product),
                                        icon: Icon(
                                          Icons.remove,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                        padding: EdgeInsets.all(4),
                                        constraints: BoxConstraints(
                                          minWidth: 32,
                                          minHeight: 32,
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 8,
                                      ),
                                      child: Text(
                                        '${cartItem.quantity}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.orange[700],
                                        shape: BoxShape.circle,
                                      ),
                                      child: IconButton(
                                        onPressed:
                                            product.stock > cartItem.quantity
                                                ? () => _addToCart(product)
                                                : null,
                                        icon: Icon(
                                          Icons.add,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                        padding: EdgeInsets.all(4),
                                        constraints: BoxConstraints(
                                          minWidth: 32,
                                          minHeight: 32,
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                                : ElevatedButton(
                                  onPressed:
                                      product.stock > 0
                                          ? () => _addToCart(product)
                                          : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange[700],
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                  ),
                                  child: Text('Tambah'),
                                ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      // Floating button checkout jika ada item di keranjang
      floatingActionButton:
          _cart.isNotEmpty
              ? FloatingActionButton.extended(
                onPressed: () => _showCartDialog(context),
                backgroundColor: Colors.orange[700],
                icon: Icon(Icons.shopping_cart, color: Colors.white),
                label: Text(
                  'Checkout  •  Rp ${_cartTotal.toStringAsFixed(0)}',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
              : null,
    );
  }

  // Widget gambar produk dengan fallback
  Widget _buildProductImage(Product product, {double size = 60}) {
    if (product.imageUrl != null && product.imageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          product.imageUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return _buildImagePlaceholder(size);
          },
        ),
      );
    }
    return _buildImagePlaceholder(size);
  }

  Widget _buildImagePlaceholder(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Icon(
        Icons.inventory_2_outlined,
        color: Colors.orange[300],
        size: size * 0.45,
      ),
    );
  }

  void _addToCart(Product product) {
    final existingIndex = _cart.indexWhere(
      (item) => item.product.id == product.id,
    );
    if (existingIndex != -1) {
      if (_cart[existingIndex].quantity < product.stock) {
        setState(() {
          _cart[existingIndex].quantity++;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Stok tidak mencukupi')),
        );
      }
    } else {
      setState(() {
        _cart.add(CartItem(product: product, quantity: 1));
      });
    }
  }

  void _removeFromCart(Product product) {
    final existingIndex = _cart.indexWhere(
      (item) => item.product.id == product.id,
    );
    if (existingIndex != -1) {
      setState(() {
        if (_cart[existingIndex].quantity > 1) {
          _cart[existingIndex].quantity--;
        } else {
          _cart.removeAt(existingIndex);
        }
      });
    }
  }

  void _showCartDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Keranjang Belanja'),
            content: Container(
              width: double.maxFinite,
              height: 400,
              child: Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: _cart.length,
                      itemBuilder: (context, index) {
                        final item = _cart[index];
                        return ListTile(
                          // Gambar kecil di keranjang
                          leading: _buildProductImage(item.product, size: 44),
                          title: Text(item.product.name),
                          subtitle: Text(
                            'Rp ${item.product.sellPrice.toStringAsFixed(0)}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: () {
                                  setState(() {
                                    if (item.quantity > 1) {
                                      item.quantity--;
                                    } else {
                                      _cart.removeAt(index);
                                    }
                                  });
                                  Navigator.pop(context);
                                  if (_cart.isNotEmpty) {
                                    _showCartDialog(context);
                                  }
                                },
                                icon: Icon(Icons.remove),
                              ),
                              Text('${item.quantity}'),
                              IconButton(
                                onPressed: () {
                                  if (item.quantity < item.product.stock) {
                                    setState(() {
                                      item.quantity++;
                                    });
                                    Navigator.pop(context);
                                    _showCartDialog(context);
                                  }
                                },
                                icon: Icon(Icons.add),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  Divider(),
                  Text(
                    'Total: Rp ${_cartTotal.toStringAsFixed(0)}',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Tutup'),
              ),
              ElevatedButton(
                onPressed:
                    _cart.isNotEmpty
                        ? () {
                          Navigator.pop(context);
                          _showPaymentDialog(context);
                        }
                        : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[700],
                  foregroundColor: Colors.white,
                ),
                child: Text('Checkout'),
              ),
            ],
          ),
    );
  }

  void _showPaymentDialog(BuildContext context) {
    String selectedPayment = 'Cash';
    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  title: Text('Pilih Metode Pembayaran'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      RadioListTile<String>(
                        title: Text('Cash'),
                        value: 'Cash',
                        groupValue: selectedPayment,
                        onChanged: (value) {
                          setState(() {
                            selectedPayment = value!;
                          });
                        },
                      ),
                      RadioListTile<String>(
                        title: Text('QRIS'),
                        value: 'QRIS',
                        groupValue: selectedPayment,
                        onChanged: (value) {
                          setState(() {
                            selectedPayment = value!;
                          });
                        },
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Total: Rp ${_cartTotal.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Batal'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        await _processOrder(selectedPayment);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange[700],
                        foregroundColor: Colors.white,
                      ),
                      child: Text('Proses Pesanan'),
                    ),
                  ],
                ),
          ),
    );
  }

  Future<void> _processOrder(String paymentMethod) async {
    try {
      final orderData = {
        'items':
            _cart
                .map(
                  (item) => {
                    'productName': item.product.name,
                    'quantity': item.quantity,
                    'price': item.product.sellPrice,
                    'buyPrice': item.product.buyPrice,
                  },
                )
                .toList(),
        'total': _cartTotal,
        'paymentMethod': paymentMethod,
        'dateTime': DateTime.now().toIso8601String(),
      };

      await _firestore.collection('orders').add(orderData);

      for (final item in _cart) {
        await _firestore
            .collection('products')
            .doc(item.product.id)
            .update({'stock': item.product.stock - item.quantity});
      }

      setState(() {
        _cart.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pesanan berhasil diproses!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }
}