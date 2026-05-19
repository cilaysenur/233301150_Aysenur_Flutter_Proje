import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class KayitOlScreen extends StatefulWidget {
  const KayitOlScreen({super.key});

  @override
  State<KayitOlScreen> createState() => _KayitOlScreenState();
}

class _KayitOlScreenState extends State<KayitOlScreen> {
  bool _sifreGizli = true;
  bool _yukleniyor = false;

  final _adSoyadController = TextEditingController();
  final _epostaController = TextEditingController();
  final _sifreController = TextEditingController();

  Future<void> _kayitOl() async {
    final adSoyad = _adSoyadController.text.trim();
    final eposta = _epostaController.text.trim();
    final sifre = _sifreController.text.trim();

    if (adSoyad.isEmpty || eposta.isEmpty || sifre.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen tüm alanları doldurun!')),
      );
      return;
    }

    setState(() { _yukleniyor = true; });

    try {
      final AuthResponse response = await Supabase.instance.client.auth.signUp(
        email: eposta,
        password: sifre,
        data: {'ad_soyad': adSoyad}, 
      );

      if (response.user != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Kayıt Başarılı! Hoş Geldiniz.'), backgroundColor: Colors.green),
          );
          Navigator.pop(context); 
        }
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Hata: ${e.message}'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
       if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Bir hata oluştu: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
       setState(() { _yukleniyor = false; });
    }
  }

  @override
  void dispose() {
    _adSoyadController.dispose();
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
            colors: [
              Color(0xFF0F172A), 
              Color(0xFF1E3A8A),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: bilgisayarMi
            ? Row(
                children: [
                  Expanded(flex: 5, child: _buildMarkaPaneli(context)),
                  Expanded(flex: 4, child: _buildGlassFormPaneli()),
                ],
              )
            : _buildGlassFormPaneli(),
      ),
    );
  }

  Widget _buildMarkaPaneli(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(height: 40),
            const Icon(Icons.person_add_outlined, size: 80, color: Colors.white),
            const SizedBox(height: 24),
            const Text(
              "Aramıza\nKatıl.",
              style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white, height: 1.1),
            ),
            const SizedBox(height: 16),
            const Text(
              "Binlerce kullanıcıyla güvenli alışverişe başlamak için sadece birkaç saniyenizi ayırın.",
              style: TextStyle(fontSize: 18, color: Colors.white70, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassFormPaneli() {
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
                    const Text('Kayıt Ol', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white)),
                    const SizedBox(height: 8),
                    const Text('Hemen bir hesap oluşturun.', style: TextStyle(fontSize: 15, color: Colors.white70)),
                    const SizedBox(height: 40),

                    const Text('Ad Soyad', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                    const SizedBox(height: 8),
                    _buildTextField(hint: 'Örn: Ayşe Yılmaz', icon: Icons.person_outline, controller: _adSoyadController),
                    const SizedBox(height: 20),

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
                    const SizedBox(height: 40),

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
                        onPressed: _yukleniyor ? null : _kayitOl, 
                        child: _yukleniyor 
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Color(0xFF1E3A8A), strokeWidth: 2)) 
                            : const Text('KAYIT OL', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                      ),
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