import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kelimeoyunu/models/user_model.dart';
import 'package:kelimeoyunu/screens/gecmis_oyunlar_ekrani.dart';
import 'package:kelimeoyunu/services/waiting_service.dart';
import 'package:kelimeoyunu/screens/game_screen2.dart';

class AnaOyunEkrani extends StatefulWidget {
  final AppUser user;

  const AnaOyunEkrani({Key? key, required this.user}) : super(key: key);

  @override
  State<AnaOyunEkrani> createState() => _AnaOyunEkraniState();
}

class _AnaOyunEkraniState extends State<AnaOyunEkrani> {
  String? selectedMode;
  bool isFindingGame = false;
  StreamSubscription<DocumentSnapshot>? waitingListener;
  StreamSubscription<QuerySnapshot>? gameListener;

  @override
  void dispose() {
    waitingListener?.cancel();
    gameListener?.cancel();
    super.dispose();
  }

  void _findGame() async {
    if (selectedMode == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen oyun süresi seç!")),
      );
      return;
    }

    setState(() {
      isFindingGame = true;
    });

    String? gameId = await WaitingService.findMatchAndCreateGame(widget.user, mode: selectedMode!);

    if (gameId != null) {
      _goToGameScreen(gameId);
    } else {
      _listenForWaitingChanges();
    }
  }

  void _listenForWaitingChanges() {
    final waitingRef = FirebaseFirestore.instance
        .collection('waiting_players')
        .doc(widget.user.uid);

    waitingListener = waitingRef.snapshots().listen((snapshot) {
      if (!snapshot.exists) {
        _listenForGameCreated();
        waitingListener?.cancel();
      }
    });
  }

  void _listenForGameCreated() {
    final gamesRef = FirebaseFirestore.instance.collection('games');

    gameListener = gamesRef
        .where('playerUids', arrayContains: widget.user.uid)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        final gameId = snapshot.docs.first.id;
        _goToGameScreen(gameId);
        gameListener?.cancel();
      }
    });
  }

  void _goToGameScreen(String gameId) {
    setState(() {
      isFindingGame = false;
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GameScreen2(
          gameId: gameId,
          currentUser: widget.user,
        ),
      ),
    );
  }

  String modYazisi(String mode) {
    switch (mode) {
      case '2m': return '2 Dakika';
      case '5m': return '5 Dakika';
      case '12h': return '12 Saat';
      case '24h': return '24 Saat';
      default: return mode;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Hoşgeldin ${widget.user.username}", style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.cyan,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance.collection('users').doc(widget.user.uid).snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const CircularProgressIndicator();

                    final data = snapshot.data!.data() as Map<String, dynamic>;
                    final puan = data['puan'] ?? 0;
                    final oynanan = data['playedGames'] ?? 0;
                    final kazanilan = data['wonGames'] ?? 0;
                    final success = oynanan == 0 ? 0.0 : (kazanilan / oynanan * 100);

                    return Column(
                      children: [
                        const SizedBox(height: 20),
                        Text("Başarı Yüzdesi: ${success.toStringAsFixed(1)}%", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        Text("Oynanan Oyun: $oynanan", style: const TextStyle(fontSize: 16)),
                        Text("Kazanılan Oyun: $kazanilan", style: const TextStyle(fontSize: 16)),
                        const SizedBox(height: 30),
                        Text("Toplam Puan: $puan", style: const TextStyle(fontSize: 16)),
                        const SizedBox(height: 30),
                        const Text("Aktif Oyunlar", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 250,
                          child: StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('games')
                                .where('playerUids', arrayContains: widget.user.uid)
                                .where('gameStatus', isEqualTo: 'ongoing')
                                .orderBy('createdAt', descending: true)
                                .snapshots(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                              final games = snapshot.data!.docs;
                              if (games.isEmpty) return const Center(child: Text("Aktif oyun bulunamadı."));

                              return ListView.builder(
                                itemCount: games.length,
                                itemBuilder: (context, index) {
                                  final game = games[index];
                                  final data = game.data() as Map<String, dynamic>;
                                  final player1 = data['player1']['username'];
                                  final player2 = data['player2']['username'];
                                  final rakip = widget.user.username == player1 ? player2 : player1;
                                  final gameId = game.id;

                                  return Card(
                                    child: ListTile(
                                      title: Text("Rakip: $rakip"),
                                      subtitle: Text("Mod: ${modYazisi(data['mode'])} - Durum: ${data['gameStatus']}"),
                                      trailing: const Icon(Icons.arrow_forward),
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => GameScreen2(
                                              gameId: gameId,
                                              currentUser: widget.user,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              const Text("Oyun Süresi Seç", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 12,
                children: [
                  ChoiceChip(label: const Text("2dk"), selected: selectedMode == "2m", onSelected: (_) => setState(() => selectedMode = "2m")),
                  ChoiceChip(label: const Text("5dk"), selected: selectedMode == "5m", onSelected: (_) => setState(() => selectedMode = "5m")),
                  ChoiceChip(label: const Text("12s"), selected: selectedMode == "12h", onSelected: (_) => setState(() => selectedMode = "12h")),
                  ChoiceChip(label: const Text("24s"), selected: selectedMode == "24h", onSelected: (_) => setState(() => selectedMode = "24h")),
                ],
              ),
              Center(
                child: ElevatedButton(
                  onPressed: isFindingGame ? null : _findGame,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyan,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  ),
                  child: Text(
                    isFindingGame ? "Oyun aranıyor..." : "Yeni Oyun Başlat",
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => GecmisOyunlarEkrani(user: widget.user),
                      ),
                    );
                  },
                  child: const Text("📜 Geçmiş Oyunlarım", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}