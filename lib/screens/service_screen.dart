import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/currency_formatter.dart';

class ServiceScreen extends StatefulWidget {
  @override
  _ServiceScreenState createState() => _ServiceScreenState();
}

class _ServiceScreenState extends State<ServiceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Tab bar
          Container(
            color: Colors.orange[700],
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              unselectedLabelStyle: GoogleFonts.poppins(),
              tabs: const [
                Tab(icon: Icon(Icons.content_cut), text: 'Grooming'),
                Tab(icon: Icon(Icons.home), text: 'Penitipan'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _GroomingTab(),
                _PenitipanTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── GROOMING TAB ─────────────────────────────────────────────────────────────

class _GroomingTab extends StatefulWidget {
  @override
  _GroomingTabState createState() => _GroomingTabState();
}

class _GroomingTabState extends State<_GroomingTab> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('services')
            .where('type', isEqualTo: 'grooming')
            .orderBy('dateTime', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final services = snapshot.data!.docs;

          if (services.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.content_cut, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada data grooming',
                    style: GoogleFonts.poppins(
                        fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: services.length,
            itemBuilder: (context, index) {
              final data = services[index].data() as Map<String, dynamic>;
              final dateTime = DateTime.parse(data['dateTime']);
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.content_cut,
                        color: Colors.orange[700], size: 24),
                  ),
                  title: Text(
                    data['catName'],
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['serviceType'],
                        style: GoogleFonts.poppins(color: Colors.grey[600]),
                      ),
                      Text(
                        '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}',
                        style: GoogleFonts.poppins(
                            fontSize: 12, color: Colors.grey),
                      ),
                      Text(
                        'Pembayaran: ${data['paymentMethod']}',
                        style: GoogleFonts.poppins(fontSize: 12),
                      ),
                    ],
                  ),
                  trailing: Text(
                    'Rp ${(data['price'] as num).toRupiah()}',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                      fontSize: 15,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddGroomingDialog(context),
        backgroundColor: Colors.orange[700],
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('Tambah Grooming',
            style: GoogleFonts.poppins(
                color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  void _showAddGroomingDialog(BuildContext context) {
    final catNameCtrl = TextEditingController();
    final serviceTypeCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    String selectedPayment = 'Cash';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          title: Text('Tambah Grooming',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: catNameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Nama Kucing',
                    prefixIcon: const Icon(Icons.pets),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: serviceTypeCtrl,
                  decoration: InputDecoration(
                    labelText: 'Jenis Grooming',
                    hintText: 'contoh: Mandi + Potong Kuku',
                    prefixIcon: const Icon(Icons.content_cut),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: priceCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Harga',
                    prefixText: 'Rp ',
                    prefixIcon: const Icon(Icons.attach_money),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 12),
                // Metode pembayaran
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 12, top: 8),
                        child: Text('Metode Pembayaran',
                            style: GoogleFonts.poppins(
                                fontSize: 12, color: Colors.grey[600])),
                      ),
                      RadioListTile<String>(
                        title: Text('Cash', style: GoogleFonts.poppins()),
                        value: 'Cash',
                        groupValue: selectedPayment,
                        onChanged: (v) =>
                            setDialog(() => selectedPayment = v!),
                        dense: true,
                      ),
                      RadioListTile<String>(
                        title: Text('QRIS', style: GoogleFonts.poppins()),
                        value: 'QRIS',
                        groupValue: selectedPayment,
                        onChanged: (v) =>
                            setDialog(() => selectedPayment = v!),
                        dense: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Batal', style: GoogleFonts.poppins()),
            ),
            ElevatedButton(
              onPressed: () async {
                if (catNameCtrl.text.isEmpty ||
                    serviceTypeCtrl.text.isEmpty ||
                    priceCtrl.text.isEmpty) return;

                await _firestore.collection('services').add({
                  'type': 'grooming',
                  'catName': catNameCtrl.text,
                  'serviceType': serviceTypeCtrl.text,
                  'price': double.tryParse(priceCtrl.text) ?? 0,
                  'paymentMethod': selectedPayment,
                  'dateTime': DateTime.now().toIso8601String(),
                });

                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Grooming berhasil dicatat!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[700],
                foregroundColor: Colors.white,
              ),
              child: Text('Simpan', style: GoogleFonts.poppins()),
            ),
          ],
        ),
      ),
    );
  }
}

// ── PENITIPAN TAB ─────────────────────────────────────────────────────────────

class _PenitipanTab extends StatefulWidget {
  @override
  _PenitipanTabState createState() => _PenitipanTabState();
}

