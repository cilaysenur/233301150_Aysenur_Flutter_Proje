import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'ilan_duzenle.dart';

class IlanlarimSayfasi extends StatefulWidget {
  const IlanlarimSayfasi({super.key});

  @override
  State<IlanlarimSayfasi> createState() => _IlanlarimSayfasiState();
}

class _IlanlarimSayfasiState extends State<IlanlarimSayfasi> {
  List<Map<String, dynamic>> _ilanlarim = [];
  bool _yukleniyor = true;

  @override
  void initState() {
    super.initState();
    _ilanlarimiGetir();
  }

  Future<void> _ilanlarimiGetir() async {
    setState(() => _yukleniyor = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final response = await Supabase.instance.client
          .from('ilanlar')
          .select()
          .eq('email', user.email!) 
          .order('created_at', ascending: false);

      setState(() {
        _ilanlarim = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: $e")));
    } finally {
      setState(() => _yukleniyor = false);
    }
  }

  Future<void> _ilanSil(dynamic id) async {
    try {
      await Supabase.instance.client.from('ilanlar').delete().eq('id', id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("İlan başarıyla silindi!"), backgroundColor: Colors.red)
        );
      }
      _ilanlarimiGetir(); 
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Silme hatası: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: const Text("İlanlarım & Yönetim", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: _yukleniyor
          ? const Center(child: CircularProgressIndicator())
          : _ilanlarim.isEmpty
              ? const Center(child: Text("Henüz hiç ilan eklemediniz.", style: TextStyle(fontSize: 16)))
              : ListView.builder(
                  // KENARLARDAN 15 PİKSEL BOŞLUK (Mükemmel mobil görünüm, 100 sildik)
                  padding: const EdgeInsets.all(15),
                  itemCount: _ilanlarim.length,
                  itemBuilder: (context, index) {
                    final ilan = _ilanlarim[index];
                    return _buildIlanCard(ilan);
                  },
                ),
    );
  }

  // KUSURSUZ YENİ MOBİL TASARIM (DİKEY KART - SIKIŞMA İHTİMALİ YOK)
  Widget _buildIlanCard(Map<String, dynamic> ilan) {
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      clipBehavior: Clip.antiAlias, // Resmin köşelerinin kartla birlikte yuvarlanmasını sağlar
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. ÜST KISIM: TAM GENİŞLİKTE BÜYÜK RESİM
          Image.network(
            ilan['resim'] ?? 'https://via.placeholder.com/500',
            width: double.infinity,
            height: 200,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              width: double.infinity, 
              height: 200, 
              color: Colors.grey.shade200, 
              child: const Center(child: Icon(Icons.broken_image, size: 50, color: Colors.grey))
            ),
          ),
          
          // 2. ALT KISIM: YAZILAR VE BUTONLAR
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ilan['kategori'] ?? 'Kategori Yok', style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                Text(ilan['baslik'] ?? 'Başlıksız İlan', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 10),
                Text("₺${ilan['fiyat']}", style: const TextStyle(fontSize: 22, color: Color(0xFF1E3A8A), fontWeight: FontWeight.w900)),
                
                const SizedBox(height: 15),
                const Divider(height: 1),
                const SizedBox(height: 15),
                
                // Butonlar Alt Alta Değil, Yanyana ve Geniş
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final sonuc = await Navigator.push(
                            context, 
                            MaterialPageRoute(builder: (context) => IlanDuzenleSayfasi(ilan: ilan))
                          );
                          if (sonuc == true) {
                            _ilanlarimiGetir();
                          }
                        },
                        icon: const Icon(Icons.edit, size: 18, color: Colors.white),
                        label: const Text("Düzenle", style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E3A8A), 
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _ilanSil(ilan['id']),
                        icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                        label: const Text("Sil", style: TextStyle(color: Colors.red)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red), 
                          foregroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                        ),
                      ),
                    )
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}