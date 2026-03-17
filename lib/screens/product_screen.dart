import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/models.dart';
import '../utils/currency_formatter.dart';

class ProductScreen extends StatefulWidget {
  @override
  _ProductScreenState createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  static const String _cloudName = 'dwx1lavrx';
  static const String _uploadPreset = 'maffin petshop';

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

  Future<XFile?> _pickImage() async {
    return await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 300,
      maxHeight: 300,
      imageQuality: 70,
    );
  }

  Future<String?> _uploadToCloudinary(XFile imageFile) async {
    try {
      final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/$_cloudName/image/upload',
      );
      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = _uploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      final jsonData = json.decode(responseBody);

      if (response.statusCode == 200) {
        return jsonData['secure_url'] as String;
      } else {
        debugPrint('Cloudinary error: ${jsonData['error']['message']}');
        return null;
      }
    } catch (e) {
      debugPrint('Upload error: $e');
      return null;
    }
  }

  // Pop up gambar besar saat di-tap
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
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.orange[700],
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Text(
                    product.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
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
                    loadingBuilder: (_, child, progress) =>
                        progress == null
                            ? child
                            : Container(
                                height: 300,
                                color: Colors.grey[900],
                                child: const Center(
                                  child: CircularProgressIndicator(
                                      color: Colors.white),
                                ),
                              ),
                    errorBuilder: (_, __, ___) => Container(
                      height: 200,
                      color: Colors.grey[900],
                      child: const Center(
                        child: Icon(Icons.broken_image,
                            color: Colors.white54, size: 64),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Tap di luar gambar untuk menutup',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
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
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari produk...',
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
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: _buildTappableImage(product),
                        title: Text(product.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                'Beli: Rp ${product.buyPrice.toRupiah()}'),
                            Text(
                                'Jual: Rp ${product.sellPrice.toRupiah()}'),
                            Row(
                              children: [
                                Text('Stok: ${product.stock} - '),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _getStockColor(product.stock),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    _getStockStatus(product.stock),
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () =>
                              _showEditProductDialog(context, product),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddProductDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  // Gambar yang bisa di-tap — ukuran 80px + icon zoom
  Widget _buildTappableImage(Product product, {double size = 80}) {
    final hasImage =
        product.imageUrl != null && product.imageUrl!.isNotEmpty;

    return GestureDetector(
      onTap: hasImage ? () => _showImageDialog(context, product) : null,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: hasImage
                ? Image.network(
                    product.imageUrl!,
                    width: size,
                    height: size,
                    fit: BoxFit.cover,
                    loadingBuilder: (_, child, progress) =>
                        progress == null
                            ? child
                            : Container(
                                width: size,
                                height: size,
                                color: Colors.grey[200],
                                child: const Center(
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2)),
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
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(
                  Icons.zoom_in,
                  color: Colors.white,
                  size: 14,
                ),
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
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange[200]!),
        ),
        child: Icon(Icons.image_outlined,
            color: Colors.orange[300], size: size * 0.5),
      );

  void _showAddProductDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final stockCtrl = TextEditingController();
    final buyCtrl = TextEditingController();
    final sellCtrl = TextEditingController();
    XFile? selectedImage;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          title: const Text('Tambah Produk'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () async {
                    final img = await _pickImage();
                    if (img != null) setDialog(() => selectedImage = img);
                  },
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selectedImage != null
                            ? Colors.orange
                            : Colors.orange[200]!,
                        width: selectedImage != null ? 2 : 1,
                      ),
                    ),
                    child: selectedImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(File(selectedImage!.path),
                                fit: BoxFit.cover),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate_outlined,
                                  color: Colors.orange[400], size: 36),
                              const SizedBox(height: 4),
                              Text('Tambah Foto',
                                  style: TextStyle(
                                      color: Colors.orange[400],
                                      fontSize: 12)),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                    controller: nameCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Nama Produk')),
                TextField(
                    controller: stockCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Jumlah Stok'),
                    keyboardType: TextInputType.number),
                TextField(
                    controller: buyCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Harga Beli'),
                    keyboardType: TextInputType.number),
                TextField(
                    controller: sellCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Harga Jual'),
                    keyboardType: TextInputType.number),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Batal')),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.isEmpty) return;
                showDialog(
                  context: ctx,
                  barrierDismissible: false,
                  builder: (_) =>
                      const Center(child: CircularProgressIndicator()),
                );
                String? imageUrl;
                if (selectedImage != null) {
                  imageUrl = await _uploadToCloudinary(selectedImage!);
                  if (imageUrl == null && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Gagal upload gambar, coba lagi'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
                await _firestore.collection('products').add({
                  'name': nameCtrl.text,
                  'stock': int.tryParse(stockCtrl.text) ?? 0,
                  'buyPrice': double.tryParse(buyCtrl.text) ?? 0,
                  'sellPrice': double.tryParse(sellCtrl.text) ?? 0,
                  'imageUrl': imageUrl,
                });
                if (mounted) {
                  Navigator.pop(ctx);
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditProductDialog(BuildContext context, Product product) {
    final nameCtrl = TextEditingController(text: product.name);
    final stockCtrl =
        TextEditingController(text: product.stock.toString());
    final buyCtrl =
        TextEditingController(text: product.buyPrice.toStringAsFixed(0));
    final sellCtrl =
        TextEditingController(text: product.sellPrice.toStringAsFixed(0));
    XFile? selectedImage;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          title: const Text('Edit Produk'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () async {
                    final img = await _pickImage();
                    if (img != null) setDialog(() => selectedImage = img);
                  },
                  child: Stack(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: Colors.orange, width: 2),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: selectedImage != null
                              ? Image.file(File(selectedImage!.path),
                                  fit: BoxFit.cover)
                              : (product.imageUrl != null
                                  ? Image.network(product.imageUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          _placeholder(100))
                                  : _placeholder(100)),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.edit,
                              color: Colors.white, size: 16),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                    controller: nameCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Nama Produk')),
                TextField(
                    controller: stockCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Jumlah Stok'),
                    keyboardType: TextInputType.number),
                TextField(
                    controller: buyCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Harga Beli'),
                    keyboardType: TextInputType.number),
                TextField(
                    controller: sellCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Harga Jual'),
                    keyboardType: TextInputType.number),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Batal')),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.isEmpty) return;
                showDialog(
                  context: ctx,
                  barrierDismissible: false,
                  builder: (_) =>
                      const Center(child: CircularProgressIndicator()),
                );
                String? imageUrl = product.imageUrl;
                if (selectedImage != null) {
                  final newUrl = await _uploadToCloudinary(selectedImage!);
                  if (newUrl != null) {
                    imageUrl = newUrl;
                  } else if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Gagal upload gambar, coba lagi'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
                await _firestore
                    .collection('products')
                    .doc(product.id)
                    .update({
                  'name': nameCtrl.text,
                  'stock': int.tryParse(stockCtrl.text) ?? 0,
                  'buyPrice': double.tryParse(buyCtrl.text) ?? 0,
                  'sellPrice': double.tryParse(sellCtrl.text) ?? 0,
                  'imageUrl': imageUrl,
                });
                if (mounted) {
                  Navigator.pop(ctx);
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }
}