import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class ReportScreen extends StatefulWidget {
  @override
  _ReportScreenState createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _selectedPeriod = 'Harian';
  DateTime _selectedDate = DateTime.now();
  String _selectedFilter = 'Semua'; // Filter: Semua, Produk, Service

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildPeriodSelector()),
            SliverToBoxAdapter(child: _buildFilterSelector()),
            SliverToBoxAdapter(child: _buildFinancialSummary()),
            SliverToBoxAdapter(
              child: Divider(thickness: 1, color: Colors.grey[300]),
            ),
            _buildOrdersSliver(),
          ],
        ),
      ),
    );
  }

  // ── Filter Produk / Service / Semua ───────────────────────────────────────
  Widget _buildFilterSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: ['Semua', 'Produk', 'Service'].map((filter) {
          final isSelected = _selectedFilter == filter;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedFilter = filter),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.orange[700] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected
                        ? Colors.orange[700]!
                        : Colors.grey[300]!,
                  ),
                ),
                child: Text(
                  filter,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.date_range, color: Colors.orange[700]),
              const SizedBox(width: 8),
              Text(
                'Periode Laporan:',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[700],
                ),
              ),
              const Spacer(),
              DropdownButton<String>(
                value: _selectedPeriod,
                items: ['Harian', 'Bulanan', 'Tahunan'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value, style: GoogleFonts.poppins()),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() => _selectedPeriod = newValue!);
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () => _selectDate(context),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.orange[300]!),
                borderRadius: BorderRadius.circular(8),
                color: Colors.white,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.calendar_today,
                      size: 20, color: Colors.orange[700]),
                  const SizedBox(width: 8),
                  Text(
                    _getDateText(),
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialSummary() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _calculateAllFinancials(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return const SizedBox();
        }

        final data = snapshot.data!;

        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      'Total Transaksi',
                      '${data['totalOrders']}',
                      Icons.receipt_long,
                      Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSummaryCard(
                      'Total Item',
                      '${data['totalItems']}',
                      Icons.inventory,
                      Colors.amber,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      'Total Modal',
                      'Rp ${_formatCurrency(data['totalCost'])}',
                      Icons.money_off,
                      Colors.red,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSummaryCard(
                      'Omset',
                      'Rp ${_formatCurrency(data['omset'])}',
                      Icons.trending_up,
                      Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange[500]!, Colors.orange[800]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.35),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.account_balance_wallet,
                        color: Colors.white, size: 28),
                    const SizedBox(height: 6),
                    Text(
                      'Laba Bersih',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Rp ${_formatCurrency(data['netProfit'])}',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Margin: ${_calculateMarginPercentage(data['omset'], data['netProfit'])}%',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.white70,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersSliver() {
    // Tampilkan berdasarkan filter
    if (_selectedFilter == 'Produk') {
      return _buildProductOrdersSliver();
    } else if (_selectedFilter == 'Service') {
      return _buildServiceOrdersSliver();
    } else {
      // Semua: gabungkan keduanya
      return _buildAllOrdersSliver();
    }
  }

  // ── Sliver untuk pesanan produk ───────────────────────────────────────────
  Widget _buildProductOrdersSliver() {
    return StreamBuilder<QuerySnapshot>(
      stream: _getFilteredOrdersStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SliverToBoxAdapter(
              child: Center(child: CircularProgressIndicator()));
        }
        final orders = snapshot.data!.docs;
        if (orders.isEmpty) {
          return SliverToBoxAdapter(child: _emptyState('produk'));
        }
        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => _buildProductOrderCard(orders[index]),
            childCount: orders.length,
          ),
        );
      },
    );
  }

  // ── Sliver untuk service ──────────────────────────────────────────────────
  Widget _buildServiceOrdersSliver() {
    return StreamBuilder<QuerySnapshot>(
      stream: _getFilteredServicesStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SliverToBoxAdapter(
              child: Center(child: CircularProgressIndicator()));
        }
        final services = snapshot.data!.docs;
        if (services.isEmpty) {
          return SliverToBoxAdapter(child: _emptyState('service'));
        }
        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => _buildServiceCard(services[index]),
            childCount: services.length,
          ),
        );
      },
    );
  }

  // ── Sliver untuk semua (produk + service) ─────────────────────────────────
  Widget _buildAllOrdersSliver() {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section produk
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              '🛒 Penjualan Produk',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Colors.orange[700],
              ),
            ),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: _getFilteredOrdersStream(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final orders = snapshot.data!.docs;
              if (orders.isEmpty) return _emptyState('produk');
              return Column(
                children: orders
                    .map((doc) => _buildProductOrderCard(doc))
                    .toList(),
              );
            },
          ),
          // Section service
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              '✂️ Jasa Service',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Colors.orange[700],
              ),
            ),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: _getFilteredServicesStream(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final services = snapshot.data!.docs;
              if (services.isEmpty) return _emptyState('service');
              return Column(
                children: services
                    .map((doc) => _buildServiceCard(doc))
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _emptyState(String type) {
    return Container(
      height: 120,
      child: Center(
        child: Text(
          'Belum ada data $type\npada periode ini',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildProductOrderCard(QueryDocumentSnapshot doc) {
    final orderData = doc.data() as Map<String, dynamic>;
    final dateTime = DateTime.parse(orderData['dateTime']);
    final items = (orderData['items'] as List?) ?? [];
    double orderProfit = _calculateOrderProfit(items);
    double orderCost = _calculateOrderCost(items);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Theme(
        data:
            Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(
            'Pesanan ${dateTime.day}/${dateTime.month}/${dateTime.year}',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                  'Waktu: ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}',
                  style: GoogleFonts.poppins()),
              Text('Pembayaran: ${orderData['paymentMethod']}',
                  style: GoogleFonts.poppins()),
              const SizedBox(height: 4),
              Text(
                'Modal: Rp ${_formatCurrency(orderCost)}',
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    color: Colors.red[600]),
              ),
              Text(
                'Omset: Rp ${_formatCurrency(orderData['total'].toDouble())}',
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    color: Colors.green[600]),
              ),
              Text(
                'Laba: Rp ${_formatCurrency(orderProfit)}',
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[700]),
              ),
            ],
          ),
          trailing: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.orange[700],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${items.fold<int>(0, (sum, item) => sum + (item['quantity'] as int))} pcs',
              style: GoogleFonts.poppins(
                  color: Colors.white, fontSize: 12),
            ),
          ),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Detail Item:',
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  ...items.map<Widget>((item) {
                    double buyPrice = _safeToDouble(item['buyPrice']);
                    double sellPrice = _safeToDouble(item['price']);
                    int quantity = item['quantity'] as int;
                    double itemProfit =
                        (sellPrice - buyPrice) * quantity;
                    double itemCost = buyPrice * quantity;
                    double itemRevenue = sellPrice * quantity;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(item['productName'],
                                    style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15)),
                              ),
                              Text('${quantity}x',
                                  style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                              'Harga Beli: Rp ${_formatCurrency(buyPrice)}',
                              style: GoogleFonts.poppins(
                                  color: Colors.red[600], fontSize: 13)),
                          Text(
                              'Harga Jual: Rp ${_formatCurrency(sellPrice)}',
                              style: GoogleFonts.poppins(
                                  color: Colors.green[600],
                                  fontSize: 13)),
                          Text('Modal: Rp ${_formatCurrency(itemCost)}',
                              style: GoogleFonts.poppins(
                                  color: Colors.red[600], fontSize: 13)),
                          Text(
                              'Omset: Rp ${_formatCurrency(itemRevenue)}',
                              style: GoogleFonts.poppins(
                                  color: Colors.green[600],
                                  fontSize: 13)),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding:
                                const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: itemProfit > 0
                                  ? Colors.green[100]
                                  : Colors.red[100],
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Laba: Rp ${_formatCurrency(itemProfit)} (${_calculateItemMargin(sellPrice, buyPrice)}%)',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                color: itemProfit > 0
                                    ? Colors.green[700]
                                    : Colors.red[700],
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCard(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final isGrooming = data['type'] == 'grooming';
    final dateTime = DateTime.parse(data['dateTime']);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Theme(
        data:
            Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              shape: BoxShape.circle,
            ),
            child: Icon(
              isGrooming ? Icons.content_cut : Icons.home,
              color: Colors.orange[700],
              size: 20,
            ),
          ),
          title: Text(
            '${isGrooming ? 'Grooming' : 'Penitipan'} - ${data['catName']}',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}',
                style: GoogleFonts.poppins(fontSize: 12),
              ),
              Text('Pembayaran: ${data['paymentMethod']}',
                  style: GoogleFonts.poppins(fontSize: 12)),
              Text(
                'Total: Rp ${_formatCurrency((data['total'] ?? data['price']).toDouble())}',
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    color: Colors.green[600]),
              ),
            ],
          ),
          trailing: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isGrooming ? Colors.purple[400] : Colors.blue[400],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              isGrooming ? 'Grooming' : 'Nitip',
              style: GoogleFonts.poppins(
                  color: Colors.white, fontSize: 12),
            ),
          ),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: isGrooming
                  ? _buildGroomingDetail(data)
                  : _buildPenitipanDetail(data),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroomingDetail(Map<String, dynamic> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _detailRow('Jenis Grooming', data['serviceType']),
        _detailRow(
            'Total', 'Rp ${_formatCurrency(data['price'].toDouble())}',
            isBold: true, valueColor: Colors.green[700]),
      ],
    );
  }

  Widget _buildPenitipanDetail(Map<String, dynamic> data) {
    final days = data['days'] as int;
    final bringFood = data['bringFood'] as bool;
    final discount = (data['discount'] as num).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _detailRow('Jumlah hari', '$days hari'),
        _detailRow('Harga/hari',
            'Rp ${_formatCurrency((data['pricePerDay'] as num).toDouble())}'),
        _detailRow('Bawa makanan', bringFood ? 'Ya' : 'Tidak'),
        if (!bringFood)
          _detailRow('Harga makanan/hari',
              'Rp ${_formatCurrency((data['foodPricePerDay'] as num).toDouble())}'),
        if (discount > 0)
          _detailRow('Diskon', '- Rp ${_formatCurrency(discount)}',
              valueColor: Colors.red[600]),
        const Divider(),
        _detailRow(
            'Total', 'Rp ${_formatCurrency((data['total'] as num).toDouble())}',
            isBold: true, valueColor: Colors.green[700]),
      ],
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
          Text(value,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight:
                    isBold ? FontWeight.bold : FontWeight.w500,
                color: valueColor,
              )),
        ],
      ),
    );
  }

  // ── Streams ───────────────────────────────────────────────────────────────

  Stream<QuerySnapshot> _getFilteredOrdersStream() {
    final range = _getDateRange();
    return _firestore
        .collection('orders')
        .where('dateTime',
            isGreaterThanOrEqualTo: range['start']!.toIso8601String())
        .where('dateTime',
            isLessThan: range['end']!.toIso8601String())
        .orderBy('dateTime', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> _getFilteredServicesStream() {
    final range = _getDateRange();
    return _firestore
        .collection('services')
        .where('dateTime',
            isGreaterThanOrEqualTo: range['start']!.toIso8601String())
        .where('dateTime',
            isLessThan: range['end']!.toIso8601String())
        .orderBy('dateTime', descending: true)
        .snapshots();
  }

  Map<String, DateTime> _getDateRange() {
    DateTime startDate, endDate;
    switch (_selectedPeriod) {
      case 'Harian':
        startDate = DateTime(
            _selectedDate.year, _selectedDate.month, _selectedDate.day);
        endDate = startDate.add(const Duration(days: 1));
        break;
      case 'Bulanan':
        startDate =
            DateTime(_selectedDate.year, _selectedDate.month, 1);
        endDate =
            DateTime(_selectedDate.year, _selectedDate.month + 1, 1);
        break;
      case 'Tahunan':
        startDate = DateTime(_selectedDate.year, 1, 1);
        endDate = DateTime(_selectedDate.year + 1, 1, 1);
        break;
      default:
        startDate = DateTime.now();
        endDate = startDate.add(const Duration(days: 1));
    }
    return {'start': startDate, 'end': endDate};
  }

  // ── Kalkulasi finansial ───────────────────────────────────────────────────

  Future<Map<String, dynamic>> _calculateAllFinancials() async {
    final range = _getDateRange();
    int totalOrders = 0;
    int totalItems = 0;
    double omset = 0;
    double totalCost = 0;
    double netProfit = 0;

    // Hitung dari orders (produk)
    if (_selectedFilter == 'Semua' || _selectedFilter == 'Produk') {
      final ordersSnap = await _firestore
          .collection('orders')
          .where('dateTime',
              isGreaterThanOrEqualTo: range['start']!.toIso8601String())
          .where('dateTime',
              isLessThan: range['end']!.toIso8601String())
          .get();

      totalOrders += ordersSnap.docs.length;
      for (var doc in ordersSnap.docs) {
        final data = doc.data();
        final items = data['items'] as List;
        totalItems += items.fold<int>(
            0, (sum, item) => sum + (item['quantity'] as int));
        omset += _safeToDouble(data['total']);
        for (var item in items) {
          double buyPrice = _safeToDouble(item['buyPrice']);
          double sellPrice = _safeToDouble(item['price']);
          int qty = item['quantity'] as int;
          totalCost += buyPrice * qty;
          netProfit += (sellPrice - buyPrice) * qty;
        }
      }
    }

    // Hitung dari services (grooming & penitipan)
    if (_selectedFilter == 'Semua' || _selectedFilter == 'Service') {
      final servicesSnap = await _firestore
          .collection('services')
          .where('dateTime',
              isGreaterThanOrEqualTo: range['start']!.toIso8601String())
          .where('dateTime',
              isLessThan: range['end']!.toIso8601String())
          .get();

      totalOrders += servicesSnap.docs.length;
      for (var doc in servicesSnap.docs) {
        final data = doc.data();
        // Service tidak punya modal, jadi semua revenue = laba
        final revenue = data['type'] == 'grooming'
            ? _safeToDouble(data['price'])
            : _safeToDouble(data['total']);
        omset += revenue;
        netProfit += revenue;
        totalItems += 1;
      }
    }

    return {
      'totalOrders': totalOrders,
      'totalItems': totalItems,
      'omset': omset,
      'totalCost': totalCost,
      'netProfit': netProfit,
    };
  }

  double _calculateOrderProfit(List items) {
    double profit = 0;
    for (var item in items) {
      double buyPrice = _safeToDouble(item['buyPrice']);
      double sellPrice = _safeToDouble(item['price']);
      int quantity = item['quantity'] as int;
      profit += (sellPrice - buyPrice) * quantity;
    }
    return profit;
  }

  double _calculateOrderCost(List items) {
    double cost = 0;
    for (var item in items) {
      double buyPrice = _safeToDouble(item['buyPrice']);
      int quantity = item['quantity'] as int;
      cost += buyPrice * quantity;
    }
    return cost;
  }

  double _safeToDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  String _calculateMarginPercentage(double revenue, double profit) {
    if (revenue == 0) return '0';
    return ((profit / revenue) * 100).toStringAsFixed(1);
  }

  String _calculateItemMargin(double sellPrice, double buyPrice) {
    if (sellPrice == 0) return '0';
    return (((sellPrice - buyPrice) / sellPrice) * 100)
        .toStringAsFixed(1);
  }

  String _formatCurrency(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }

  String _getDateText() {
    switch (_selectedPeriod) {
      case 'Harian':
        return '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}';
      case 'Bulanan':
        final months = [
          'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
          'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
        ];
        return '${months[_selectedDate.month - 1]} ${_selectedDate.year}';
      case 'Tahunan':
        return '${_selectedDate.year}';
      default:
        return '';
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    if (_selectedPeriod == 'Harian') {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: _selectedDate,
        firstDate: DateTime(2020),
        lastDate: DateTime.now(),
      );
      if (picked != null && picked != _selectedDate) {
        setState(() => _selectedDate = picked);
      }
    } else if (_selectedPeriod == 'Bulanan') {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: _selectedDate,
        firstDate: DateTime(2020),
        lastDate: DateTime.now(),
        selectableDayPredicate: (DateTime date) => date.day == 1,
      );
      if (picked != null) {
        setState(() =>
            _selectedDate = DateTime(picked.year, picked.month, 1));
      }
    } else if (_selectedPeriod == 'Tahunan') {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: _selectedDate,
        firstDate: DateTime(2020),
        lastDate: DateTime.now(),
        selectableDayPredicate: (DateTime date) =>
            date.day == 1 && date.month == 1,
      );
      if (picked != null) {
        setState(() => _selectedDate = DateTime(picked.year, 1, 1));
      }
    }
  }
}