import 'dart:ui';
import 'ilan_duzenle.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'ilan_ekle.dart';
import 'favoriler_sayfasi.dart';
import 'ilan_detay.dart';
import 'ilanlarim_sayfasi.dart';
import 'profil_sayfasi.dart';

class IlanlarSayfasi extends StatefulWidget {
  const IlanlarSayfasi({super.key});

  @override
  State<IlanlarSayfasi> createState() => _IlanlarSayfasiState();
}

class _IlanlarSayfasiState extends State<IlanlarSayfasi> {
  List<Map<String, dynamic>> _canliIlanlar = [];
  bool _yukleniyor = true;
  bool _yeniBildirimVar = false; 
  List<int> _favoriIlanIdleri = [];
  
  final _aramaController = TextEditingController();
  
  final List<String> _kategoriler = ["Tümü", "Elektronik", "Vasıta", "Moda", "Kitap", "Mobilya", "Hobi", "Diğer"];
  String _seciliKategori = "Tümü";

  @override
  void initState() {
    super.initState();
    _verileriGetir();
    _bildirimKontrol(); 
  }

  Future<void> _bildirimKontrol() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final response = await Supabase.instance.client
          .from('teklifler')
          .select('id')
          .eq('ilan_sahibi_email', user.email!)
          .eq('durum', 'Bekliyor'); 

