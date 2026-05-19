import 'dart:ui'; // BackdropFilter için gerekli
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'ilanlar_sayfasi.dart'; 
import 'kayit_ol.dart';        

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://rttxvvoslbjabgohoipo.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJ0dHh2dm9zbGJqYWJnb2hvaXBvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzkxMTg3MTcsImV4cCI6MjA5NDY5NDcxN30.3ih3eiA0mQgYdKznjGX15-NMN6w0BD6pXKWIWwmir1A',
  );

  runApp(const IkinciElApp());
}

class IkinciElApp extends StatelessWidget {
  const IkinciElApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'İkinci El Pazarı',
      theme: ThemeData(
        primaryColor: const Color(0xFF1E3A8A),
        fontFamily: 'Roboto',
      ),
      home: StreamBuilder<AuthState>(
        stream: Supabase.instance.client.auth.onAuthStateChange,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          final session = snapshot.data?.session;
          if (session != null) {
            return const IlanlarSayfasi();
          }
          return const LoginScreen();
        },
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _sifreGizli = true;
  bool _yukleniyor = false; 

  final _epostaController = TextEditingController();
  final _sifreController = TextEditingController();

  Future<void> _girisYap() async {
    final eposta = _epostaController.text.trim();
    final sifre = _sifreController.text.trim();

    if (eposta.isEmpty || sifre.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen e-posta ve şifrenizi girin!')),
      );
      return;
    }

    setState(() { _yukleniyor = true; });

    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: eposta,
        password: sifre,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Giriş Başarılı!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() { _yukleniyor = false; });
    }
  }

  @override
  void dispose() {
    _epostaController.dispose();
    _sifreController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final genislik = MediaQuery.of(context).size.width;
    final bilgisayarMi = genislik > 800;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF1E3A8A)], 
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: bilgisayarMi
            ? Row(
                children: [
                  Expanded(flex: 5, child: _buildMarkaPaneli()),
                  Expanded(flex: 4, child: _buildGlassFormPaneli(context)),
                ],
              )
            : _buildGlassFormPaneli(context), 
      ),
    );
  }

  Widget _buildMarkaPaneli() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.handshake_outlined, size: 80, color: Colors.white),
            SizedBox(height: 24),
            Text(
              "İkinci Elin\nYeni Yüzü.",
              style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white, height: 1.1),
            ),
            SizedBox(height: 16),
            Text(
              "Güvenli, hızlı ve kârlı alışverişin adresi. Alıcılar ve satıcılar tek bir çatı altında.",
              style: TextStyle(fontSize: 18, color: Colors.white70, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassFormPaneli(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 20.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 450),
                padding: const EdgeInsets.all(40.0),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.2)), 
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (MediaQuery.of(context).size.width <= 800) ...[
                      const Center(child: Icon(Icons.handshake_outlined, size: 60, color: Colors.white)),
                      const SizedBox(height: 20),
                    ],

                    const Text('Merhaba', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white)),
                    const SizedBox(height: 8),
                    const Text('Alım satım işlemlerinize devam etmek için giriş yapın.', style: TextStyle(fontSize: 15, color: Colors.white70)),
                    const SizedBox(height: 40),

                    const Text('E-posta Adresi', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                    const SizedBox(height: 8),
                    _buildTextField(hint: 'ornek@eposta.com', icon: Icons.mail_outline, controller: _epostaController),
                    const SizedBox(height: 20),

                    const Text('Şifre', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                    const SizedBox(height: 8),
                    _buildTextField(
                      hint: '••••••••',
                      icon: Icons.lock_outline,
                      isPassword: true,
                      controller: _sifreController,
                      suffix: IconButton(
                        icon: Icon(_sifreGizli ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: Colors.white70, size: 20),
                        onPressed: () { setState(() { _sifreGizli = !_sifreGizli; }); },
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {},
                        child: const Text('Şifremi Unuttum', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
                      ),
                    ),
                    const SizedBox(height: 30),

                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF1E3A8A), 
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _yukleniyor ? null : _girisYap,
                        child: _yukleniyor 
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Color(0xFF1E3A8A), strokeWidth: 2)) 
                            : const Text('GİRİŞ YAP', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                      ),
                    ),
                    const SizedBox(height: 40),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Hesabınız yok mu?', style: TextStyle(color: Colors.white70, fontSize: 15)),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const KayitOlScreen()),
                            );
                          },
                          child: const Text('Kayıt Ol', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({required String hint, required IconData icon, bool isPassword = false, Widget? suffix, TextEditingController? controller}) {
    return TextFormField(
      controller: controller, 
      obscureText: isPassword && _sifreGizli,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white54),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        prefixIcon: Icon(icon, color: Colors.white70, size: 20),
        suffixIcon: suffix,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.white.withOpacity(0.3))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.white.withOpacity(0.3))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.white, width: 2)),
      ),
    );
  }
}