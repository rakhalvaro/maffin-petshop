import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';
import '../utils/currency_formatter.dart';

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

  Color _getStockColor(int stock) {
    if (stock > 10) return Colors.green;
    if (stock >= 1) return Colors.orange;
    return Colors.red;
  }

  String _getStockStatus(int stock) {
    if (stock > 10) return 'Aman';
    if (stock >= 1) return 'Rendah';
    return 'Habis';
  }

  List<Product> _filterProducts(List<Product> products) {
    if (_searchQuery.isEmpty) return products;
    return products
        .where((p) => p.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Header keranjang
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.orange[50],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.shopping_cart, color: Colors.orange[700]),
                    const SizedBox(width: 8),
                    Text(
                      'Keranjang (${_cart.length} item)',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                if (_cart.isNotEmpty)
                  ElevatedButton.icon(
                    onPressed: () => _showCartDialog(context),
                    icon: const Icon(Icons.visibility, size: 16),
                    label: const Text('Lihat'),
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
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari produk untuk dipesan...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() {
                          _searchController.clear();
                          _searchQuery = '';
                        }),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
          // Daftar produk
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('products')
                  .orderBy('name')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allProducts = snapshot.data!.docs
                    .map((doc) => Product.fromMap(
                        doc.id, doc.data() as Map<String, dynamic>))
                    .toList();

                final filtered = _filterProducts(allProducts);

                if (filtered.isEmpty && _searchQuery.isNotEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text('Produk tidak ditemukan',
                            style:
                                TextStyle(fontSize: 18, color: Colors.grey)),
                        Text('Coba kata kunci lain',
                            style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final product = filtered[index];
                    final cartItem = _cart.firstWhere(
                      (item) => item.product.id == product.id,
                      orElse: () =>
                          CartItem(product: product, quantity: 0),
                    );
                    final inCart = cartItem.quantity > 0;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      color: inCart ? Colors.orange[50] : null,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: inCart
                            ? BorderSide(
                                color: Colors.orange[300]!, width: 1.5)
                            : BorderSide.none,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            _buildProductImage(product),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Rp ${product.sellPrice.toRupiah()}',
                                    style: TextStyle(
                                        color: Colors.green[700],
                                        fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Text(
                                        'Stok: ${product.stock} - ',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600]),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: _getStockColor(product.stock),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          _getStockStatus(product.stock),
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
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
                                          icon: const Icon(Icons.remove,
                                              color: Colors.white, size: 16),
                                          padding: const EdgeInsets.all(4),
                                          constraints: const BoxConstraints(
                                              minWidth: 32, minHeight: 32),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8),
                                        child: Text(
                                          '${cartItem.quantity}',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16),
                                        ),
                                      ),
                                      Container(
                                        decoration: BoxDecoration(
                                          color: product.stock >
                                                  cartItem.quantity
                                              ? Colors.orange[700]
                                              : Colors.grey[400],
                                          shape: BoxShape.circle,
                                        ),
                                        child: IconButton(
                                          onPressed: product.stock >
                                                  cartItem.quantity
                                              ? () => _addToCart(product)
                                              : null,
                                          icon: const Icon(Icons.add,
                                              color: Colors.white, size: 16),
                                          padding: const EdgeInsets.all(4),
                                          constraints: const BoxConstraints(
                                              minWidth: 32, minHeight: 32),
                                        ),
                                      ),
                                    ],
                                  )
                                : ElevatedButton(
                                    onPressed: product.stock > 0
                                        ? () => _addToCart(product)
                                        : null,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange[700],
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 8),
                                    ),
                                    child: const Text('Tambah'),
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
      floatingActionButton: _cart.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => _showCartDialog(context),
              backgroundColor: Colors.orange[700],
              icon: const Icon(Icons.shopping_cart, color: Colors.white),
              label: Text(
                'Checkout  •  Rp ${_cartTotal.toRupiah()}',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
            )
          : null,
    );
  }

  Widget _buildProductImage(Product product, {double size = 60}) {
    if (product.imageUrl != null && product.imageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          product.imageUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          loadingBuilder: (_, child, progress) => progress == null
              ? child
              : Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(10)),
                  child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2)),
                ),
          errorBuilder: (_, __, ___) => _placeholder(size),
        ),
      );
    }
    return _placeholder(size);
  }

  Widget _placeholder(double size) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.orange[50],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.orange[200]!),
        ),
        child: Icon(Icons.inventory_2_outlined,
            color: Colors.orange[300], size: size * 0.45),
      );

  void _addToCart(Product product) {
    final existingIndex =
        _cart.indexWhere((item) => item.product.id == product.id);
    if (existingIndex != -1) {
      if (_cart[existingIndex].quantity < product.stock) {
        setState(() => _cart[existingIndex].quantity++);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Stok tidak mencukupi')),
        );
      }
    } else {
      setState(() => _cart.add(CartItem(product: product, quantity: 1)));
    }
  }

  void _removeFromCart(Product product) {
    final existingIndex =
        _cart.indexWhere((item) => item.product.id == product.id);
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
      builder: (context) => AlertDialog(
        title: const Text('Keranjang Belanja'),
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
                      leading: _buildProductImage(item.product, size: 44),
                      title: Text(item.product.name),
                      subtitle: Text(
                          'Rp ${item.product.sellPrice.toRupiah()}'),
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
                              if (_cart.isNotEmpty) _showCartDialog(context);
                            },
                            icon: const Icon(Icons.remove),
                          ),
                          Text('${item.quantity}'),
                          IconButton(
                            onPressed: () {
                              if (item.quantity < item.product.stock) {
                                setState(() => item.quantity++);
                                Navigator.pop(context);
                                _showCartDialog(context);
                              }
                            },
                            icon: const Icon(Icons.add),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const Divider(),
              Text(
                'Total: Rp ${_cartTotal.toRupiah()}',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tutup')),
          ElevatedButton(
            onPressed: _cart.isNotEmpty
                ? () {
                    Navigator.pop(context);
                    _showPaymentDialog(context);
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange[700],
              foregroundColor: Colors.white,
            ),
            child: const Text('Checkout'),
          ),
        ],
      ),
    );
  }

  void _showPaymentDialog(BuildContext context) {
    String selectedPayment = 'Cash';
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Pilih Metode Pembayaran'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                title: const Text('Cash'),
                value: 'Cash',
                groupValue: selectedPayment,
                onChanged: (v) => setState(() => selectedPayment = v!),
              ),
              RadioListTile<String>(
                title: const Text('QRIS'),
                value: 'QRIS',
                groupValue: selectedPayment,
                onChanged: (v) => setState(() => selectedPayment = v!),
              ),
              const SizedBox(height: 16),
              Text(
                'Total: Rp ${_cartTotal.toRupiah()}',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal')),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _processOrder(selectedPayment);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[700],
                foregroundColor: Colors.white,
              ),
              child: const Text('Proses Pesanan'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _processOrder(String paymentMethod) async {
    try {
      final orderData = {
        'items': _cart
            .map((item) => {
                  'productName': item.product.name,
                  'quantity': item.quantity,
                  'price': item.product.sellPrice,
                  'buyPrice': item.product.buyPrice,
                })
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

      setState(() => _cart.clear());

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
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
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}