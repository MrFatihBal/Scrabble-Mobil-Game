import 'package:flutter/material.dart';
import 'package:kelimeoyunu/database.dart';

class KayitEkrani extends StatefulWidget {
  @override
  State<KayitEkrani> createState() => _KayitEkraniState();
}

class _KayitEkraniState extends State<KayitEkrani> {
  TextEditingController _emailController = TextEditingController();
  TextEditingController _usernameController = TextEditingController();
  TextEditingController _sifreController = TextEditingController();

  String _email = "";
  String _sifre = "";

  void _kayitOl() async {
    final email = _emailController.text.trim();
    final username = _usernameController.text.trim();
    final password = _sifreController.text.trim();

    final user = await Database.registerUser(email, password, username);
    print("Girilen şifre: $password");
    print("Şifre geçerli mi: ${Database.isValidPassword(password)}");

    if (user != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Kayıt başarılı!")),

      );
      Navigator.pop(context, "kayıt_basarili");
      // Ana sayfa veya giriş sayfasına yönlendirme yapabilirsin
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Kayıt başarısız. Şifre şartlarını kontrol et.")),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "KULLANICI KAYDI",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: "E-posta",
                filled: true,
                fillColor: Colors.white,
                prefixIcon: Icon(Icons.email),
              ),
            ),
            SizedBox(height: 30),
            TextField(
              controller: _usernameController,
              keyboardType: TextInputType.text,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: "Kullanıcı Adı",
                filled: true,
                fillColor: Colors.white,
                prefixIcon: Icon(Icons.abc),
              ),
            ),
            SizedBox(height: 30),
            TextField(
              controller: _sifreController,
              keyboardType: TextInputType.text,
              obscureText: true,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: "Şifre",
                filled: true,
                fillColor: Colors.white,
                prefixIcon: Icon(Icons.password),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _kayitOl,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              child: Text(
                "Kayıt Ol",
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