      if (mounted) {
        setState(() {
          _yeniBildirimVar = response.isNotEmpty; 
        });
      }
    } catch (e) {
      debugPrint("Bildirim kontrol hatası: $e");
    }
  }

  Future<void> _verileriGetir({String? aramaSorgusu}) async {
    setState(() { _yukleniyor = true; });
    try {
      var query = Supabase.instance.client.from('ilanlar').select();
      
      if (_seciliKategori != "Tümü") {
        query = query.eq('kategori', _seciliKategori);
      }
      
      if (aramaSorgusu != null && aramaSorgusu.trim().isNotEmpty) {
        query = query.ilike('baslik', '%${aramaSorgusu.trim()}%');
      }
      
      final response = await query.order('created_at', ascending: false);

      final user = Supabase.instance.client.auth.currentUser;
      List<int> favorilerim = [];
      if (user != null) {
        final favData = await Supabase.instance.client.from('favoriler').select('ilan_id').eq('user_email', user.email!);
        for (var f in favData) {
          favorilerim.add(f['ilan_id'] as int);
        }
      }

      if (mounted) {
        setState(() {
          _canliIlanlar = List<Map<String, dynamic>>.from(response);
          _favoriIlanIdleri = favorilerim;
        });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Veri çekme hatası: $e"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() { _yukleniyor = false; });
    }
  }

  Future<void> _favoriyeEkleCikar(int ilanId) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Önce giriş yapmalısınız!")));
      return;
    }

    bool suAnFavoriMi = _favoriIlanIdleri.contains(ilanId);
    
    setState(() {
      if (suAnFavoriMi) {
        _favoriIlanIdleri.remove(ilanId);
      } else {
        _favoriIlanIdleri.add(ilanId);
      }
    });

    try {
      if (suAnFavoriMi) {
        await Supabase.instance.client.from('favoriler').delete().eq('user_email', user.email!).eq('ilan_id', ilanId);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Favorilerden çıkarıldı."), backgroundColor: Colors.black87));
      } else {
        await Supabase.instance.client.from('favoriler').insert({'user_email': user.email!, 'ilan_id': ilanId});
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Favorilere eklendi! ❤️"), backgroundColor: Colors.red));
      }
    } catch (e) {
      setState(() {
        if (suAnFavoriMi) {
          _favoriIlanIdleri.add(ilanId);
        } else {
          _favoriIlanIdleri.remove(ilanId);
        }
      });
    }
  }

  // YENİ: Teklif Gönderme İşlemi (Ayrı Fonksiyon)
  Future<void> _teklifGonder(Map<String, dynamic> ilan, String fiyat) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    
    try {
      await Supabase.instance.client.from('teklifler').insert({
        'ilan_id': ilan['id'],
        'ilan_sahibi_email': ilan['email'], 
        'teklif_veren_email': user.email,          
        'teklif_fiyati': fiyat,
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Teklif başarıyla iletildi! 🎉"), backgroundColor: Colors.green));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: $e"), backgroundColor: Colors.red));
    }
  }

  // YENİ: Zarif Pop-up Menu (Tooltip Benzeri)
  void _teklifMenusuGoster(BuildContext context, Map<String, dynamic> ilan, GlobalKey key) {
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Teklif vermek için giriş yapmalısınız!")));
      return;
    }
    if (user.email == ilan['email']) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Kendi ilanınıza teklif veremezsiniz!"), backgroundColor: Colors.orange));
      return;
    }

    final RenderBox renderBox = key.currentContext!.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final position = renderBox.localToGlobal(Offset.zero);

    final teklifController = TextEditingController();

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx, 
        position.dy - 160, 
        position.dx + size.width, 
        position.dy
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      items: [
        PopupMenuItem(
          enabled: false, 
          child: SizedBox(
            width: 200,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Hızlı Teklif Ver", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
                const SizedBox(height: 10),
                SizedBox(
                  height: 40,
                  child: TextField(
                    controller: teklifController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: "Teklifiniz (₺)",
                      hintStyle: const TextStyle(fontSize: 12),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 35,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                    onPressed: () {
                      if (teklifController.text.isNotEmpty) {
                        Navigator.pop(context);
                        _teklifGonder(ilan, teklifController.text);
                      }
                    },
                    child: const Text("Gönder", style: TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _tarihFormatla(String? hamTarih) {
    if (hamTarih == null) return "Tarih Belirtilmemiş";
    try {
      final parsedDate = DateTime.parse(hamTarih).toLocal(); 
      final gun = parsedDate.day.toString().padLeft(2, '0');
      final ay = parsedDate.month.toString().padLeft(2, '0');
      final yil = parsedDate.year;
      return "$gun.$ay.$yil";
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
            _navbarItem("Ana Sayfa", active: true, onTap: () {}),
            _navbarItem("İlanlarım", onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const IlanlarimSayfasi()));
            }),
          ],
        ),
        actions: [
          _navbarAction(Icons.add_circle_outline, "İlan Ver", () async {
            final sonuc = await Navigator.push(context, MaterialPageRoute(builder: (context) => const IlanEkleSayfasi()));
            if (sonuc == true) _verileriGetir(); 
          }),
          
          _navbarAction(Icons.favorite_border, "Favoriler", () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const FavorilerSayfasi())).then((_) => _verileriGetir());
          }),
          
          InkWell(
            onTap: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfilSayfasi()));
              _bildirimKontrol(); 
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: [
                  Badge(
                    isLabelVisible: _yeniBildirimVar, 
                    backgroundColor: Colors.red,
                    smallSize: 10,
                    child: const Icon(Icons.person_outline, size: 20, color: Colors.black87),
                  ),
                  const SizedBox(width: 5),
                  const Text("Profilim", style: TextStyle(color: Colors.black87, fontSize: 13)),
                ],
              ),
            ),
          ),
          
          _navbarAction(Icons.logout, "Çıkış Yap", () async {
            await Supabase.instance.client.auth.signOut(); 
            if (context.mounted) {
              Navigator.of(context).popUntil((route) => route.isFirst); 
            }
          }),
          
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
                  SizedBox(
                    height: 40,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _kategoriler.length,
                      itemBuilder: (context, index) {
                        final kat = _kategoriler[index];
                        final seciliMi = _seciliKategori == kat;
                        return Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: ChoiceChip(
                            label: Text(kat, style: TextStyle(fontWeight: FontWeight.bold, color: seciliMi ? Colors.white : Colors.black87)),
                            selectedColor: const Color(0xFF1E3A8A),
                            backgroundColor: Colors.grey.shade100,
                            selected: seciliMi,
                            showCheckmark: false,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: seciliMi ? const Color(0xFF1E3A8A) : Colors.grey.shade300)),
                            onSelected: (selected) {
                              setState(() => _seciliKategori = kat);
                              _verileriGetir(aramaSorgusu: _aramaController.text); 
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_seciliKategori == "Tümü" ? "Tüm İlanlar" : "$_seciliKategori İlanları", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      IconButton(icon: const Icon(Icons.refresh, color: Color(0xFF1E3A8A)), onPressed: () {
                        _verileriGetir(aramaSorgusu: _aramaController.text);
                        _bildirimKontrol(); 
                      })
                    ],
                  ),
                  const SizedBox(height: 20),
                  _yukleniyor
                      ? const Center(child: Padding(padding: EdgeInsets.all(50.0), child: CircularProgressIndicator()))
                      : _canliIlanlar.isEmpty
                          ? Center(child: Padding(padding: const EdgeInsets.all(50.0), child: Text("Bu kategoride veya aramada ilan bulunmuyor.", style: TextStyle(fontSize: 16, color: Colors.grey.shade600))))
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

  Widget _navbarItem(String text, {bool active = false, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8), 
        child: Text(text, style: TextStyle(color: active ? const Color(0xFF1E3A8A) : Colors.black54, fontSize: 14, fontWeight: active ? FontWeight.bold : FontWeight.normal))
      ),
    );
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
                      Expanded(child: TextField(
                        controller: _aramaController,
                        onChanged: (value) {
                           _verileriGetir(aramaSorgusu: value); 
                        },
                        onSubmitted: (value) {
                           _verileriGetir(aramaSorgusu: value); 
                        },
                        decoration: const InputDecoration(hintText: "İlan ara...", border: InputBorder.none)
                      )),
                      ElevatedButton(
                        onPressed: () {
                          _verileriGetir(aramaSorgusu: _aramaController.text);
                        }, 
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), 
                        child: const Text("İlanları Keşfet", style: TextStyle(color: Colors.white))
                      )
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
    bool favoriMi = _favoriIlanIdleri.contains(ilan['id']);
    final GlobalKey teklifButonKey = GlobalKey(); 

    return InkWell(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => IlanDetaySayfasi(ilan: ilan))).then((_) => _verileriGetir());
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    child: Image.network(ilan["resim"] ?? "https://via.placeholder.com/500", fit: BoxFit.cover, width: double.infinity, height: double.infinity, errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.broken_image, size: 50, color: Colors.grey))),
                  ),
                  
                  Positioned(
                    bottom: 10,
                    right: 10,
                    child: Row(
                      children: [
                        ElevatedButton(
                          key: teklifButonKey,
                          onPressed: () => _teklifMenusuGoster(context, ilan, teklifButonKey), 
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E3A8A), 
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                            minimumSize: const Size(0, 36),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                          ),
                          child: const Text("Teklif Ver", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))
                        ),
                        
                        const SizedBox(width: 8),
                        
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: favoriMi ? Colors.red.withOpacity(0.1) : Colors.white.withOpacity(0.9),
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 5)]
                          ),
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: Icon(
                              favoriMi ? Icons.favorite : Icons.favorite_border, 
                              color: favoriMi ? Colors.red : Colors.grey.shade600, 
                              size: 20
                            ),
                            onPressed: () => _favoriyeEkleCikar(ilan['id']),
                            tooltip: "Favorilere Ekle/Çıkar",
                          ),
                        )
                      ],
                    ),
                  )
                ],
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
                  Text("₺${ilan["fiyat"]}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1E3A8A))),
                  const SizedBox(height: 10),
                  Text("${ilan["sehir"] ?? "Belirtilmemiş"} • ${_tarihFormatla(ilan["created_at"])}", style: const TextStyle(color: Colors.grey, fontSize: 11)),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}