class _PenitipanTabState extends State<_PenitipanTab> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('services')
            .where('type', isEqualTo: 'penitipan')
            .orderBy('dateTime', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final services = snapshot.data!.docs;

          if (services.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.home, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada data penitipan',
                    style: GoogleFonts.poppins(
                        fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: services.length,
            itemBuilder: (context, index) {
              final data = services[index].data() as Map<String, dynamic>;
              final checkIn = DateTime.parse(data['checkIn']);
              final checkOut = DateTime.parse(data['checkOut']);
              final days = checkOut.difference(checkIn).inDays;
              final bringFood = data['bringFood'] as bool;
              final discount = (data['discount'] as num).toDouble();
              final total = (data['total'] as num).toDouble();

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ExpansionTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      shape: BoxShape.circle,
                    ),
                    child:
                        Icon(Icons.home, color: Colors.orange[700], size: 24),
                  ),
                  title: Text(
                    data['catName'],
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$days hari • ${checkIn.day}/${checkIn.month} - ${checkOut.day}/${checkOut.month}/${checkOut.year}',
                        style: GoogleFonts.poppins(fontSize: 12),
                      ),
                      Text(
                        'Pembayaran: ${data['paymentMethod']}',
                        style: GoogleFonts.poppins(fontSize: 12),
                      ),
                    ],
                  ),
                  trailing: Text(
                    'Rp ${total.toRupiah()}',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                      fontSize: 15,
                    ),
                  ),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      width: double.infinity,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _detailRow('Harga per hari',
                              'Rp ${(data['pricePerDay'] as num).toRupiah()}'),
                          _detailRow('Jumlah hari', '$days hari'),
                          _detailRow('Bawa makanan sendiri',
                              bringFood ? 'Ya' : 'Tidak'),
                          if (!bringFood)
                            _detailRow('Harga makanan/hari',
                                'Rp ${(data['foodPricePerDay'] as num).toRupiah()}'),
                          if (discount > 0)
                            _detailRow('Diskon',
                                '- Rp ${discount.toRupiah()}',
                                valueColor: Colors.red[600]),
                          const Divider(),
                          _detailRow('Total', 'Rp ${total.toRupiah()}',
                              isBold: true,
                              valueColor: Colors.green[700]),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddPenitipanDialog(context),
        backgroundColor: Colors.orange[700],
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('Tambah Penitipan',
            style: GoogleFonts.poppins(
                color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _detailRow(String label, String value,
      {bool isBold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 13, color: Colors.grey[600])),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddPenitipanDialog(BuildContext context) {
    final catNameCtrl = TextEditingController();
    final pricePerDayCtrl = TextEditingController();
    final foodPriceCtrl = TextEditingController();
    final discountCtrl = TextEditingController();
    DateTime checkIn = DateTime.now();
    DateTime checkOut = DateTime.now().add(const Duration(days: 1));
    bool bringFood = true;
    String selectedPayment = 'Cash';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (ctx, setDialog) {
          final days = checkOut.difference(checkIn).inDays;
          final pricePerDay =
              double.tryParse(pricePerDayCtrl.text) ?? 0;
          final foodPrice =
              double.tryParse(foodPriceCtrl.text) ?? 0;
          final discount = double.tryParse(discountCtrl.text) ?? 0;
          final subtotal = (pricePerDay * days) +
              (bringFood ? 0 : foodPrice * days);
          final total = subtotal - discount;

          return AlertDialog(
            title: Text('Tambah Penitipan',
                style:
                    GoogleFonts.poppins(fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Nama kucing
                  TextField(
                    controller: catNameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Nama Kucing',
                      prefixIcon: const Icon(Icons.pets),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Tanggal masuk
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: checkIn,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        setDialog(() {
                          checkIn = picked;
                          if (checkOut.isBefore(checkIn)) {
                            checkOut = checkIn
                                .add(const Duration(days: 1));
                          }
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[400]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.login,
                              color: Colors.orange[700], size: 20),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text('Tanggal Masuk',
                                  style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      color: Colors.grey[600])),
                              Text(
                                '${checkIn.day}/${checkIn.month}/${checkIn.year}',
                                style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Tanggal keluar
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: checkOut,
                        firstDate: checkIn
                            .add(const Duration(days: 1)),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        setDialog(() => checkOut = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[400]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.logout,
                              color: Colors.orange[700], size: 20),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text('Tanggal Keluar',
                                  style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      color: Colors.grey[600])),
                              Text(
                                '${checkOut.day}/${checkOut.month}/${checkOut.year}',
                                style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.orange[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$days hari',
                              style: GoogleFonts.poppins(
                                color: Colors.orange[800],
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Harga per hari
                  TextField(
                    controller: pricePerDayCtrl,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setDialog(() {}),
                    decoration: InputDecoration(
                      labelText: 'Harga per Hari',
                      prefixText: 'Rp ',
                      prefixIcon: const Icon(Icons.attach_money),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Bawa makanan sendiri
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding:
                              const EdgeInsets.only(left: 12, top: 8),
                          child: Text('Makanan',
                              style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.grey[600])),
                        ),
                        RadioListTile<bool>(
                          title: Text('Bawa makanan sendiri',
                              style: GoogleFonts.poppins()),
                          value: true,
                          groupValue: bringFood,
                          onChanged: (v) =>
                              setDialog(() => bringFood = v!),
                          dense: true,
                        ),
                        RadioListTile<bool>(
                          title: Text('Tidak bawa makanan',
                              style: GoogleFonts.poppins()),
                          value: false,
                          groupValue: bringFood,
                          onChanged: (v) =>
                              setDialog(() => bringFood = v!),
                          dense: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Harga makanan (muncul jika tidak bawa makanan)
                  if (!bringFood) ...[
                    TextField(
                      controller: foodPriceCtrl,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setDialog(() {}),
                      decoration: InputDecoration(
                        labelText: 'Harga Makanan per Hari',
                        prefixText: 'Rp ',
                        prefixIcon: const Icon(Icons.restaurant),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Diskon
                  TextField(
                    controller: discountCtrl,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setDialog(() {}),
                    decoration: InputDecoration(
                      labelText: 'Diskon (opsional)',
                      prefixText: 'Rp ',
                      prefixIcon: const Icon(Icons.discount),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Metode pembayaran
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding:
                              const EdgeInsets.only(left: 12, top: 8),
                          child: Text('Metode Pembayaran',
                              style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.grey[600])),
                        ),
                        RadioListTile<String>(
                          title:
                              Text('Cash', style: GoogleFonts.poppins()),
                          value: 'Cash',
                          groupValue: selectedPayment,
                          onChanged: (v) =>
                              setDialog(() => selectedPayment = v!),
                          dense: true,
                        ),
                        RadioListTile<String>(
                          title:
                              Text('QRIS', style: GoogleFonts.poppins()),
                          value: 'QRIS',
                          groupValue: selectedPayment,
                          onChanged: (v) =>
                              setDialog(() => selectedPayment = v!),
                          dense: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Ringkasan total
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange[200]!),
                    ),
                    child: Column(
                      children: [
                        Text('Ringkasan',
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange[700])),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Menginap ($days hari)',
                                style: GoogleFonts.poppins(fontSize: 13)),
                            Text(
                                'Rp ${(pricePerDay * days).toRupiah()}',
                                style: GoogleFonts.poppins(fontSize: 13)),
                          ],
                        ),
                        if (!bringFood)
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Makanan ($days hari)',
                                  style:
                                      GoogleFonts.poppins(fontSize: 13)),
                              Text(
                                  'Rp ${(foodPrice * days).toRupiah()}',
                                  style:
                                      GoogleFonts.poppins(fontSize: 13)),
                            ],
                          ),
                        if (discount > 0)
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Diskon',
                                  style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      color: Colors.red[600])),
                              Text('- Rp ${discount.toRupiah()}',
                                  style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      color: Colors.red[600])),
                            ],
                          ),
                        const Divider(),
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Total',
                                style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold)),
                            Text(
                              'Rp ${total.toRupiah()}',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                color: Colors.green[700],
                                fontSize: 16,
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
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Batal', style: GoogleFonts.poppins()),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (catNameCtrl.text.isEmpty ||
                      pricePerDayCtrl.text.isEmpty) return;
                  if (!bringFood && foodPriceCtrl.text.isEmpty) return;

                  await _firestore.collection('services').add({
                    'type': 'penitipan',
                    'catName': catNameCtrl.text,
                    'checkIn': checkIn.toIso8601String(),
                    'checkOut': checkOut.toIso8601String(),
                    'days': days,
                    'pricePerDay':
                        double.tryParse(pricePerDayCtrl.text) ?? 0,
                    'bringFood': bringFood,
                    'foodPricePerDay': bringFood
                        ? 0
                        : (double.tryParse(foodPriceCtrl.text) ?? 0),
                    'discount': discount,
                    'total': total,
                    'paymentMethod': selectedPayment,
                    'dateTime': DateTime.now().toIso8601String(),
                  });

                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Penitipan berhasil dicatat!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[700],
                  foregroundColor: Colors.white,
                ),
                child: Text('Simpan', style: GoogleFonts.poppins()),
              ),
            ],
          );
        },
      ),
    );
  }
}