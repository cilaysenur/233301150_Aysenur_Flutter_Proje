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
  final _sehirController = TextEditingController();
  final _fiyatController = TextEditingController();
  final _aciklamaController = TextEditingController();
  
  String? _seciliKategori;
  final List<String> _kategoriler = ["Elektronik", "Vasıta", "Moda", "Kitap", "Mobilya", "Hobi", "Diğer"];
  
  bool _yukleniyor = false;
  
  Uint8List? _secilenResimBytes;
  String? _secilenResimAdi;

  Future<void> _resimSec() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _secilenResimBytes = bytes;
        _secilenResimAdi = image.name;
      });
    }
  }

  Future<void> _ilaniKaydet() async {
    if (_baslikController.text.isEmpty || _fiyatController.text.isEmpty || _secilenResimBytes == null || _seciliKategori == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lütfen tüm alanları doldurun, kategori ve resim seçin!")));
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
        'sehir': _sehirController.text.trim(),
        'fiyat': _fiyatController.text.trim(),
        'aciklama': _aciklamaController.text.trim(),
        'satici': saticiAdi,
        'email': userEmail,  
        'resim': resimUrl, 
      });

      try {
        await Supabase.instance.client.from('islem_loglari').insert({
          'islem_turu': 'Yeni İlan Ekleme',
          'kullanici_email': userEmail,
        });
      } catch (logHatasi) {
        debugPrint("Log kaydedilemedi: $logHatasi");
      }

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
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start, 
                        children: [
                          _buildInputLabel("Kategori"), 
                          DropdownButtonFormField<String>(
                            value: _seciliKategori,
                            hint: const Text("Kategori Seçiniz"),
                            decoration: InputDecoration(
                              filled: true, 
                              fillColor: const Color(0xFFF8FAFC), 
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)
                            ),
                            items: _kategoriler.map((String kategori) {
                              return DropdownMenuItem<String>(
                                value: kategori,
                                child: Text(kategori),
                              );
                            }).toList(),
                            onChanged: (String? yeniDeger) {
                              setState(() {
                                _seciliKategori = yeniDeger;
                              });
                            },
                          )
                        ]
                      )
                    ),
                    const SizedBox(width: 20),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildInputLabel("Şehir"), _buildTextField("Şehir Seçiniz", controller: _sehirController)])),
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
}