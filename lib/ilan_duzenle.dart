import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class IlanDuzenleSayfasi extends StatefulWidget {
  final Map<String, dynamic> ilan; // Düzenlenecek ilan verisi
  const IlanDuzenleSayfasi({super.key, required this.ilan});

  @override
  State<IlanDuzenleSayfasi> createState() => _IlanDuzenleSayfasiState();
}

class _IlanDuzenleSayfasiState extends State<IlanDuzenleSayfasi> {
  late TextEditingController _baslikController;
  late TextEditingController _fiyatController;
  late TextEditingController _aciklamaController;
  
  String? _seciliKategori;
  final List<String> _kategoriler = ["Elektronik", "Vasıta", "Emlak", "Mobilya", "Giyim", "Spor Malzemesi", "Kitap", "Müzik Aleti", "Oyun & Konsol", "Beyaz Eşya"];
  
  String? _seciliSehir;
  final List<String> _sehirler = ['Istanbul', 'Ankara', 'Izmir', 'Bursa', 'Antalya', 'Adana', 'Konya', 'Gaziantep', 'Trabzon', 'Eskisehir', 'Kayseri', 'Samsun', 'Mersin', 'Diyarbakir', 'Malatya'];
  
  bool _yukleniyor = false;
  Uint8List? _yeniResimBytes;

  @override
  void initState() {
    super.initState();
    // Mevcut verileri controller'lara dolduruyoruz
    _baslikController = TextEditingController(text: widget.ilan['baslik']);
    _fiyatController = TextEditingController(text: widget.ilan['fiyat'].toString());
    _aciklamaController = TextEditingController(text: widget.ilan['aciklama']);
    _seciliKategori = widget.ilan['kategori'];
    _seciliSehir = widget.ilan['sehir'];
  }

  Future<void> _resimSec() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() => _yeniResimBytes = bytes);
    }
  }

  Future<void> _ilaniGuncelle() async {
    if (_baslikController.text.isEmpty || _fiyatController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Başlık ve Fiyat boş olamaz!")));
      return;
    }

    setState(() => _yukleniyor = true);

    try {
      String resimUrl = widget.ilan['resim']; // Varsayılan olarak eski resmi tut

      // Eğer kullanıcı yeni resim seçtiyse, Storage'a yükle
      if (_yeniResimBytes != null) {
        final dosyaAdi = 'ilan_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final yol = 'ilanlar/$dosyaAdi';
        await Supabase.instance.client.storage.from('ilan_resimleri').uploadBinary(yol, _yeniResimBytes!);
        resimUrl = Supabase.instance.client.storage.from('ilan_resimleri').getPublicUrl(yol);
      }

      // Veritabanını Güncelle
      await Supabase.instance.client.from('ilanlar').update({
        'baslik': _baslikController.text.trim(),
        'kategori': _seciliKategori,
        'sehir': _seciliSehir,
        'fiyat': _fiyatController.text.trim(),
        'aciklama': _aciklamaController.text.trim(),
        'resim': resimUrl,
      }).eq('id', widget.ilan['id']);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("İlan Başarıyla Güncellendi!"), backgroundColor: Colors.green));
        Navigator.pop(context, true); // Geri dönerken 'true' döndür ki liste yenilensin
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: $e"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _yukleniyor = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("İlanı Düzenle"), backgroundColor: Colors.white, foregroundColor: Colors.black, elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Ürün Görseli (Değiştirmek için tıklayın)", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            InkWell(
              onTap: _resimSec,
              child: Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(15)),
                child: _yeniResimBytes != null 
                  ? Image.memory(_yeniResimBytes!, fit: BoxFit.cover)
                  : Image.network(widget.ilan['resim'], fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 20),
            _buildInputLabel("İlan Başlığı"),
            TextField(controller: _baslikController, decoration: _inputDeco("Başlık girin")),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: _buildDropdown("Kategori", _seciliKategori, _kategoriler, (v) => setState(() => _seciliKategori = v))),
                const SizedBox(width: 20),
                Expanded(child: _buildDropdown("Şehir", _seciliSehir, _sehirler, (v) => setState(() => _seciliSehir = v))),
              ],
            ),
            const SizedBox(height: 20),
            _buildInputLabel("Fiyat (₺)"),
            TextField(controller: _fiyatController, keyboardType: TextInputType.number, decoration: _inputDeco("Fiyat")),
            const SizedBox(height: 20),
            _buildInputLabel("Açıklama"),
            TextField(controller: _aciklamaController, maxLines: 4, decoration: _inputDeco("Açıklama")),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A)),
                onPressed: _yukleniyor ? null : _ilaniGuncelle,
                child: _yukleniyor ? const CircularProgressIndicator(color: Colors.white) : const Text("Değişiklikleri Kaydet", style: TextStyle(color: Colors.white)),
              ),
            )
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String hint) => InputDecoration(hintText: hint, filled: true, fillColor: Colors.grey.shade100, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none));
  Widget _buildInputLabel(String text) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)));
  Widget _buildDropdown(String label, String? deger, List<String> liste, Function(String?) degisti) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildInputLabel(label),
      DropdownButtonFormField<String>(value: deger, items: liste.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: degisti, decoration: _inputDeco(label))
    ]);
  }
}