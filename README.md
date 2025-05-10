# Scrabble-Mobil-Game
# 🔠 Kelime Oyunu (Flutter + Firebase)

Bu proje, oyuncuların 15x15'lik tahta üzerinde gerçek zamanlı olarak yarıştığı bir Scrabble tarzı çevrim içi kelime oyunudur.

## 🧩 Özellikler

- 🔐 Firebase Auth ile kullanıcı kaydı ve girişi
- 🧠 Gerçek zamanlı eşleşme sistemi
- 📅 Hızlı Oyun (2dk, 5dk), Uzun Oyun (12s, 24s) seçenekleri
- 🔤 Harf puanlama sistemi ve tuzak/çarpan özellikli kareler
- 🎮 Gerçek zamanlı oyun senkronizasyonu
- 📊 Oyuncu puanları, sıralama ve geçmiş oyunlar görüntüleme
- 💾 Firestore entegrasyonu ile tüm veriler bulutta

## 📁 Proje Yapısı

lib/
├── main.dart # Uygulama başlangıç noktası
├── database.dart # Firestore işlemleri
├── models/ # User, GameBoard, Letter, vb.
├── screens/ # Ana ekran, oyun ekranı, geçmiş oyunlar
├── services/ # Oyun eşleştirme ve kontrol servisleri
├── utils/ # Oyun kuralları, kelime doğrulama
└── widgets/ # GameBoard, CellWidget, harf çekme, vs.

