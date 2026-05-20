import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class IlanDetaySayfasi extends StatefulWidget {
  final Map<String, dynamic> ilan;

  const IlanDetaySayfasi({super.key, required this.ilan});

  @override
  State<IlanDetaySayfasi> createState() => _IlanDetaySayfasiState();
}

class _IlanDetaySayfasiState extends State<IlanDetaySayfasi> {
  bool _favorideMi = false;

 @override
  void initState() {
    super.initState();
    _checkFavoriDurumu(); 
  }

  Future<void> _checkFavoriDurumu() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    
    final data = await Supabase.instance.client
        .from('favoriler')
        .select()
        .eq('ilan_id', widget.ilan['id'])
        .eq('user_email', user.email!);
    
    if (mounted && data.isNotEmpty) {
      setState(() => _favorideMi = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ilan = widget.ilan;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(backgroundColor: Colors.white, elevation: 0, foregroundColor: Colors.black),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 100, vertical: 30),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 500,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        image: DecorationImage(image: NetworkImage(ilan['resim'] ?? ''), fit: BoxFit.contain),
                        color: Colors.black12,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(ilan['baslik'] ?? '', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 15),
                    Text(ilan['aciklama'] ?? '', style: const TextStyle(fontSize: 18, color: Colors.black87, height: 1.5)),
                  ],
                ),
              ),
              const SizedBox(width: 40),
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    _buildInfoCard(ilan),
                    const SizedBox(height: 20),
                    _buildOwnerCard(ilan),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(Map<String, dynamic> ilan) {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("₺${ilan['fiyat']}", style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE11D48), padding: const EdgeInsets.all(15)),
              onPressed: () async {
                final user = Supabase.instance.client.auth.currentUser;
                if (user == null) return;

                if (_favorideMi) {
                  await Supabase.instance.client.from('favoriler').delete().eq('ilan_id', ilan['id']).eq('user_email', user.email!);
                } else {
                  await Supabase.instance.client.from('favoriler').insert({'ilan_id': ilan['id'], 'user_email': user.email!});
                }
                setState(() => _favorideMi = !_favorideMi);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_favorideMi ? "Favorilere eklendi!" : "Favorilerden çıkarıldı!")));
              },
              icon: Icon(_favorideMi ? Icons.favorite : Icons.favorite_border, color: Colors.white),
              label: Text(_favorideMi ? "Favorilerden Çıkar" : "Favorilere Ekle", style: const TextStyle(color: Colors.white)),
            ),
          ),
          const Divider(height: 40),
          _infoRow(Icons.location_on, "Şehir", ilan['sehir'] ?? '-'),
          _infoRow(Icons.category, "Kategori", ilan['kategori'] ?? '-'),
          _infoRow(Icons.date_range, "Tarih", "18.05.2026"),
        ],
      ),
    );
  }

  Widget _buildOwnerCard(Map<String, dynamic> ilan) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        children: [
          const Align(alignment: Alignment.centerLeft, child: Text("İlan Sahibi", style: TextStyle(fontWeight: FontWeight.bold))),
          const SizedBox(height: 15),
          Row(
            children: [
              const CircleAvatar(radius: 25, child: Icon(Icons.person)),
              const SizedBox(width: 15),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ilan['satici'] ?? 'Ahmet Yılmaz', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const Text("cilay2000@gmail.com", style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 10),
          Text(title, style: const TextStyle(color: Colors.grey)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}