import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'ilan_duzenle.dart'; // DÜZENLEME SAYFANIZI İÇERİ AKTARDIK

class ProfilSayfasi extends StatefulWidget {
  const ProfilSayfasi({super.key});

  @override
  State<ProfilSayfasi> createState() => _ProfilSayfasiState();
}

class _ProfilSayfasiState extends State<ProfilSayfasi> {
  bool _yukleniyor = true;
  String _kullaniciMail = "";
  
  // --- ADMİN KONTROLÜ ---
  bool _isAdmin = false;
  final String adminMail = "admin2005@gmail.com"; 

  // Normal Kullanıcı Değişkenleri
  String _adSoyad = "Ad Soyad Belirtilmemiş";
  String _dogumTarihi = "Doğum Tarihi Belirtilmemiş";
  List<Map<String, dynamic>> _gelenTeklifler = [];
  List<Map<String, dynamic>> _verdigimTeklifler = [];

  // Admin Değişkenleri
  List<Map<String, dynamic>> _tumIlanlarAdmin = [];

  final _adController = TextEditingController();
  final _tarihController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tumVerileriYenile();
  }

  Future<void> _tumVerileriYenile() async {
    setState(() => _yukleniyor = true);
    final user = Supabase.instance.client.auth.currentUser;
    
    if (user != null) {
      _kullaniciMail = user.email!;
      _isAdmin = _kullaniciMail == adminMail;

      if (_isAdmin) {
        await _adminTumIlanlariGetir();
      } else {
        await _profilBilgileriniGetir();
        await _gelenTeklifleriGetir();
        await _verdigimTeklifleriGetir();
      }
    }
    setState(() => _yukleniyor = false);
  }

  // ================= ADMİN METOTLARI =================

  Future<void> _adminTumIlanlariGetir() async {
    try {
      final response = await Supabase.instance.client
          .from('ilanlar')
          .select()
          .order('created_at', ascending: false);

      setState(() {
        _tumIlanlarAdmin = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      debugPrint("Admin ilan çekme hatası: $e");
    }
  }

  Future<void> _adminIlanSil(int id) async {
    try {
      await Supabase.instance.client.from('ilanlar').delete().eq('id', id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("İlan sistemden kalıcı olarak silindi."),
          backgroundColor: Colors.red,
        ));
      }
      _tumVerileriYenile();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Silme hatası: $e")));
    }
  }

  // ================= NORMAL KULLANICI METOTLARI =================

  Future<void> _profilBilgileriniGetir() async {
    try {
      final response = await Supabase.instance.client
          .from('profiller')
          .select()
          .eq('email', _kullaniciMail)
          .maybeSingle();

      if (response != null) {
        setState(() {
          _adSoyad = response['ad_soyad'] ?? "Ad Soyad Belirtilmemiş";
          _dogumTarihi = response['dogum_tarihi'] ?? "Doğum Tarihi Belirtilmemiş";
        });
      }
    } catch (e) {
      debugPrint("Profil çekme hatası: $e");
    }
  }

  Future<void> _gelenTeklifleriGetir() async {
    try {
      final response = await Supabase.instance.client
          .from('teklifler')
          .select('*, ilanlar(*)')
          .eq('ilan_sahibi_email', _kullaniciMail)
          .order('created_at', ascending: false);

      List<Map<String, dynamic>> geciciListe = List<Map<String, dynamic>>.from(response);
      for (var teklif in geciciListe) {
        final profilResp = await Supabase.instance.client
            .from('profiller')
            .select('ad_soyad')
            .eq('email', teklif['teklif_veren_email'])
            .maybeSingle();
        teklif['veren_isim'] = profilResp != null ? profilResp['ad_soyad'] : teklif['teklif_veren_email'].split('@')[0];
      }

      setState(() { _gelenTeklifler = geciciListe; });
    } catch (e) {
      debugPrint("Gelen teklif hatası: $e");
    }
  }

  Future<void> _verdigimTeklifleriGetir() async {
    try {
      final response = await Supabase.instance.client
          .from('teklifler')
          .select('*, ilanlar(*)')
          .eq('teklif_veren_email', _kullaniciMail)
          .order('created_at', ascending: false);

      setState(() { _verdigimTeklifler = List<Map<String, dynamic>>.from(response); });
    } catch (e) {
      debugPrint("Verilen teklif hatası: $e");
    }
  }

  Future<void> _teklifDurumGuncelle(int id, String yeniDurum) async {
    try {
      await Supabase.instance.client.from('teklifler').update({'durum': yeniDurum}).eq('id', id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Teklif $yeniDurum!"),
          backgroundColor: yeniDurum == 'Kabul Edildi' ? Colors.green : Colors.red,
        ));
      }
      _tumVerileriYenile(); 
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: $e")));
    }
  }

  Future<void> _teklifSil(int id) async {
    try {
      await Supabase.instance.client.from('teklifler').delete().eq('id', id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Teklif başarıyla kaldırıldı."),
          backgroundColor: Colors.black87,
        ));
      }
      _tumVerileriYenile();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Silme hatası: $e")));
    }
  }

  void _profilDuzenleMenusu() {
    _adController.text = _adSoyad == "Ad Soyad Belirtilmemiş" ? "" : _adSoyad;
    _tarihController.text = _dogumTarihi == "Doğum Tarihi Belirtilmemiş" ? "" : _dogumTarihi;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 30, right: 30, top: 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Bilgilerimi Düzenle", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextField(controller: _adController, decoration: InputDecoration(labelText: "Ad Soyad", filled: true, fillColor: Colors.grey.shade100, border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none))),
            const SizedBox(height: 15),
            TextField(controller: _tarihController, decoration: InputDecoration(hintText: "GG.AA.YYYY", labelText: "Doğum Tarihi", filled: true, fillColor: Colors.grey.shade100, border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none))),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                onPressed: () async {
                  await Supabase.instance.client.from('profiller').upsert({
                    'email': _kullaniciMail,
                    'ad_soyad': _adController.text.trim(),
                    'dogum_tarihi': _tarihController.text.trim(),
                  });
                  if (context.mounted) Navigator.pop(context);
                  _tumVerileriYenile();
                },
                child: const Text("Kaydet", style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(_isAdmin ? "Tüm İlan Yönetimi" : "Profilim & İşlemlerim"), 
        backgroundColor: _isAdmin ? Colors.red.shade50 : Colors.white, 
        foregroundColor: _isAdmin ? Colors.red.shade900 : Colors.black, 
        elevation: 0
      ),
      body: _yukleniyor
          ? const Center(child: CircularProgressIndicator())
          : _isAdmin 
              ? _buildAdminPaneli() 
              : _buildNormalKullaniciPaneli(),
    );
  }

  // ================= ARAYÜZ PARÇALARI =================

  Widget _buildAdminPaneli() {
    if (_tumIlanlarAdmin.isEmpty) {
      return const Center(child: Text("Sistemde aktif ilan bulunmuyor.", style: TextStyle(fontSize: 18)));
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 100, vertical: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Sistemdeki Tüm İlanlar", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red)),
          const SizedBox(height: 15),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _tumIlanlarAdmin.length,
            itemBuilder: (context, index) {
              final ilan = _tumIlanlarAdmin[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: Colors.red.shade100)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.network(ilan['resim'] ?? 'https://via.placeholder.com/100', width: 100, height: 70, fit: BoxFit.cover)),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(ilan['baslik'] ?? 'İsimsiz İlan', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 5),
                            Text("Sahibi: ${ilan['email']}", style: const TextStyle(color: Colors.black54)),
                          ],
                        ),
                      ),
                      Text("₺${ilan['fiyat']}", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.black87)),
                      const SizedBox(width: 30),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue, size: 28),
                        onPressed: () {
                           // KENDİ YAZDIĞIN DÜZENLEME SAYFASINA GİDER
                           Navigator.push(context, MaterialPageRoute(builder: (context) => IlanDuzenleSayfasi(ilan: ilan)))
                               .then((_) => _tumVerileriYenile());
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_forever, color: Colors.red, size: 28),
                        onPressed: () => _adminIlanSil(ilan['id']),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNormalKullaniciPaneli() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 100, vertical: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15)]),
            child: Row(
              children: [
                CircleAvatar(radius: 45, backgroundColor: Colors.blue.shade50, child: const Icon(Icons.person, size: 45, color: Color(0xFF1E3A8A))),
                const SizedBox(width: 30),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_adSoyad, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 5),
                      Text("📧 $_kullaniciMail", style: const TextStyle(color: Colors.black54)),
                      const SizedBox(height: 5),
                      Text("🎂 $_dogumTarihi", style: const TextStyle(color: Colors.black54)),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _profilDuzenleMenusu,
                  icon: const Icon(Icons.edit, size: 16, color: Colors.white),
                  label: const Text("Düzenle", style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                )
              ],
            ),
          ),
          const SizedBox(height: 40),
          const Text("Gelen Teklifler (Satıcı Rolü)", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
          const SizedBox(height: 15),
          _buildGelenTekliflerListesi(),
          const SizedBox(height: 40),
          const Text("Verdiğim Teklifler (Alıcı Rolü)", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 15),
          _buildVerdigimTekliflerListesi(),
        ],
      ),
    );
  }

  Widget _buildGelenTekliflerListesi() {
    if (_gelenTeklifler.isEmpty) {
      return const Card(child: Padding(padding: EdgeInsets.all(30), child: Center(child: Text("Henüz bir teklif almadınız."))));
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _gelenTeklifler.length,
      itemBuilder: (context, index) {
        final teklif = _gelenTeklifler[index];
        final ilan = teklif['ilanlar'];
        return Card(
          margin: const EdgeInsets.only(bottom: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.network(ilan?['resim'] ?? 'https://via.placeholder.com/100', width: 100, height: 70, fit: BoxFit.cover)),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ilan?['baslik'] ?? 'Silinmiş Ürün', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 5),
                      Text("Teklif Veren: ${teklif['veren_isim']}", style: const TextStyle(color: Colors.black54)),
                      const SizedBox(height: 5),
                      _buildDurumEtiketi(teklif['durum']),
                    ],
                  ),
                ),
                Text("₺${teklif['teklif_fiyati']}", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: const Color(0xFF1E3A8A))),
                const SizedBox(width: 30),
                Row(
                  children: [
                    if (teklif['durum'] == 'Bekliyor') ...[
                      IconButton(icon: const Icon(Icons.check_circle, color: Colors.green, size: 32), onPressed: () => _teklifDurumGuncelle(teklif['id'], 'Kabul Edildi')),
                      IconButton(icon: const Icon(Icons.cancel, color: Colors.red, size: 32), onPressed: () => _teklifDurumGuncelle(teklif['id'], 'Reddedildi')),
                    ],
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.grey, size: 28),
                      onPressed: () => _teklifSil(teklif['id']),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildVerdigimTekliflerListesi() {
    if (_verdigimTeklifler.isEmpty) {
      return const Card(child: Padding(padding: EdgeInsets.all(30), child: Center(child: Text("Henüz bir ürüne teklif vermediniz."))));
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _verdigimTeklifler.length,
      itemBuilder: (context, index) {
        final teklif = _verdigimTeklifler[index];
        final ilan = teklif['ilanlar'];
        return Card(
          margin: const EdgeInsets.only(bottom: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.network(ilan?['resim'] ?? 'https://via.placeholder.com/100', width: 100, height: 70, fit: BoxFit.cover)),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ilan?['baslik'] ?? 'Silinmiş Ürün', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 5),
                      Text("Satıcı Mail: ${teklif['ilan_sahibi_email']}", style: const TextStyle(color: Colors.black54)),
                      const SizedBox(height: 5),
                      _buildDurumEtiketi(teklif['durum']),
                    ],
                  ),
                ),
                Text("₺${teklif['teklif_fiyati']}", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.black87)),
                const SizedBox(width: 20),
                IconButton(
                  icon: const Icon(Icons.delete_forever, color: Colors.redAccent, size: 26),
                  onPressed: () => _teklifSil(teklif['id']),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDurumEtiketi(String durum) {
    Color renk = Colors.orange;
    if (durum == 'Kabul Edildi') renk = Colors.green;
    if (durum == 'Reddedildi') renk = Colors.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: renk.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(durum, style: TextStyle(color: renk, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }
}