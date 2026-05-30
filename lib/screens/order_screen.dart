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
  final TextEditingController _discountController = TextEditingController();
  String _searchQuery = '';
  List<CartItem> _cart = [];
  double _discount = 0;

  double get _cartTotal {
    return _cart.fold(
      0,
      (sum, item) => sum + (item.product.sellPrice * item.quantity),
    );
  }

  double get _finalTotal => (_cartTotal - _discount).clamp(0, double.infinity);

  @override
  void dispose() {
    _searchController.dispose();
    _discountController.dispose();
    super.dispose();
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

  void _showImageDialog(BuildContext context, Product product) {
    if (product.imageUrl == null || product.imageUrl!.isEmpty) return;
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => GestureDetector(
        onTap: () => Navigator.pop(ctx),
        child: Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.all(24),
          child: GestureDetector(
            onTap: () {},
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.orange[700],
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Text(
                    product.name,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                  child: Image.network(
                    product.imageUrl!,
                    fit: BoxFit.contain,
                    width: double.infinity,
                    loadingBuilder: (_, child, progress) => progress == null
                        ? child
                        : Container(
                            height: 300,
                            color: Colors.grey[900],
                            child: const Center(child: CircularProgressIndicator(color: Colors.white)),
                          ),
                    errorBuilder: (_, __, ___) => Container(
                      height: 200,
                      color: Colors.grey[900],
                      child: const Center(child: Icon(Icons.broken_image, color: Colors.white54, size: 64)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Tap di luar gambar untuk menutup',
                    style: TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
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
                    Text('Keranjang (${_cart.length} item)',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('products').orderBy('name').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allProducts = snapshot.data!.docs
                    .map((doc) => Product.fromMap(doc.id, doc.data() as Map<String, dynamic>))
                    .toList();
                final filtered = _filterProducts(allProducts);

                if (filtered.isEmpty && _searchQuery.isNotEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.search_off, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('Produk tidak ditemukan',
                            style: TextStyle(fontSize: 18, color: Colors.grey)),
                        Text('Coba kata kunci lain', style: TextStyle(color: Colors.grey)),
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
                      orElse: () => CartItem(product: product, quantity: 0),
                    );
                    final inCart = cartItem.quantity > 0;

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      color: inCart ? Colors.orange[50] : null,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: inCart
                            ? BorderSide(color: Colors.orange[300]!, width: 1.5)
                            : BorderSide.none,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Row(
                          children: [
                            _buildTappableImage(product),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Rp ${product.sellPrice.toRupiah()}',
                                    style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.w600, fontSize: 13),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Text('Stok: ${product.stock}',
                                          style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                                      const SizedBox(width: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: _getStockColor(product.stock),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(_getStockStatus(product.stock),
                                            style: const TextStyle(color: Colors.white, fontSize: 10)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            inCart
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _circleButton(
                                        icon: Icons.remove,
                                        color: Colors.orange[700]!,
                                        onTap: () => _removeFromCart(product),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 6),
                                        child: Text('${cartItem.quantity}',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                      ),
                                      _circleButton(
                                        icon: Icons.add,
                                        color: product.stock > cartItem.quantity
                                            ? Colors.orange[700]!
                                            : Colors.grey[400]!,
                                        onTap: product.stock > cartItem.quantity
                                            ? () => _addToCart(product)
                                            : null,
                                      ),
                                    ],
                                  )
                                : SizedBox(
                                    height: 34,
                                    child: ElevatedButton(
                                      onPressed: product.stock > 0 ? () => _addToCart(product) : null,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.orange[700],
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                                        textStyle: const TextStyle(fontSize: 13),
                                      ),
                                      child: const Text('Tambah'),
                                    ),
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
                'Checkout  •  Rp ${_finalTotal.toRupiah()}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            )
          : null,
    );
  }

  Widget _circleButton({required IconData icon, required Color color, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white, size: 16),
      ),
    );
  }

  Widget _buildTappableImage(Product product, {double size = 70}) {
    final hasImage = product.imageUrl != null && product.imageUrl!.isNotEmpty;
    return GestureDetector(
      onTap: hasImage ? () => _showImageDialog(context, product) : null,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: hasImage
                ? Image.network(
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
                                color: Colors.grey[200], borderRadius: BorderRadius.circular(10)),
                            child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                          ),
                    errorBuilder: (_, __, ___) => _placeholder(size),
                  )
                : _placeholder(size),
          ),
          if (hasImage)
            Positioned(
              bottom: 2,
              right: 2,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(4)),
                child: const Icon(Icons.zoom_in, color: Colors.white, size: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _placeholder(double size) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.orange[50],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.orange[200]!),
        ),
        child: Icon(Icons.inventory_2_outlined, color: Colors.orange[300], size: size * 0.45),
      );

  void _addToCart(Product product) {
    final existingIndex = _cart.indexWhere((item) => item.product.id == product.id);
    if (existingIndex != -1) {
      if (_cart[existingIndex].quantity < product.stock) {
        setState(() => _cart[existingIndex].quantity++);
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Stok tidak mencukupi')));
      }
    } else {
      setState(() => _cart.add(CartItem(product: product, quantity: 1)));
    }
  }

  void _removeFromCart(Product product) {
    final existingIndex = _cart.indexWhere((item) => item.product.id == product.id);
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
    // FIX: pakai showModalBottomSheet agar tidak nabrak keyboard
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // wajib untuk keyboard handling
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (dialogContext, dialogSetState) {
          // FIX: tinggi maksimal 85% layar, menyisakan ruang keyboard
          final screenHeight = MediaQuery.of(context).size.height;
          final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

          return Container(
            // FIX: tinggi dinamis = 85% layar, tapi naik sesuai keyboard
            constraints: BoxConstraints(
              maxHeight: screenHeight * 0.85,
            ),
            padding: EdgeInsets.only(bottom: keyboardHeight),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 4),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Icon(Icons.shopping_cart, color: Colors.orange[700]),
                      const SizedBox(width: 8),
                      const Text('Keranjang Belanja',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // Konten scrollable
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ── Daftar item ──────────────────────────
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _cart.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final item = _cart[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                children: [
                                  _buildTappableImage(item.product, size: 52),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.product.name,
                                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text('Rp ${item.product.sellPrice.toRupiah()}',
                                            style: TextStyle(color: Colors.green[700], fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _circleButton(
                                        icon: Icons.remove,
                                        color: Colors.orange[700]!,
                                        onTap: () {
                                          setState(() {
                                            if (item.quantity > 1) {
                                              item.quantity--;
                                            } else {
                                              _cart.removeAt(index);
                                            }
                                          });
                                          dialogSetState(() {});
                                          if (_cart.isEmpty) {
                                            setState(() {
                                              _discount = 0;
                                              _discountController.clear();
                                            });
                                            Navigator.pop(context);
                                          }
                                        },
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 8),
                                        child: Text('${item.quantity}',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                      ),
                                      _circleButton(
                                        icon: Icons.add,
                                        color: item.quantity < item.product.stock
                                            ? Colors.orange[700]!
                                            : Colors.grey[400]!,
                                        onTap: item.quantity < item.product.stock
                                            ? () {
                                                setState(() => item.quantity++);
                                                dialogSetState(() {});
                                              }
                                            : null,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),

                        const Divider(height: 20),

                        // ── Subtotal ──────────────────────────────
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Subtotal', style: TextStyle(color: Colors.grey)),
                            Text('Rp ${_cartTotal.toRupiah()}',
                                style: const TextStyle(color: Colors.grey)),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // ── Input Diskon ──────────────────────────
                        Row(
                          children: [
                            Icon(Icons.discount_outlined, size: 16, color: Colors.orange[700]),
                            const SizedBox(width: 6),
                            const Text('Diskon',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                            const SizedBox(width: 4),
                            const Text('(opsional)',
                                style: TextStyle(fontSize: 12, color: Colors.grey)),
                            const Spacer(),
                            if (_discount > 0)
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _discount = 0;
                                    _discountController.clear();
                                  });
                                  dialogSetState(() {});
                                },
                                child: Row(
                                  children: const [
                                    Icon(Icons.close, size: 14, color: Colors.red),
                                    SizedBox(width: 2),
                                    Text('Hapus',
                                        style: TextStyle(fontSize: 12, color: Colors.red)),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _discountController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: 'Masukkan nominal diskon...',
                            prefixText: 'Rp ',
                            isDense: true,
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.orange[700]!, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.orange[50],
                          ),
                          onChanged: (val) {
                            final parsed =
                                double.tryParse(val.replaceAll('.', '').replaceAll(',', '')) ?? 0;
                            setState(() => _discount = parsed);
                            dialogSetState(() {});
                          },
                        ),
                        const SizedBox(height: 12),

                        // ── Total Akhir ───────────────────────────
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.orange[700],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_discount > 0) ...[
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Diskon',
                                        style: TextStyle(color: Colors.white70, fontSize: 12)),
                                    Text('- Rp ${_discount.toRupiah()}',
                                        style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                              ],
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Total Bayar',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14)),
                                  Text('Rp ${_finalTotal.toRupiah()}',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // ── Tombol aksi ───────────────────────────
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _discount = 0;
                                  _discountController.clear();
                                });
                                Navigator.pop(context);
                              },
                              child: const Text('Tutup'),
                            ),
                            const SizedBox(width: 8),
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
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
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
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Subtotal', style: TextStyle(color: Colors.grey)),
                  Text('Rp ${_cartTotal.toRupiah()}',
                      style: const TextStyle(color: Colors.grey)),
                ],
              ),
              if (_discount > 0) ...[
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Diskon', style: TextStyle(color: Colors.red)),
                    Text('- Rp ${_discount.toRupiah()}',
                        style: const TextStyle(color: Colors.red)),
                  ],
                ),
              ],
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[300]!),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Bayar',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    Text('Rp ${_finalTotal.toRupiah()}',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.orange[700])),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context), child: const Text('Batal')),
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
        'subtotal': _cartTotal,
        'discount': _discount,
        'total': _finalTotal,
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
        _discount = 0;
        _discountController.clear();
      });

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