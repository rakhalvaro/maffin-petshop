import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'product_screen.dart';
import 'order_screen.dart';
import 'report_screen.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    ProductScreen(),
    OrderScreen(),
    ReportScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orange[700],
        toolbarHeight: 80, // Lebih tinggi supaya muat 3 baris teks
        centerTitle: true,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Bismillah
            Text(
              'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
              style: TextStyle(
                fontFamily: 'serif',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 1.4,
              ),
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
            ),
            // Shalawat
            Text(
              'اللَّهُمَّ صَلِّ عَلَى سَيِّدِنَا مُحَمَّدٍ',
              style: TextStyle(
                fontFamily: 'serif',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.white.withOpacity(0.92),
                height: 1.4,
              ),
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
            ),
            // Nama app
            Text(
              'Maffin Petshop',
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w400,
                color: Colors.white.withOpacity(0.75),
                letterSpacing: 1.2,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.orange[700],
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory),
            label: 'Produk',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Pesanan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Laporan',
          ),
        ],
      ),
    );
  }
}