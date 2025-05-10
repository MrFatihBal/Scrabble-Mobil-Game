import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kelimeoyunu/models/user_model.dart';
 // AppUser class burada tanımlı

class Database {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 🔐 Şifre geçerlilik kontrolü
  static bool isValidPassword(String password) {
    final passwordRegEx = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)[a-zA-Z\d]{8,}$');
    return passwordRegEx.hasMatch(password);
  }

  // ✅ Kullanıcı kaydı: Auth + Firestore
  static Future<AppUser?> registerUser(String email, String password, String username) async {
    if (!isValidPassword(password)) {
      print("Şifre zayıf: 8 karakter, büyük harf, küçük harf, sayı şart.");
      return null;
    }

    final existing = await _firestore
        .collection("users")
        .where("username", isEqualTo: username)
        .get();

    if (existing.docs.isNotEmpty) {
      print("Bu kullanıcı adı zaten kullanılıyor.");
      return null;
    }


    try {
      // Firebase Authentication ile kullanıcı oluştur
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;

      if (user != null) {
        // AppUser nesnesini oluştur
        AppUser newUser = AppUser(
          uid: user.uid,
          email: user.email!,
          username: username,
          puan: 0,
          createdAt: DateTime.now(),
        );

        // Firestore'a kayıt işlemi
        await _firestore.collection("users").doc(user.uid).set({
          'email': newUser.email,
          'username': newUser.username,
          'puan': newUser.puan,
          'playedGames': newUser.playedGames,  // 🔥 eklendi
          'wonGames': newUser.wonGames,        // 🔥 eklendi
          'createdAt': FieldValue.serverTimestamp(),
        });


        print("Kayıt başarılı: ${newUser.email}");
        return newUser;
      }
    } catch (e) {
      print("Kayıt hatası: $e");
    }

    return null;
  }
  static Future<AppUser?> loginWithUsername(String username, String password) async {
    try {
      // 1. Firestore’dan username'e karşılık gelen email’i bul
      final result = await _firestore
          .collection("users")
          .where("username", isEqualTo: username)
          .get();

      if (result.docs.isEmpty) {
        print("Kullanıcı adı bulunamadı.");
        return null;
      }

      final email = result.docs.first.get("email");

      // 2. Firebase Auth ile email+şifre giriş yap
      final authResult = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 3. Firebase Auth'tan gelen 'User' nesnesini 'AppUser' nesnesine dönüştür
      User? user = authResult.user;

      if (user != null) {
        AppUser appUser = AppUser(
          uid: user.uid,
          email: user.email!,
          username: username,
          puan: 0,
          createdAt: DateTime.now(),
        );

        return appUser;
      }

    } catch (e) {
      print("Giriş hatası: $e");
      return null;
    }
  }


}
