import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'ilan_ekle.dart';

class IlanlarSayfasi extends StatefulWidget {
  const IlanlarSayfasi({super.key});

  @override
  State<IlanlarSayfasi> createState() => _IlanlarSayfasiState();
}

class _IlanlarSayfasiState extends State<IlanlarSayfasi> {
  List<Map<String, dynamic>> _canliIlanlar = [];
  bool _yukleniyor = true;

  @override
  void initState() {
    super.initState();
    _verileriGetir();
  }

  Future<void> _verileriGetir() async {
    setState(() { _yukleniyor = true; });
    try {
      final response = await Supabase.instance.client
          .from('ilanlar')
          .select()
          .order('created_at', ascending: false);
      
      setState(() {
        _canliIlanlar = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Veri çekme hatası: $e"), backgroundColor: Colors.red));
    } finally {
      setState(() { _yukleniyor = false; });
    }
  }

  Future<void> _ilanSil(int id) async {
    try {
      await Supabase.instance.client.from('ilanlar').delete().eq('id', id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("İlan başarıyla silindi!"), backgroundColor: Colors.redAccent),
        );
      }
      _verileriGetir(); 
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Silme hatası: $e"), backgroundColor: Colors.red));
      }
    }
  }

  String _tarihFormatla(String? hamTarih) {
    if (hamTarih == null) return "Tarih Belirtilmemiş";
    try {
      final parsedDate = DateTime.parse(hamTarih).toLocal(); 
      
      final gun = parsedDate.day.toString().padLeft(2, '0');
      final ay = parsedDate.month.toString().padLeft(2, '0');
      final yil = parsedDate.year;
      final saat = parsedDate.hour.toString().padLeft(2, '0');
      final dakika = parsedDate.minute.toString().padLeft(2, '0');
      
      return "$gun.$ay.$yil - $saat:$dakika";
    } catch (e) {
      return "Tarih Hatalı";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            const Text("İkinci El Pazarı", style: TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold)),
            const SizedBox(width: 40),
            _navbarItem("Ana Sayfa"),
            _navbarItem("İlanlar", active: true),
            _navbarItem("Kategoriler"),
            _navbarItem("Şehirler"),
          ],
        ),
        actions: [
          _navbarAction(Icons.add_circle_outline, "İlan Ekle", () async {
            final sonuc = await Navigator.push(
              context, 
              MaterialPageRoute(builder: (context) => const IlanEkleSayfasi())
            );
            if (sonuc == true) {
              _verileriGetir();
            }
          }),
          _navbarAction(Icons.favorite_border, "Favorilerim", () {}),
          _navbarAction(Icons.person_outline, "Profil", () {}),
          const SizedBox(width: 20),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeroSection(),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 100, vertical: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Son Eklenen İlanlar", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.refresh, color: Color(0xFF1E3A8A)),
                        onPressed: _verileriGetir,
                      )
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  _yukleniyor
                      ? const Center(child: Padding(padding: EdgeInsets.all(50.0), child: CircularProgressIndicator()))
                      : _canliIlanlar.isEmpty
                          ? const Center(child: Padding(padding: EdgeInsets.all(50.0), child: Text("Henüz hiç ilan eklenmemiş. İlk ilanı sen ekle!", style: TextStyle(fontSize: 16, color: Colors.grey))))
                          : GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 4, 
                                childAspectRatio: 0.8,
                                crossAxisSpacing: 20,
                                mainAxisSpacing: 20,
                              ),
                              itemCount: _canliIlanlar.length,
                              itemBuilder: (context, index) => _buildModernCard(_canliIlanlar[index]),
                            ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navbarItem(String text, {bool active = false}) {
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 15), child: Text(text, style: TextStyle(color: active ? const Color(0xFF1E3A8A) : Colors.black54, fontSize: 14, fontWeight: active ? FontWeight.bold : FontWeight.normal)));
  }

  Widget _navbarAction(IconData icon, String text, VoidCallback onTap) {
    return TextButton.icon(onPressed: onTap, icon: Icon(icon, size: 20, color: Colors.black87), label: Text(text, style: const TextStyle(color: Colors.black87, fontSize: 13)));
  }

  Widget _buildHeroSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 100),
      decoration: const BoxDecoration(color: Color(0xFFF8FAFC), borderRadius: BorderRadius.only(bottomLeft: Radius.circular(50), bottomRight: Radius.circular(50))),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("İkinci El Ürünlerde\nEn İyi Fırsatlar", style: TextStyle(fontSize: 42, fontWeight: FontWeight.bold, height: 1.1)),
                const SizedBox(height: 20),
                const Text("Binlerce ilan arasından aradığını bul, uygun fiyata sahip ol.\nİlanını ekle, hızlıca alıcı bul.", style: TextStyle(fontSize: 16, color: Colors.black54)),
                const SizedBox(height: 40),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)]),
                  child: Row(
                    children: [
                      const Icon(Icons.search, color: Color(0xFF1E3A8A)),
                      const SizedBox(width: 10),
                      const Expanded(child: TextField(decoration: InputDecoration(hintText: "İlan ara...", border: InputBorder.none))),
                      ElevatedButton(onPressed: () {}, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), child: const Text("İlanları Keşfet", style: TextStyle(color: Colors.white)))
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Expanded(child: Icon(Icons.shopping_bag_outlined, size: 250, color: Color(0xFFE2E8F0))),
        ],
      ),
    );
  }

  Widget _buildModernCard(Map<String, dynamic> ilan) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: Image.network(ilan["resim"] ?? "https://via.placeholder.com/500", fit: BoxFit.cover, width: double.infinity, errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.broken_image, size: 50, color: Colors.grey))),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ilan["kategori"] ?? "Genel", style: const TextStyle(color: Color(0xFF1E3A8A), fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                Text(ilan["baslik"] ?? "Başlıksız İlan", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("₺${ilan["fiyat"]}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1E3A8A))),
                    InkWell(
                      onTap: () => _ilanSil(ilan["id"]),
                      child: const Icon(Icons.delete_outline, size: 22, color: Colors.red),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  "${ilan["sehir"] ?? "Belirtilmemiş"} • ${_tarihFormatla(ilan["created_at"])}", 
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}