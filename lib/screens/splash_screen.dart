import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'main_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _taglineController;

  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _textOpacity;
  late Animation<Offset> _textSlide;
  late Animation<double> _taglineOpacity;

  @override
  void initState() {
    super.initState();

    // Controller untuk logo (muncul pertama)
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );

    // Controller untuk teks nama app
    _textController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    // Controller untuk tagline
    _taglineController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    // Animasi logo: scale dari kecil + fade in
    _logoScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: const Interval(0.0, 0.6)),
    );

    // Animasi teks: slide dari bawah + fade in
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeIn),
    );
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOut),
    );

    // Animasi tagline: fade in
    _taglineOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _taglineController, curve: Curves.easeIn),
    );

    // Jalankan animasi secara berurutan
    _runAnimations();
  }

  Future<void> _runAnimations() async {
    // Logo muncul
    await Future.delayed(const Duration(milliseconds: 200));
    _logoController.forward();

    // Teks nama muncul
    await Future.delayed(const Duration(milliseconds: 500));
    _textController.forward();

    // Tagline muncul
    await Future.delayed(const Duration(milliseconds: 400));
    _taglineController.forward();

    // Tunggu total ~2.5 detik lalu pindah ke MainScreen
    await Future.delayed(const Duration(milliseconds: 900));
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              MainScreen(),
          transitionsBuilder:
              (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _taglineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFF8C00), // Warna oranye khas Maffin
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo dengan animasi scale + fade
              AnimatedBuilder(
                animation: _logoController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _logoOpacity.value,
                    child: Transform.scale(
                      scale: _logoScale.value,
                      child: child,
                    ),
                  );
                },
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: Image.asset(
                      'assets/icon/icon.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Nama app dengan animasi slide + fade
              AnimatedBuilder(
                animation: _textController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _textOpacity.value,
                    child: SlideTransition(
                      position: _textSlide,
                      child: child,
                    ),
                  );
                },
                child: Column(
                  children: [
                    Text(
                      'maffin',
                      style: GoogleFonts.poppins(
                        fontSize: 48,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -1,
                        height: 1.0,
                      ),
                    ),
                    Text(
                      'petshop',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withOpacity(0.9),
                        letterSpacing: 2,
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Tagline dengan animasi fade
              AnimatedBuilder(
                animation: _taglineController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _taglineOpacity.value,
                    child: child,
                  );
                },
                child: Text(
                  '🐱 Teman Setia Hewan Peliharaanmu',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withOpacity(0.8),
                    letterSpacing: 0.5,
                  ),
                ),
              ),

              const SizedBox(height: 80),

              // Loading indicator kecil di bawah
              AnimatedBuilder(
                animation: _taglineController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _taglineOpacity.value,
                    child: child,
                  );
                },
                child: SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.white.withOpacity(0.7),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}