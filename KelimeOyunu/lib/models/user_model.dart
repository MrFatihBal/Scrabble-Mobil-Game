import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String email;
  final String username;
  final int puan;
  final int playedGames; // 👈 Eklenen alan
  final int wonGames;    // 👈 Eklenen alan
  final DateTime? createdAt;

  AppUser({
    required this.uid,
    required this.email,
    required this.username,
    this.puan = 0,
    this.playedGames = 0,
    this.wonGames = 0,
    this.createdAt,
  });

  factory AppUser.fromMap(String uid, Map<String, dynamic> data) {
    return AppUser(
      uid: uid,
      email: data['email'],
      username: data['username'] ?? "",
      puan: data['puan'] ?? 0,
      playedGames: data['playedGames'] ?? 0, // 👈 yeni field
      wonGames: data['wonGames'] ?? 0,        // 👈 yeni field
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'username': username,
      'puan': puan,
      'playedGames': playedGames, // 👈 firestore’a ekleniyor
      'wonGames': wonGames,       // 👈 firestore’a ekleniyor
      'createdAt': createdAt ?? DateTime.now(),
    };
  }
}
