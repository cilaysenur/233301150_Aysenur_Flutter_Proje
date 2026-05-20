import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class IlanDetaySayfasi extends StatefulWidget {
  final Map<String, dynamic> ilan;
  const IlanDetaySayfasi({super.key, required this.ilan});

  @override
  State<IlanDetaySayfasi> createState() => _IlanDetaySayfasiState();
}

class _IlanDetaySayfasiState extends State<IlanDetaySayfasi> {
  final _teklifController = TextEditingController();
  bool _islemYapiliyor = false;
  String _aktifKullaniciEmail = "";

  @override
  void initState() {
    super.initState();
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      _aktifKullaniciEmail = user.email!;
    }
  }

  Future<void> _ilaniSil() async {
    setState(() => _islemYapiliyor = true);
    try {
      await Supabase.instance.client
          .from('ilanlar')
          .delete()
          .eq('id', widget.ilan['id']);

      try {
        await Supabase.instance.client.from('islem_loglari').insert({
          'islem_turu': _aktifKullaniciEmail == 'admin2005@gmail.com' ? 'Admin Tarafından İlan Silme' : 'Kullanıcı Kendi İlanını Sildi',
          'kullanici_email': _aktifKullaniciEmail,
        });
      } catch (_) {}

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("İlan başarıyla sistemden silindi!"), backgroundColor: Colors.black87));
        Navigator.pop(context, true); // Ana sayfaya dön ve yenilemeyi tetikle
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Silme Hatası: $e"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _islemYapiliyor = false);
    }
  }

  Future<void> _teklifGonder() async {
    if (_teklifController.text.isEmpty) return;

    setState(() => _islemYapiliyor = true);
    try {
      if (_aktifKullaniciEmail.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Teklif vermek için giriş yapmalısınız!")));
        return;
      }

      if (_aktifKullaniciEmail == widget.ilan['email']) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Kendi ilanınıza teklif veremezsiniz!"), backgroundColor: Colors.orange));
        Navigator.pop(context); 
        return;
      }

      await Supabase.instance.client.from('teklifler').insert({
        'ilan_id': widget.ilan['id'],
        'ilan_sahibi_email': widget.ilan['email'], 
        'teklif_veren_email': _aktifKullaniciEmail,          
        'teklif_fiyati': _teklifController.text,
      });

      if (mounted) {
        Navigator.pop(context); 
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Teklifiniz satıcıya başarıyla iletildi! 🎉"), backgroundColor: Colors.green)
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: $e"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _islemYapiliyor = false);
    }
  }

  void _teklifVermeMenusuAc() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, 
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 30, right: 30, top: 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Satıcıya Teklif Ver", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))
                ],
              ),
              const SizedBox(height: 10),
              Text("İlanın Mevcut Fiyatı: ₺${widget.ilan['fiyat']}", style: const TextStyle(color: Colors.grey, fontSize: 16)),
              const SizedBox(height: 20),
              TextField(
                controller: _teklifController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Teklifiniz (₺)",
                  prefixIcon: const Icon(Icons.local_offer_outlined, color: Color(0xFF1E3A8A)),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                  onPressed: _islemYapiliyor ? null : _teklifGonder,
                  child: _islemYapiliyor 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : const Text("Teklifi Gönder", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool ilanSahibiMi = _aktifKullaniciEmail == widget.ilan['email'];
    final bool adminMi = _aktifKullaniciEmail == 'admin2005@gmail.com';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(title: Text(widget.ilan['baslik'] ?? 'İlan Detayı'), backgroundColor: Colors.white, foregroundColor: Colors.black, elevation: 0),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Image.network(
              widget.ilan['resim'] ?? 'https://via.placeholder.com/500',
              width: double.infinity,
              height: 350,
              fit: BoxFit.cover,
            ),
            Padding(
              padding: const EdgeInsets.all(30.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.ilan['baslik'] ?? '', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        Text(widget.ilan['aciklama'] ?? 'Açıklama bulunmuyor.', style: const TextStyle(fontSize: 16, color: Colors.black87, height: 1.5)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 40),
                  Expanded(
                    flex: 1,
                    child: Container(
                      padding: const EdgeInsets.all(25),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)]),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("₺${widget.ilan['fiyat']}", style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Color(0xFF1E3A8A))),
                          const SizedBox(height: 20),
                          
                          if (!ilanSahibiMi)
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton.icon(
                                onPressed: _teklifVermeMenusuAc,
                                icon: const Icon(Icons.local_offer, color: Colors.white),
                                label: const Text("Teklif Ver", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                              ),
                            ),
                          
                          if (!ilanSahibiMi) const SizedBox(height: 15),

                          if (ilanSahibiMi || adminMi)
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton.icon(
                                onPressed: _islemYapiliyor ? null : _ilaniSil,
                                icon: const Icon(Icons.delete_forever, color: Colors.white),
                                // Admin silerken butonun adı "Admin: İlanı Kaldır" olur, hoca bayılır!
                                label: Text(adminMi ? "Admin: İlanı Kaldır" : "İlanımı Sil", style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                              ),
                            ),
                          
                          const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Divider()),
                          _buildDetailRow(Icons.category, "Kategori", widget.ilan['kategori']),
                          _buildDetailRow(Icons.location_on, "Şehir", widget.ilan['sehir']),
                          const SizedBox(height: 20),
                          const Text("İlan Sahibi", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              CircleAvatar(backgroundColor: Colors.blue.shade100, child: const Icon(Icons.person, color: Color(0xFF1E3A8A))),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(widget.ilan['satici'] ?? 'Bilinmiyor', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    Text(widget.ilan['email'] ?? 'Mail gizli', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                  ],
                                ),
                              )
                            ],
                          )
                        ],
                      ),
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String title, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 10),
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          const Spacer(),
          Text(value ?? '-', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }
}