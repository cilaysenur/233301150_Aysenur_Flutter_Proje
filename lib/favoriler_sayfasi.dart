import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'ilan_detay.dart';

class FavorilerSayfasi extends StatefulWidget {
  const FavorilerSayfasi({super.key});

  @override
  State<FavorilerSayfasi> createState() => _FavorilerSayfasiState();
}

class _FavorilerSayfasiState extends State<FavorilerSayfasi> {
  List<dynamic> _favoriler = [];

  @override
  void initState() {
    super.initState();
    _favorileriGetir();
  }

  Future<void> _favorileriGetir() async {
    final user = Supabase.instance.client.auth.currentUser;
    final data = await Supabase.instance.client
        .from('favoriler')
        .select('ilanlar(*)') 
        .eq('user_email', user!.email!);
    setState(() => _favoriler = data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Favorilerim")),
      body: ListView.builder(
        itemCount: _favoriler.length,
        itemBuilder: (context, index) {
          final ilan = _favoriler[index]['ilanlar'];
          return ListTile(
            leading: Image.network(ilan['resim'], width: 50, fit: BoxFit.cover),
            title: Text(ilan['baslik']),
            subtitle: Text("₺${ilan['fiyat']}"),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => IlanDetaySayfasi(ilan: ilan))),
          );
        },
      ),
    );
  }
}