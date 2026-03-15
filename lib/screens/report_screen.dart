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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildPeriodSelector()),
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

  Widget _buildPeriodSelector() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.only(
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
              SizedBox(width: 8),
              Text(
                'Periode Laporan:',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[700],
                ),
              ),
              Spacer(),
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
          SizedBox(height: 12),
          InkWell(
            onTap: () => _selectDate(context),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                  SizedBox(width: 8),
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
    return StreamBuilder<QuerySnapshot>(
      stream: _getFilteredOrdersStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Container(
            padding: EdgeInsets.all(16),
            child: Text('Error: ${snapshot.error}',
                style: GoogleFonts.poppins()),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final orders = snapshot.data!.docs;
        final financialData = _calculateFinancials(orders);

        return Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      'Total Pesanan',
                      '${financialData['totalOrders']}',
                      Icons.receipt_long,
                      Colors.orange,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _buildSummaryCard(
                      'Total Item',
                      '${financialData['totalItems']}',
                      Icons.inventory,
                      Colors.amber,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      'Total Modal',
                      'Rp ${_formatCurrency(financialData['totalCost'])}',
                      Icons.money_off,
                      Colors.red,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _buildSummaryCard(
                      'Omset',
                      'Rp ${_formatCurrency(financialData['omset'])}',
                      Icons.trending_up,
                      Colors.green,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
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
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.account_balance_wallet,
                        color: Colors.white, size: 28),
                    SizedBox(height: 6),
                    Text(
                      'Laba Bersih',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Rp ${_formatCurrency(financialData['netProfit'])}',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Margin: ${_calculateMarginPercentage(financialData['omset'], financialData['netProfit'])}%',
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
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 32),
          SizedBox(height: 8),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 4),
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
    return StreamBuilder<QuerySnapshot>(
      stream: _getFilteredOrdersStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Error: ${snapshot.error}',
                    style: GoogleFonts.poppins()),
              ),
            ),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }

        final orders = snapshot.data!.docs;

        if (orders.isEmpty) {
          return SliverToBoxAdapter(
            child: Container(
              height: 300,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.analytics, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'Belum ada laporan pesanan\nuntuk periode ${_selectedPeriod.toLowerCase()}',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                          fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final orderData =
                  orders[index].data() as Map<String, dynamic>;
              final dateTime = DateTime.parse(orderData['dateTime']);
              final items = orderData['items'] as List;

              double orderProfit = _calculateOrderProfit(items);
              double orderCost = _calculateOrderCost(items);

              return Card(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Theme(
                  data: Theme.of(context)
                      .copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    title: Text(
                      'Pesanan ${dateTime.day}/${dateTime.month}/${dateTime.year}',
                      style:
                          GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Waktu: ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}',
                          style: GoogleFonts.poppins(),
                        ),
                        Text(
                          'Pembayaran: ${orderData['paymentMethod']}',
                          style: GoogleFonts.poppins(),
                        ),
                        SizedBox(height: 4),
                        // 🔄 Diganti dari Row ke Column supaya tidak overflow
                        Text(
                          'Modal: Rp ${_formatCurrency(orderCost)}',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            color: Colors.red[600],
                          ),
                        ),
                        Text(
                          'Omset: Rp ${_formatCurrency(orderData['total'].toDouble())}',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            color: Colors.green[600],
                          ),
                        ),
                        Text(
                          'Laba: Rp ${_formatCurrency(orderProfit)}',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange[700],
                          ),
                        ),
                      ],
                    ),
                    trailing: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange[700],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${items.fold<int>(0, (sum, item) => sum + (item['quantity'] as int))} pcs',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    children: [
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Detail Item:',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 12),
                            ...items.map<Widget>((item) {
                              double buyPrice =
                                  _safeToDouble(item['buyPrice']);
                              double sellPrice =
                                  _safeToDouble(item['price']);
                              int quantity = item['quantity'] as int;
                              double itemProfit =
                                  (sellPrice - buyPrice) * quantity;
                              double itemCost = buyPrice * quantity;
                              double itemRevenue = sellPrice * quantity;

                              return Container(
                                margin: EdgeInsets.only(bottom: 12),
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: Colors.grey[200]!),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            item['productName'],
                                            style: GoogleFonts.poppins(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          '${quantity}x',
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 8),
                                    // 🔄 Diganti dari Row ke Column supaya tidak overflow
                                    Text(
                                      'Harga Beli: Rp ${_formatCurrency(buyPrice)}',
                                      style: GoogleFonts.poppins(
                                        color: Colors.red[600],
                                        fontSize: 13,
                                      ),
                                    ),
                                    Text(
                                      'Harga Jual: Rp ${_formatCurrency(sellPrice)}',
                                      style: GoogleFonts.poppins(
                                        color: Colors.green[600],
                                        fontSize: 13,
                                      ),
                                    ),
                                    Text(
                                      'Modal: Rp ${_formatCurrency(itemCost)}',
                                      style: GoogleFonts.poppins(
                                        color: Colors.red[600],
                                        fontSize: 13,
                                      ),
                                    ),
                                    Text(
                                      'Omset: Rp ${_formatCurrency(itemRevenue)}',
                                      style: GoogleFonts.poppins(
                                        color: Colors.green[600],
                                        fontSize: 13,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Container(
                                      width: double.infinity,
                                      padding: EdgeInsets.symmetric(
                                          vertical: 8),
                                      decoration: BoxDecoration(
                                        color: itemProfit > 0
                                            ? Colors.green[100]
                                            : Colors.red[100],
                                        borderRadius:
                                            BorderRadius.circular(6),
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
            },
            childCount: orders.length,
          ),
        );
      },
    );
  }

  double _safeToDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Stream<QuerySnapshot> _getFilteredOrdersStream() {
    DateTime startDate, endDate;

    switch (_selectedPeriod) {
      case 'Harian':
        startDate = DateTime(
            _selectedDate.year, _selectedDate.month, _selectedDate.day);
        endDate = startDate.add(Duration(days: 1));
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
        endDate = startDate.add(Duration(days: 1));
    }

    return _firestore
        .collection('orders')
        .where('dateTime',
            isGreaterThanOrEqualTo: startDate.toIso8601String())
        .where('dateTime', isLessThan: endDate.toIso8601String())
        .orderBy('dateTime', descending: true)
        .snapshots();
  }

  Map<String, dynamic> _calculateFinancials(
      List<QueryDocumentSnapshot> orders) {
    int totalOrders = orders.length;
    int totalItems = 0;
    double omset = 0;
    double totalCost = 0;
    double netProfit = 0;

    for (var order in orders) {
      final orderData = order.data() as Map<String, dynamic>;
      final items = orderData['items'] as List;

      totalItems += items.fold<int>(
          0, (sum, item) => sum + (item['quantity'] as int));
      omset += _safeToDouble(orderData['total']);

      for (var item in items) {
        double buyPrice = _safeToDouble(item['buyPrice']);
        double sellPrice = _safeToDouble(item['price']);
        int quantity = item['quantity'] as int;

        totalCost += buyPrice * quantity;
        netProfit += (sellPrice - buyPrice) * quantity;
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

  String _calculateMarginPercentage(double revenue, double profit) {
    if (revenue == 0) return '0';
    return ((profit / revenue) * 100).toStringAsFixed(1);
  }

  String _calculateItemMargin(double sellPrice, double buyPrice) {
    if (sellPrice == 0) return '0';
    return (((sellPrice - buyPrice) / sellPrice) * 100).toStringAsFixed(1);
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
        setState(
            () => _selectedDate = DateTime(picked.year, picked.month, 1));
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