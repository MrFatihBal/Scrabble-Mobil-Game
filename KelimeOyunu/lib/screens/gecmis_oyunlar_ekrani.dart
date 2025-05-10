
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:kelimeoyunu/models/game_board.dart';
import 'package:kelimeoyunu/models/user_model.dart';
import 'package:kelimeoyunu/screens/gecmis_oyun_detay_ekrani.dart';

class GecmisOyunlarEkrani extends StatelessWidget {
  final AppUser user;
  const GecmisOyunlarEkrani({required this.user, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final gamesRef = FirebaseFirestore.instance
        .collection('games')
        .where('playerUids', arrayContains: user.uid)
        .where('gameStatus', isEqualTo: 'finished')
        .orderBy('createdAt', descending: true);

    return Scaffold(
      appBar: AppBar(title: Text("Geçmiş Oyunlar")),
      body: StreamBuilder<QuerySnapshot>(
        stream: gamesRef.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

          final games = snapshot.data!.docs;

          return ListView.builder(
            itemCount: games.length,
            itemBuilder: (context, index) {
              final game = games[index];
              final data = game.data() as Map<String, dynamic>;
              final kazandiMi = data['winnerUid'] == user.uid;

              return ListTile(
                title: Text("Rakip: ${_getRakipIsim(data, user)}"),
                subtitle: Text("Mod: ${data['mode']}"),
                trailing: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: kazandiMi ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    kazandiMi ? "Galibiyet" : "Yenilgi",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                onTap: () {
                  final boardMap = data['board'];
                  if (boardMap == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Tahta verisi bulunamadı.')),
                    );
                    return;
                  }
                  final board = GameBoard.fromMap(boardMap);
                  final p1 = data['player1']['username'];
                  final p2 = data['player2']['username'];

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => GecmisOyunDetayEkrani(
                        player1: p1,
                        player2: p2,
                        board: board,
                      ),
                    ),
                  );
                },

              );
            },
          );
        },
      ),
    );
  }

  String _getRakipIsim(Map<String, dynamic> data, AppUser user) {
    final p1 = data['player1']['username'];
    final p2 = data['player2']['username'];
    return p1 == user.username ? p2 : p1;
  }
}
