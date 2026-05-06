import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
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

// ── GROOMING TAB ──────────────────────────────────────────────────────────────

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
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
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
                  Text('Belum ada data grooming',
                      style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey)),
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
              final price = (data['price'] as num).toDouble();
              final modal = (data['modal'] as num? ?? 0).toDouble();
              final laba = price - modal;

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Colors.orange[50], shape: BoxShape.circle),
                        child: Icon(Icons.content_cut, color: Colors.orange[700], size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(data['catName'],
                                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15)),
                            Text(data['serviceType'],
                                style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 13)),
                            Text(
                              '${dateTime.day}/${dateTime.month}/${dateTime.year}  ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}',
                              style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[400]),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Rp ${price.toRupiah()}',
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold, color: Colors.green[700], fontSize: 15)),
                          const SizedBox(height: 2),
                          Text('Modal: Rp ${modal.toRupiah()}',
                              style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[500])),
                          Container(
                            margin: const EdgeInsets.only(top: 2),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: laba >= 0 ? Colors.green[50] : Colors.red[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: laba >= 0 ? Colors.green[200]! : Colors.red[200]!,
                              ),
                            ),
                            child: Text(
                              'Laba: Rp ${laba.toRupiah()}',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: laba >= 0 ? Colors.green[700] : Colors.red[600],
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                                color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                            child: Text(data['paymentMethod'],
                                style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[600])),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddGroomingDialog(context),
        backgroundColor: Colors.orange[700],
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showAddGroomingDialog(BuildContext context) {
    final catNameCtrl = TextEditingController();
    final serviceTypeCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final modalCtrl = TextEditingController();
    String selectedPayment = 'Cash';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (ctx, setDialog) {
          final price = double.tryParse(priceCtrl.text) ?? 0;
          final modal = double.tryParse(modalCtrl.text) ?? 0;
          final laba = price - modal;

          return AlertDialog(
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
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: serviceTypeCtrl,
                    decoration: InputDecoration(
                      labelText: 'Jenis Grooming',
                      hintText: 'contoh: Mandi + Potong Kuku',
                      prefixIcon: const Icon(Icons.content_cut),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: priceCtrl,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setDialog(() {}),
                    decoration: InputDecoration(
                      labelText: 'Harga Jual',
                      prefixText: 'Rp ',
                      prefixIcon: const Icon(Icons.attach_money),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: modalCtrl,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setDialog(() {}),
                    decoration: InputDecoration(
                      labelText: 'Modal (air + shampo + listrik)',
                      prefixText: 'Rp ',
                      prefixIcon: const Icon(Icons.water_drop_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  // Preview laba real-time
                  if (price > 0 || modal > 0) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: laba >= 0 ? Colors.green[50] : Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: laba >= 0 ? Colors.green[200]! : Colors.red[200]!,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Estimasi Laba',
                              style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600])),
                          Text(
                            'Rp ${laba.toRupiah()}',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: laba >= 0 ? Colors.green[700] : Colors.red[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  _paymentSelector(selectedPayment, (v) => setDialog(() => selectedPayment = v)),
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
                  if (catNameCtrl.text.isEmpty || serviceTypeCtrl.text.isEmpty || priceCtrl.text.isEmpty) return;
                  await _firestore.collection('services').add({
                    'type': 'grooming',
                    'catName': catNameCtrl.text,
                    'serviceType': serviceTypeCtrl.text,
                    'price': double.tryParse(priceCtrl.text) ?? 0,
                    'modal': double.tryParse(modalCtrl.text) ?? 0,
                    'paymentMethod': selectedPayment,
                    'dateTime': DateTime.now().toIso8601String(),
                  });
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Grooming berhasil dicatat!'),
                            backgroundColor: Colors.green));
                  }
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[700], foregroundColor: Colors.white),
                child: Text('Simpan', style: GoogleFonts.poppins()),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _paymentSelector(String selected, Function(String) onChanged) {
    return Container(
      decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 8),
            child: Text('Metode Pembayaran',
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
          ),
          RadioListTile<String>(
            title: Text('Cash', style: GoogleFonts.poppins()),
            value: 'Cash', groupValue: selected,
            onChanged: (v) => onChanged(v!), dense: true,
          ),
          RadioListTile<String>(
            title: Text('QRIS', style: GoogleFonts.poppins()),
            value: 'QRIS', groupValue: selected,
            onChanged: (v) => onChanged(v!), dense: true,
          ),
        ],
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
  double _pricePerDay = 0;
  bool _priceLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadPrice();
  }

  Future<void> _loadPrice() async {
    try {
      final doc = await _firestore.collection('config').doc('app_config').get();
      if (doc.exists && doc.data()!.containsKey('pricePerDay')) {
        setState(() {
          _pricePerDay = (doc.data()!['pricePerDay'] as num).toDouble();
          _priceLoaded = true;
        });
      }
    } catch (e) {
      debugPrint('Error loading price: $e');
    }
  }

  _CheckoutStatus _getCheckoutStatus(DateTime checkOut, bool isCompleted) {
    if (isCompleted) return _CheckoutStatus.completed;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final checkOutDay = DateTime(checkOut.year, checkOut.month, checkOut.day);
    if (checkOutDay.isAtSameMomentAs(today)) return _CheckoutStatus.today;
    if (checkOutDay.isBefore(today)) return _CheckoutStatus.overdue;
    return _CheckoutStatus.upcoming;
  }

  Future<void> _openWhatsApp({
    required String phone,
    required String catName,
    required String ownerName,
    required _CheckoutStatus status,
  }) async {
    String formattedPhone = phone.trim();
    if (formattedPhone.startsWith('0')) {
      formattedPhone = '62${formattedPhone.substring(1)}';
    } else if (formattedPhone.startsWith('+')) {
      formattedPhone = formattedPhone.substring(1);
    }
    String message = '';
    if (status == _CheckoutStatus.today) {
      message = 'Halo $ownerName, kami dari Maffin Petshop ingin memberitahu bahwa kucing Anda $catName sudah waktunya dijemput. Terima kasih 🐱';
    } else if (status == _CheckoutStatus.overdue) {
      message = 'Halo $ownerName, kami dari Maffin Petshop ingin memberitahu bahwa kucing Anda $catName sudah melewati waktu penjemputan. Mohon segera dijemput. Terima kasih 🐱';
    }
    final encodedMessage = Uri.encodeComponent(message);
    final url = 'https://wa.me/$formattedPhone?text=$encodedMessage';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

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
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
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
                  Text('Belum ada data penitipan',
                      style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: services.length,
            itemBuilder: (context, index) {
              final docId = services[index].id;
              final data = services[index].data() as Map<String, dynamic>;
              final checkIn = DateTime.parse(data['checkIn']);
              final checkOut = DateTime.parse(data['checkOut']);
              final days = checkOut.difference(checkIn).inDays + 1; // fix: hitung hari masuk
              final total = (data['total'] as num).toDouble();
              final dp = (data['dp'] as num? ?? 0).toDouble();
              final isPaid = data['isPaid'] as bool? ?? false;
              final isCompleted = data['isCompleted'] as bool? ?? false;
              final ownerName = data['ownerName'] ?? '';
              final ownerPhone = data['ownerPhone'] ?? '';
              final notes = (data['notes'] as List?)?.cast<Map<String, dynamic>>() ?? [];
              final status = _getCheckoutStatus(checkOut, isCompleted);
              final discount = (data['discount'] as num? ?? 0).toDouble();

              Color borderColor;
              Color bgColor;
              switch (status) {
                case _CheckoutStatus.today:
                  borderColor = Colors.green[400]!; bgColor = Colors.green[50]!; break;
                case _CheckoutStatus.overdue:
                  borderColor = Colors.red[400]!; bgColor = Colors.red[50]!; break;
                case _CheckoutStatus.completed:
                  borderColor = Colors.grey[300]!; bgColor = Colors.grey[50]!; break;
                default:
                  borderColor = Colors.grey[200]!; bgColor = Colors.white;
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                color: bgColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: borderColor, width: 1.5),
                ),
                elevation: isCompleted ? 0 : 2,
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  childrenPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: status == _CheckoutStatus.today ? Colors.green[100]
                          : status == _CheckoutStatus.overdue ? Colors.red[100]
                          : status == _CheckoutStatus.completed ? Colors.grey[200]
                          : Colors.orange[50],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.home,
                        color: status == _CheckoutStatus.today ? Colors.green[700]
                            : status == _CheckoutStatus.overdue ? Colors.red[700]
                            : status == _CheckoutStatus.completed ? Colors.grey[500]
                            : Colors.orange[700],
                        size: 22),
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(data['catName'],
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: isCompleted ? Colors.grey[500] : null)),
                      ),
                      _buildBadge(status),
                    ],
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6, bottom: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Icon(Icons.calendar_today, size: 12, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              '$days hari  •  ${checkIn.day}/${checkIn.month} → ${checkOut.day}/${checkOut.month}/${checkOut.year}',
                              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
                            ),
                          ),
                        ]),
                        if (ownerName.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Row(children: [
                            Icon(Icons.person, size: 12, color: Colors.grey[500]),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(ownerName,
                                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
                            ),
                          ]),
                        ],
                        const SizedBox(height: 6),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Rp ${total.toRupiah()}',
                                      style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.bold,
                                          color: isCompleted ? Colors.grey[500] : Colors.green[700],
                                          fontSize: 16)),
                                  if (dp > 0 && !isPaid)
                                    Text('DP: Rp ${dp.toRupiah()} • Sisa: Rp ${(total - dp).toRupiah()}',
                                        style: GoogleFonts.poppins(fontSize: 11, color: Colors.orange[700])),
                                  if (isPaid && dp > 0)
                                    Text('✅ Lunas',
                                        style: GoogleFonts.poppins(fontSize: 11, color: Colors.green[700])),
                                ],
                              ),
                            ),
                            if (ownerPhone.isNotEmpty && !isCompleted)
                              _buildWAButton(
                                onTap: () => _openWhatsApp(
                                  phone: ownerPhone,
                                  catName: data['catName'],
                                  ownerName: ownerName,
                                  status: status,
                                ),
                                status: status,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  children: [
                    Container(
                      margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Detail Penitipan',
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey[700])),
                          const SizedBox(height: 8),
                          _detailRow('Owner', ownerName),
                          _detailRow('No. WA', ownerPhone),
                          const Divider(height: 16),
                          _detailRow('Harga per hari', 'Rp ${(data['pricePerDay'] as num).toRupiah()}'),
                          _detailRow('Jumlah hari', '$days hari'),
                          if (discount > 0)
                            _detailRow('Diskon', '- Rp ${discount.toRupiah()}',
                                valueColor: Colors.red[600]),
                          const Divider(height: 16),
                          _detailRow('Total', 'Rp ${total.toRupiah()}',
                              isBold: true, valueColor: Colors.green[700]),
                          if (dp > 0)
                            _detailRow('DP dibayar', 'Rp ${dp.toRupiah()}',
                                valueColor: Colors.orange[700]),
                          if (dp > 0 && !isPaid)
                            _detailRow('Sisa pembayaran', 'Rp ${(total - dp).toRupiah()}',
                                isBold: true, valueColor: Colors.red[600]),
                          if (isPaid && dp > 0)
                            _detailRow('Status', '✅ Lunas', valueColor: Colors.green[700]),

                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Catatan',
                                  style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey[700])),
                              if (!isCompleted)
                                GestureDetector(
                                  onTap: () => _showAddNoteDialog(context, docId, data['catName']),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.orange[50],
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.orange[300]!),
                                    ),
                                    child: Row(children: [
                                      Icon(Icons.add, size: 14, color: Colors.orange[700]),
                                      const SizedBox(width: 2),
                                      Text('Tambah', style: GoogleFonts.poppins(
                                          fontSize: 12, color: Colors.orange[700])),
                                    ]),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (notes.isEmpty)
                            Text('Belum ada catatan',
                                style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[400]))
                          else
                            ...notes.map((note) => Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.amber[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.amber[200]!),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('📝 ', style: TextStyle(fontSize: 13)),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(note['text'] ?? '',
                                            style: GoogleFonts.poppins(fontSize: 13)),
                                        Text(note['date'] ?? '',
                                            style: GoogleFonts.poppins(
                                                fontSize: 11, color: Colors.grey[500])),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            )).toList(),

                          if (!isCompleted) ...[
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () => _showExtendDialog(context, docId, data, days, total),
                                icon: const Icon(Icons.add_circle_outline, size: 18),
                                label: Text('Perpanjang Penitipan',
                                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.orange[700],
                                  side: BorderSide(color: Colors.orange[400]!),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (status == _CheckoutStatus.today || status == _CheckoutStatus.overdue)
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () => _showCompleteDialog(
                                      context, docId, data, total, dp, isPaid),
                                  icon: const Icon(Icons.check_circle, size: 18),
                                  label: Text('Selesai & Bayar',
                                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green[600],
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                              ),
                          ] else ...[
                            const SizedBox(height: 8),
                            Center(child: Text('✅ Penitipan selesai',
                                style: GoogleFonts.poppins(color: Colors.grey[500], fontSize: 13))),
                          ],
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddPenitipanDialog(context),
        backgroundColor: Colors.orange[700],
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildBadge(_CheckoutStatus status) {
    switch (status) {
      case _CheckoutStatus.today:
        return _badge('🐱 Dijemput!', Colors.green[600]!);
      case _CheckoutStatus.overdue:
        return _badge('⚠️ Terlambat!', Colors.red[600]!);
      case _CheckoutStatus.completed:
        return _badge('✅ Selesai', Colors.grey[500]!);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _badge(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
    child: Text(text, style: GoogleFonts.poppins(
        color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
  );

  Widget _buildWAButton({required VoidCallback onTap, required _CheckoutStatus status}) {
    final isUrgent = status == _CheckoutStatus.today || status == _CheckoutStatus.overdue;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF25D366),
          borderRadius: BorderRadius.circular(20),
          boxShadow: isUrgent ? [BoxShadow(
              color: const Color(0xFF25D366).withOpacity(0.4),
              blurRadius: 8, offset: const Offset(0, 3))] : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.chat, color: Colors.white, size: 14),
            const SizedBox(width: 5),
            Text('Chat WA', style: GoogleFonts.poppins(
                color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, {bool isBold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600])),
          Text(value, style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: valueColor)),
        ],
      ),
    );
  }

  void _showAddNoteDialog(BuildContext context, String docId, String catName) {
    final noteCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Tambah Catatan - $catName',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15)),
        content: TextField(
          controller: noteCtrl,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'contoh: Kucing tidak mau makan, sudah dibawa ke dokter Rp 150.000',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx),
              child: Text('Batal', style: GoogleFonts.poppins())),
          ElevatedButton(
            onPressed: () async {
              if (noteCtrl.text.isEmpty) return;
              final now = DateTime.now();
              final dateStr = '${now.day}/${now.month}/${now.year} ${now.hour}:${now.minute.toString().padLeft(2, '0')}';
              await _firestore.collection('services').doc(docId).update({
                'notes': FieldValue.arrayUnion([
                  {'text': noteCtrl.text, 'date': dateStr}
                ]),
              });
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[700], foregroundColor: Colors.white),
            child: Text('Simpan', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  void _showExtendDialog(BuildContext context, String docId,
      Map<String, dynamic> data, int currentDays, double currentTotal) {
    final addDaysCtrl = TextEditingController();
    final currentCheckOut = DateTime.parse(data['checkOut']);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) {
          final addDays = int.tryParse(addDaysCtrl.text) ?? 0;
          final newCheckOut = currentCheckOut.add(Duration(days: addDays));
          final additionalCost = _pricePerDay * addDays;
          final newTotal = currentTotal + additionalCost;

          return AlertDialog(
            title: Text('Perpanjang Penitipan',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Tanggal keluar saat ini: ${currentCheckOut.day}/${currentCheckOut.month}/${currentCheckOut.year}',
                    style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600])),
                const SizedBox(height: 12),
                TextField(
                  controller: addDaysCtrl,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setDialog(() {}),
                  decoration: InputDecoration(
                    labelText: 'Tambah berapa hari?',
                    prefixIcon: const Icon(Icons.calendar_today),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                if (addDays > 0) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange[200]!),
                    ),
                    child: Column(children: [
                      _detailRow('Tanggal keluar baru',
                          '${newCheckOut.day}/${newCheckOut.month}/${newCheckOut.year}'),
                      _detailRow('Biaya tambahan', 'Rp ${additionalCost.toRupiah()}',
                          valueColor: Colors.orange[700]),
                      const Divider(height: 12),
                      _detailRow('Total baru', 'Rp ${newTotal.toRupiah()}',
                          isBold: true, valueColor: Colors.green[700]),
                    ]),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx),
                  child: Text('Batal', style: GoogleFonts.poppins())),
              ElevatedButton(
                onPressed: addDays > 0 ? () async {
                  await _firestore.collection('services').doc(docId).update({
                    'checkOut': newCheckOut.toIso8601String(),
                    'days': currentDays + addDays,
                    'total': newTotal,
                  });
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Penitipan berhasil diperpanjang!'),
                            backgroundColor: Colors.green));
                  }
                } : null,
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[700], foregroundColor: Colors.white),
                child: Text('Perpanjang', style: GoogleFonts.poppins()),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showCompleteDialog(BuildContext context, String docId,
      Map<String, dynamic> data, double total, double dp, bool isPaid) {
    final sisa = total - dp;
    String selectedPayment = 'Cash';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          title: Text('Selesai & Bayar',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Column(children: [
                  _detailRow('Total', 'Rp ${total.toRupiah()}'),
                  if (dp > 0) _detailRow('DP sudah dibayar', 'Rp ${dp.toRupiah()}',
                      valueColor: Colors.orange[700]),
                  const Divider(height: 12),
                  _detailRow(
                    dp > 0 ? 'Sisa yang harus dibayar' : 'Total pembayaran',
                    'Rp ${sisa.toRupiah()}',
                    isBold: true, valueColor: Colors.green[700],
                  ),
                ]),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(padding: const EdgeInsets.only(left: 12, top: 8),
                        child: Text('Metode Pembayaran',
                            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]))),
                    RadioListTile<String>(title: Text('Cash', style: GoogleFonts.poppins()),
                        value: 'Cash', groupValue: selectedPayment,
                        onChanged: (v) => setDialog(() => selectedPayment = v!), dense: true),
                    RadioListTile<String>(title: Text('QRIS', style: GoogleFonts.poppins()),
                        value: 'QRIS', groupValue: selectedPayment,
                        onChanged: (v) => setDialog(() => selectedPayment = v!), dense: true),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx),
                child: Text('Batal', style: GoogleFonts.poppins())),
            ElevatedButton(
              onPressed: () async {
                await _firestore.collection('services').doc(docId).update({
                  'isCompleted': true,
                  'isPaid': true,
                  'finalPaymentMethod': selectedPayment,
                  'completedAt': DateTime.now().toIso8601String(),
                });
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Penitipan selesai! Terima kasih 🐱'),
                          backgroundColor: Colors.green));
                }
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600], foregroundColor: Colors.white),
              child: Text('Konfirmasi Selesai',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddPenitipanDialog(BuildContext context) {
    final catNameCtrl = TextEditingController();
    final ownerNameCtrl = TextEditingController();
    final ownerPhoneCtrl = TextEditingController();
    final discountCtrl = TextEditingController();
    final dpCtrl = TextEditingController();
    DateTime checkIn = DateTime.now();
    DateTime checkOut = DateTime.now().add(const Duration(days: 1));
    String selectedPayment = 'Cash';
    bool withDP = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (ctx, setDialog) {
          final days = checkOut.difference(checkIn).inDays + 1; // fix: hitung hari masuk
          final discount = double.tryParse(discountCtrl.text) ?? 0;
          final dp = double.tryParse(dpCtrl.text) ?? 0;
          final total = (_pricePerDay * days) - discount;

          return AlertDialog(
            title: Text('Tambah Penitipan',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange[200]!),
                    ),
                    child: Row(children: [
                      Icon(Icons.info_outline, size: 16, color: Colors.orange[700]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _priceLoaded
                              ? 'Harga penitipan: Rp ${_pricePerDay.toRupiah()}/hari (sudah include makanan)'
                              : 'Memuat harga...',
                          style: GoogleFonts.poppins(fontSize: 12, color: Colors.orange[700]),
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 12),
                  TextField(controller: catNameCtrl,
                      decoration: InputDecoration(labelText: 'Nama Kucing',
                          prefixIcon: const Icon(Icons.pets),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)))),
                  const SizedBox(height: 12),
                  TextField(controller: ownerNameCtrl,
                      decoration: InputDecoration(labelText: 'Nama Owner',
                          prefixIcon: const Icon(Icons.person),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)))),
                  const SizedBox(height: 12),
                  TextField(controller: ownerPhoneCtrl, keyboardType: TextInputType.phone,
                      decoration: InputDecoration(labelText: 'No. WA Owner',
                          hintText: 'contoh: 08123456789',
                          prefixIcon: const Icon(Icons.phone),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)))),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(context: ctx,
                          initialDate: checkIn, firstDate: DateTime(2020), lastDate: DateTime(2030));
                      if (picked != null) {
                        setDialog(() {
                          checkIn = picked;
                          if (checkOut.isBefore(checkIn)) {
                            checkOut = checkIn.add(const Duration(days: 1));
                          }
                        });
                      }
                    },
                    child: _dateField('Tanggal Masuk', checkIn, Icons.login),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(context: ctx,
                          initialDate: checkOut,
                          firstDate: checkIn.add(const Duration(days: 1)),
                          lastDate: DateTime(2030));
                      if (picked != null) setDialog(() => checkOut = picked);
                    },
                    child: _dateFieldWithBadge('Tanggal Keluar', checkOut, Icons.logout, '$days hari'),
                  ),
                  const SizedBox(height: 12),
                  TextField(controller: discountCtrl, keyboardType: TextInputType.number,
                      onChanged: (_) => setDialog(() {}),
                      decoration: InputDecoration(labelText: 'Diskon (opsional)',
                          prefixText: 'Rp ',
                          prefixIcon: const Icon(Icons.discount),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)))),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8)),
                    child: Column(children: [
                      SwitchListTile(
                        title: Text('Bayar DP dulu', style: GoogleFonts.poppins(fontSize: 14)),
                        subtitle: Text('Sisa dibayar saat penjemputan',
                            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[500])),
                        value: withDP,
                        activeColor: Colors.orange[700],
                        onChanged: (v) => setDialog(() => withDP = v),
                        dense: true,
                      ),
                      if (withDP)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                          child: TextField(
                            controller: dpCtrl,
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setDialog(() {}),
                            decoration: InputDecoration(
                              labelText: 'Nominal DP',
                              prefixText: 'Rp ',
                              prefixIcon: const Icon(Icons.payments),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                    ]),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(padding: const EdgeInsets.only(left: 12, top: 8),
                            child: Text(withDP ? 'Metode Pembayaran DP' : 'Metode Pembayaran',
                                style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]))),
                        RadioListTile<String>(title: Text('Cash', style: GoogleFonts.poppins()),
                            value: 'Cash', groupValue: selectedPayment,
                            onChanged: (v) => setDialog(() => selectedPayment = v!), dense: true),
                        RadioListTile<String>(title: Text('QRIS', style: GoogleFonts.poppins()),
                            value: 'QRIS', groupValue: selectedPayment,
                            onChanged: (v) => setDialog(() => selectedPayment = v!), dense: true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange[200]!),
                    ),
                    child: Column(children: [
                      Text('Ringkasan', style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold, color: Colors.orange[700])),
                      const SizedBox(height: 8),
                      _detailRow('$days hari × Rp ${_pricePerDay.toRupiah()}',
                          'Rp ${(_pricePerDay * days).toRupiah()}'),
                      if (discount > 0)
                        _detailRow('Diskon', '- Rp ${discount.toRupiah()}',
                            valueColor: Colors.red[600]),
                      const Divider(),
                      _detailRow('Total', 'Rp ${total.toRupiah()}',
                          isBold: true, valueColor: Colors.green[700]),
                      if (withDP && dp > 0) ...[
                        _detailRow('DP', 'Rp ${dp.toRupiah()}', valueColor: Colors.orange[700]),
                        _detailRow('Sisa', 'Rp ${(total - dp).toRupiah()}',
                            valueColor: Colors.red[600]),
                      ],
                    ]),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx),
                  child: Text('Batal', style: GoogleFonts.poppins())),
              ElevatedButton(
                onPressed: () async {
                  if (catNameCtrl.text.isEmpty || !_priceLoaded) return;
                  await _firestore.collection('services').add({
                    'type': 'penitipan',
                    'catName': catNameCtrl.text,
                    'ownerName': ownerNameCtrl.text,
                    'ownerPhone': ownerPhoneCtrl.text,
                    'checkIn': checkIn.toIso8601String(),
                    'checkOut': checkOut.toIso8601String(),
                    'days': days,
                    'pricePerDay': _pricePerDay,
                    'discount': discount,
                    'total': total,
                    'dp': withDP ? dp : 0,
                    'isPaid': !withDP,
                    'isCompleted': false,
                    'paymentMethod': selectedPayment,
                    'notes': [],
                    'dateTime': DateTime.now().toIso8601String(),
                  });
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Penitipan berhasil dicatat!'),
                            backgroundColor: Colors.green));
                  }
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[700], foregroundColor: Colors.white),
                child: Text('Simpan', style: GoogleFonts.poppins()),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _dateField(String label, DateTime date, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[400]!),
          borderRadius: BorderRadius.circular(8)),
      child: Row(children: [
        Icon(icon, color: Colors.orange[700], size: 20),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[600])),
          Text('${date.day}/${date.month}/${date.year}',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        ]),
      ]),
    );
  }

  Widget _dateFieldWithBadge(String label, DateTime date, IconData icon, String badge) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[400]!),
          borderRadius: BorderRadius.circular(8)),
      child: Row(children: [
        Icon(icon, color: Colors.orange[700], size: 20),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[600])),
          Text('${date.day}/${date.month}/${date.year}',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        ]),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
              color: Colors.orange[100], borderRadius: BorderRadius.circular(8)),
          child: Text(badge, style: GoogleFonts.poppins(
              color: Colors.orange[800], fontWeight: FontWeight.bold, fontSize: 13)),
        ),
      ]),
    );
  }
}

enum _CheckoutStatus { upcoming, today, overdue, completed }