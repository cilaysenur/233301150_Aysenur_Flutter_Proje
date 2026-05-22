import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class IlanEkleSayfasi extends StatefulWidget {
  const IlanEkleSayfasi({super.key});

  @override
  State<IlanEkleSayfasi> createState() => _IlanEkleSayfasiState();
}

class _IlanEkleSayfasiState extends State<IlanEkleSayfasi> {
  final _baslikController = TextEditingController();
  final _fiyatController = TextEditingController();
  final _aciklamaController = TextEditingController();
  
  String? _seciliKategori;
  final List<String> _kategoriler = ["Elektronik", "Vasıta", "Emlak", "Mobilya", "Giyim", "Spor Malzemesi", "Kitap", "Müzik Aleti", "Oyun & Konsol", "Beyaz Eşya"]; // SQL ile uyumlu
  
  // ŞEHİRLER İÇİN YENİ DROPDOWN LİSTESİ (SQL ile uyumlu)
  String? _seciliSehir;
  final List<String> _sehirler = ['Istanbul', 'Ankara', 'Izmir', 'Bursa', 'Antalya', 'Adana', 'Konya', 'Gaziantep', 'Trabzon', 'Eskisehir', 'Kayseri', 'Samsun', 'Mersin', 'Diyarbakir', 'Malatya'];
  
  bool _yukleniyor = false;
  
  Uint8List? _secilenResimBytes;

  Future<void> _resimSec() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _secilenResimBytes = bytes;
      });
    }
  }

  Future<void> _ilaniKaydet() async {
    // Şehir de boş bırakılmasın diye kontrol ekledik
    if (_baslikController.text.isEmpty || _fiyatController.text.isEmpty || _secilenResimBytes == null || _seciliKategori == null || _seciliSehir == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lütfen tüm alanları doldurun, kategori, şehir ve resim seçin!")));
      return;
    }

    setState(() { _yukleniyor = true; });

    try {
      final guvenliDosyaAdi = 'ilan_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final resimYolu = 'ilanlar/$guvenliDosyaAdi';
      
      await Supabase.instance.client.storage
          .from('ilan_resimleri')
          .uploadBinary(resimYolu, _secilenResimBytes!);
          
      final resimUrl = Supabase.instance.client.storage
          .from('ilan_resimleri')
          .getPublicUrl(resimYolu);

      final user = Supabase.instance.client.auth.currentUser;
      final userEmail = user?.email ?? 'Bilinmeyen Kullanıcı';
      final saticiAdi = userEmail != 'Bilinmeyen Kullanıcı' ? userEmail.split('@')[0] : 'Anonim';

      await Supabase.instance.client.from('ilanlar').insert({
        'baslik': _baslikController.text.trim(),
        'kategori': _seciliKategori, 
        'sehir': _seciliSehir, // Dropdown'dan gelen veriyi kaydediyoruz
        'fiyat': _fiyatController.text.trim(),
        'aciklama': _aciklamaController.text.trim(),
        'satici': saticiAdi,
        'email': userEmail,  
        'resim': resimUrl, 
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("İlan Başarıyla Eklendi!"), backgroundColor: Colors.green));
        Navigator.pop(context, true); 
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: $e"), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() { _yukleniyor = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text("Yeni İlan Ver"), backgroundColor: Colors.white, foregroundColor: const Color(0xFF1E3A8A), elevation: 0),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800), 
          padding: const EdgeInsets.all(30.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Ürün Görseli", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 10),
                
                InkWell(
                  onTap: _resimSec,
                  child: Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.grey.shade300, width: 2),
                    ),
                    child: _secilenResimBytes != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(13),
                            child: Image.memory(_secilenResimBytes!, fit: BoxFit.cover, width: double.infinity),
                          )
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo_outlined, size: 50, color: Colors.grey),
                              SizedBox(height: 10),
                              Text("Fotoğraf Yüklemek İçin Tıklayın", style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                  ),
                ),
                
                _buildInputLabel("İlan Başlığı"), _buildTextField("Örn: iPhone 14", controller: _baslikController),
                
                // KATEGORİ VE ŞEHİR YAN YANA DROPDOWN
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start, 
                        children: [
                          _buildInputLabel("Kategori"), 
                          _buildDropdown(
                            deger: _seciliKategori, 
                            liste: _kategoriler, 
                            ipucu: "Kategori Seç", 
                            degisti: (yeni) => setState(() => _seciliKategori = yeni)
                          )
                        ]
                      )
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start, 
                        children: [
                          _buildInputLabel("Şehir"), 
                          _buildDropdown(
                            deger: _seciliSehir, 
                            liste: _sehirler, 
                            ipucu: "Şehir Seç", 
                            degisti: (yeni) => setState(() => _seciliSehir = yeni)
                          )
                        ]
                      )
                    ),
                  ],
                ),
                
                _buildInputLabel("Fiyat (₺)"), _buildTextField("Örn: 5000", controller: _fiyatController, isNumber: true),
                _buildInputLabel("Açıklama"), _buildTextField("Ürün bilgileri...", controller: _aciklamaController, maxLines: 4),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    onPressed: _yukleniyor ? null : _ilaniKaydet,
                    child: _yukleniyor ? const CircularProgressIndicator(color: Colors.white) : const Text("İlanı Yayınla", style: TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputLabel(String text) => Padding(padding: const EdgeInsets.only(bottom: 8.0, top: 20.0), child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)));
  
  Widget _buildTextField(String hint, {TextEditingController? controller, int maxLines = 1, bool isNumber = false}) {
    return TextField(
      controller: controller, maxLines: maxLines, keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(hintText: hint, filled: true, fillColor: const Color(0xFFF8FAFC), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)),
    );
  }

  // Yeni oluşturduğumuz genel Dropdown yapıcı metodumuz
  Widget _buildDropdown({required String? deger, required List<String> liste, required String ipucu, required Function(String?) degisti}) {
    return DropdownButtonFormField<String>(
      value: deger,
      hint: Text(ipucu),
      decoration: InputDecoration(
        filled: true, 
        fillColor: const Color(0xFFF8FAFC), 
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)
      ),
      items: liste.map((String eleman) {
        return DropdownMenuItem<String>(value: eleman, child: Text(eleman));
      }).toList(),
      onChanged: degisti,
    );
  }
}