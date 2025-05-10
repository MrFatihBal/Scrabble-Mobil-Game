import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kelimeoyunu/screens/giris_ekrani.dart';
import 'package:kelimeoyunu/screens/kayitEkrani.dart';

class AnaSayfa extends StatefulWidget {
  @override
  State<AnaSayfa> createState() => _AnaSayfaState();
}

class _AnaSayfaState extends State<AnaSayfa> {


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            "KUllANICI GİRİŞİ",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
        ),
        backgroundColor: Colors.cyan,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
                children: [


                  FractionallySizedBox(
                    widthFactor: 0.6,
                    child: ElevatedButton(
                      child: Text(
                          "Giriş Yap",
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,

                          ),
                      ),
                      onPressed: _girisYap,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,

                      ) ,
                    ),
                  ),
                  SizedBox(height: 30,),
                  FractionallySizedBox(
                    widthFactor: 0.6,
                    child: ElevatedButton(
                      child: Text(
                        "Kayıt Ol",
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,

                        ),
                      ),
                      onPressed: (){
                        _kayitOl(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,

                      ) ,
                    ),
                  ),

                ],
          ),
        ),
      ),
      backgroundColor: Colors.grey
      ,
    );
  }
  void _girisYap() {
    MaterialPageRoute _sayfayolu=MaterialPageRoute(builder: (BuildContext context){
      return GirisEkrani();
    });
    Navigator.push(context, _sayfayolu);
  }
  void _kayitOl(BuildContext context){
    MaterialPageRoute _sayfayolu=MaterialPageRoute(builder: (BuildContext context){
      return KayitEkrani();
    });
    Navigator.push(context, _sayfayolu);
  }
}
