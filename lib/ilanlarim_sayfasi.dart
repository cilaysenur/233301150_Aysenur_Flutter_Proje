import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
              ? const Center(child: Text("Henüz hiç ilan eklemediniz.", style: TextStyle(fontSize: 18)))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 100, vertical: 20),
                  itemCount: _ilanlarim.length,
                  itemBuilder: (context, index) {
                    final ilan = _ilanlarim[index];
                    return _buildIlanCard(ilan);
                  },
                ),
    );
  }

  Widget _buildIlanCard(Map<String, dynamic> ilan) {
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                ilan['resim'] ?? 'https://via.placeholder.com/150',
                width: 180,
                height: 120,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(width: 180, height: 120, color: Colors.grey.shade200, child: const Icon(Icons.broken_image)),
              ),
            ),
            const SizedBox(width: 30),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ilan['kategori'] ?? 'Kategori Yok', style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(ilan['baslik'] ?? 'Başlıksız İlan', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text("₺${ilan['fiyat']}", style: const TextStyle(fontSize: 24, color: Color(0xFF1E3A8A), fontWeight: FontWeight.w900)),
                ],
              ),
            ),
            
            Column(
              children: [
                SizedBox(
                  width: 140,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Düzenleme sayfasına geçilecek!")));
                    },
                    icon: const Icon(Icons.edit, size: 18, color: Colors.white),
                    label: const Text("Düzenle", style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), padding: const EdgeInsets.symmetric(vertical: 15)),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: 140,
                  child: OutlinedButton.icon(
                    onPressed: () => _ilanSil(ilan['id']),
                    icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                    label: const Text("İlanı Sil", style: TextStyle(color: Colors.red)),
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red), padding: const EdgeInsets.symmetric(vertical: 15)),
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}