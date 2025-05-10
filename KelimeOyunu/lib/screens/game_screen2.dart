import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kelimeoyunu/models/cell.dart';
import 'package:kelimeoyunu/models/kelime_kontrol.dart';
import 'package:kelimeoyunu/models/tile_bag.dart';
import 'package:kelimeoyunu/models/user_model.dart';
import 'package:kelimeoyunu/models/game_board.dart';
import 'package:kelimeoyunu/models/letter.dart';
import 'package:kelimeoyunu/utils/score_utils.dart';
import 'package:kelimeoyunu/utils/word_repository.dart';
import 'package:kelimeoyunu/widgets/game_board_widget.dart';
import 'package:kelimeoyunu/widgets/hand_widget.dart';

class GameScreen2 extends StatefulWidget {
  final String gameId;
  final AppUser currentUser;

  const GameScreen2({Key? key, required this.gameId, required this.currentUser}) : super(key: key);

  @override
  State<GameScreen2> createState() => _GameScreen2State();
}

class _GameScreen2State extends State<GameScreen2> {
  late DocumentReference gameRef;
  Map<String, dynamic>? gameData;
  Map<String, dynamic>? currentPlayerData;
  Map<String, dynamic>? opponentPlayerData;
  bool isMyTurn = false;
  Letter? selectedLetter;
  late GameBoard board;
  List<Letter> playerHand = [];
  String? lastValidWord;
  int? lastGainedScore;
  late int turnLimitMs;
  Timer? turnTimer;
  DateTime? lastMoveTime;
  Duration? remainingTime;
  Timer? uiTimer;
  int remainingSeconds = 0;
  Timer? countdownTimer;





  @override
  late StreamSubscription<DocumentSnapshot> gameSubscription;
  void _setupTurnLimit() {
    final mode = gameData?['mode'] ?? '5m'; // varsayılan
    switch (mode) {
      case '2m':
        turnLimitMs = 2 * 60 * 1000;
        break;
      case '5m':
        turnLimitMs = 5 * 60 * 1000;
        break;
      case '12h':
        turnLimitMs = 12 * 60 * 60 * 1000;
        break;
      case '24h':
        turnLimitMs = 24 * 60 * 60 * 1000;
        break;
      default:
        turnLimitMs = 5 * 60 * 1000;
    }
  }
  void startTurnTimer() {
    if (!mounted || gameData == null || currentPlayerData == null || opponentPlayerData == null) return;

    final mode = gameData!['mode']; // Örn: '2m', '5m', '12h', '24h'
    final lastMoveAt = (gameData!['lastMoveAt'] as Timestamp?)?.toDate();

    if (lastMoveAt == null) return;

    final now = DateTime.now();
    final elapsed = now.difference(lastMoveAt).inSeconds;

    final allowedSeconds = switch (mode) {
      '2m' => 120,
      '5m' => 300,
      '12h' => 43200,
      '24h' => 86400,
      _ => 300
    };


    if (elapsed >= allowedSeconds) {
      _handleLossDueToTimeout();
      return;
    }

    // Süreyi başlat
    turnTimer?.cancel();
    remainingSeconds = allowedSeconds - elapsed;

    turnTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (!mounted) return;

      setState(() {
        remainingSeconds--;
      });

      if (remainingSeconds <= 0) {
        timer.cancel();
        await _handleLossDueToTimeout();
      }
    });
  }


  Future<void> _handleLossDueToTimeout() async {
    if (!mounted || gameData == null || currentPlayerData == null || opponentPlayerData == null) return;

    final winnerUid = opponentPlayerData!['uid'];
    final loserUid = currentPlayerData!['uid'];

    await gameRef.update({
      'gameStatus': 'finished',
      'winnerUid': winnerUid,
      'loserUid': loserUid,
      'finishedAt': FieldValue.serverTimestamp(),
    });
    final userRef = FirebaseFirestore.instance.collection('users');

    await userRef.doc(winnerUid).update({
      'wonGames': FieldValue.increment(1),
      'playedGames': FieldValue.increment(1),
      'puan': FieldValue.increment(10),
    });
    await userRef.doc(loserUid).update({
      'playedGames': FieldValue.increment(1),
      'puan': FieldValue.increment(1),
    });
    await FirebaseFirestore.instance.collection('users').doc(winnerUid).update({
      'wonGames': FieldValue.increment(1),
      'playedGames': FieldValue.increment(1),
      'puan': FieldValue.increment(50),
    });

    await FirebaseFirestore.instance.collection('users').doc(currentPlayerData!['uid']).update({
      'playedGames': FieldValue.increment(1),
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Süren doldu, oyunu kaybettin.")),
      );

      Navigator.pop(context);
    }
  }



  Duration? _getDurationFromMode(String? mode) {
    switch (mode) {
      case '2m':
        return const Duration(minutes: 2);
      case '5m':
        return const Duration(minutes: 5);
      case '12h':
        return const Duration(hours: 12);
      case '24h':
        return const Duration(hours: 24);
      default:
        return null;
    }
  }

  @override
  void initState() {
    super.initState();
    gameRef = FirebaseFirestore.instance.collection('games').doc(widget.gameId);
    _setupTurnLimit();

    gameSubscription = gameRef.snapshots().listen((snapshot) {
      if (!snapshot.exists) return;

      final data = snapshot.data() as Map<String, dynamic>;
      final player1 = data['player1'] as Map<String, dynamic>;
      final player2 = data['player2'] as Map<String, dynamic>;

      if (player1['uid'] == widget.currentUser.uid) {
        currentPlayerData = player1;
        opponentPlayerData = player2;
      } else {
        currentPlayerData = player2;
        opponentPlayerData = player1;
      }

      final currentTurnUid = data['currentTurnUid'];
      final isMyTurnNow = currentTurnUid == widget.currentUser.uid;

      if (data['board'] != null) {
        board = GameBoard.fromMap(data['board']);
      }

      playerHand = (currentPlayerData!['hand'] as List)
          .map((e) => Letter.fromMap(e))
          .toList();

      if (mounted) {
        setState(() {
          gameData = data;
          isMyTurn = isMyTurnNow;

        });
      }
      if (mounted && isMyTurnNow) {
        startTurnTimer();
      }

    });
    turnTimer = Timer.periodic(Duration(seconds: 10), (_) {
      _checkTimeLimit();
    });

  }
  @override
  void dispose() {
    gameSubscription.cancel();

    turnTimer?.cancel();
    uiTimer?.cancel();
    super.dispose();
  }
  void _checkTimeLimit() async {
    if (gameData == null || !isMyTurn) return;

    final lastMoveAt = (gameData!['lastMoveAt'] as Timestamp).toDate();
    final now = DateTime.now();

    final mode = gameData!['mode'];
    Duration limit;

    switch (mode) {
      case '2m':
        limit = Duration(minutes: 2);
        break;
      case '5m':
        limit = Duration(minutes: 5);
        break;
      case '12h':
        limit = Duration(hours: 12);
        break;
      case '24h':
        limit = Duration(hours: 24);
        break;
      default:
        return;
    }

    if (now.difference(lastMoveAt) > limit) {
      // Kaybetti!
      final playerKey = currentPlayerData!['uid'] == gameData!['player1']['uid']
          ? 'player1'
          : 'player2';

      final winnerKey = playerKey == 'player1' ? 'player2' : 'player1';

      await gameRef.update({
        'gameStatus': 'finished',
        'winner': gameData![winnerKey]['uid'],
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Süre doldu! Oyunu kaybettin.")),
      );
    }
  }

  Future<void> _handleOyunuBitir() async {
    if (!isMyTurn || gameData == null) return;

    final myUid = widget.currentUser.uid;
    final currentList = List<String>.from(gameData!['bitirmekIsteyenler'] ?? []);

    if (!currentList.contains(myUid)) {
      currentList.add(myUid);
      await gameRef.update({'bitirmekIsteyenler': currentList});
    }

    // Eğer her iki oyuncu da bitirmek istemişse
    if (currentList.length == 2) {
      final p1 = gameData!['player1'];
      final p2 = gameData!['player2'];

      final p1Score = p1['score'] ?? 0;
      final p2Score = p2['score'] ?? 0;

      final winnerUid = p1Score == p2Score
          ? null // Beraberlik
          : (p1Score > p2Score ? p1['uid'] : p2['uid']);

      await gameRef.update({
        'gameStatus': 'finished',
        'winnerUid': winnerUid,
        'finishedAt': FieldValue.serverTimestamp(),
      });

      final userRef = FirebaseFirestore.instance.collection('users');
      await userRef.doc(p1['uid']).update({
        'playedGames': FieldValue.increment(1),
        if (winnerUid == p1['uid']) 'wonGames': FieldValue.increment(1),
        'puan': FieldValue.increment(winnerUid == p1['uid'] ? 50 : 1),
      });
      await userRef.doc(p2['uid']).update({
        'playedGames': FieldValue.increment(1),
        if (winnerUid == p2['uid']) 'wonGames': FieldValue.increment(1),
        'puan': FieldValue.increment(winnerUid == p2['uid'] ? 50 : 1),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("🏁 Oyun bitirildi!")),
        );
        Navigator.pop(context); // geri dön
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Karşı oyuncunun da onaylaması bekleniyor...")),
      );
    }
  }


  void _geriAlHarfleri(List<Cell> newCells) {
    setState(() {
      for (var cell in newCells) {
        if (cell.letter != null) {
          playerHand.add(Letter(character: cell.letter!,point: 0)); // ele geri ver
        }
        cell.letter = null; // hücreyi boşalt
        cell.isNew = false; // artık yeni değil
      }
      selectedLetter = null; // seçim sıfırla
    });
  }

  void _handleSiraGec() async {
    final player1Uid = gameData!['player1']['uid'];
    final nextTurnUid = currentPlayerData!['uid'] == player1Uid
        ? gameData!['player2']['uid']
        : player1Uid;

    await gameRef.update({
      'currentTurnUid': nextTurnUid,
      'lastMoveAt': FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Sıra geçti!")),
    );
  }


  void _handleOnayla() async {
    if (!isMyTurn) return;

    // 1. Yeni eklenen hücreleri topla
    final isFirstMove = board.cells.every(
          (row) => row.every((cell) => cell.letter == null),
    );

    final newCells = board.cells
        .expand((row) => row)
        .where((c) => c.isNew && c.letter != null)
        .toList();

    if (newCells.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Hiç harf koymadın!")),
      );
      return;
    }

    // 2. Kelime kontrol objesi
    final kelimeKontrol = KelimeKontrol(cells: board.cells, newCells: newCells);

    // 3. Tahta tamamen boşsa → ilk hamle


    // 4. İlk hamlede merkezden geçmeli
    // 🔁 Yeni ilk hamle kontrolü (ikili şart)
    // 🔁 Yeni ilk hamle kontrolü: Ya merkezden geç ya da temas et
    if (isFirstMove) {
      final merkezdeMi = newCells.any((c) => c.x == 7 && c.y == 7);
      final temasVarMi = kelimeKontrol.isConnectedToExisting();

      if (!merkezdeMi && !temasVarMi) {
        _geriAlHarfleri(newCells);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("İlk hamlede ya ortadan (7,7) geçmeli ya da harfe temas etmeli!")),
        );
        return;
      }
    }



    // 6. Oluşan kelimeleri al
    final kelimeler = kelimeKontrol.getOlusanKelimeler();

    // 7. Geçersiz kelimeler varsa geri al
    final gecersiz = kelimeler.where((k) => !WordRepository.isValidWord(k)).toList();
    if (gecersiz.isNotEmpty) {
      _geriAlHarfleri(newCells);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Geçersiz kelime: ${gecersiz.join(', ')}")),
      );
      return;
    }


    print("✅ Tüm kelimeler geçerli: $kelimeler");
    final kelimelerWithCells = kelimeKontrol.getOlusanKelimelerWithCoords();
    int gainedScore = calculateScore(kelimelerWithCells);
    bool hasPuanTransfer = false;
    bool hasHarfKaybi = false;
    List<String> triggeredTraps = [];


    for (var word in kelimelerWithCells) {
      final cells = word['hücreler'] as List<Cell>;
      for (final cell in cells) {
        if (cell.hasTrap) {
          final String? trap = cell.trapType;
          if (cell.trapType == 'puan_transfer') hasPuanTransfer = true;
          if (cell.trapType == 'harf_kaybi') hasHarfKaybi = true;

          if (!triggeredTraps.contains(trap)) {
            triggeredTraps.add(trap!);
          }
        }
      }
    }
    if (triggeredTraps.isNotEmpty) {
      final aciklama = triggeredTraps.map((t) {
        switch (t) {
          case 'puan_transfer': return 'puan rakibe aktarıldı';
          case 'harf_kaybi': return 'harflerin sıfırlandı';
          case 'puan_bol': return 'puan %30’a düştü';
          case 'kelime_iptal': return 'kelime iptal edildi';
          case 'kat_engeli': return 'çarpanlar etkisizleştirildi';
          default: return t;
        }
      }).join(', ');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('💣 Tuzak tetiklendi: $aciklama')),
      );
    }


    if (hasPuanTransfer) {
      final rakipKey = currentPlayerData!['uid'] == gameData!['player1']['uid'] ? 'player2' : 'player1';
      final rakipOldScore = gameData![rakipKey]['score'] ?? 0;
      await gameRef.update({
        '$rakipKey.score': rakipOldScore + gainedScore,
      });
      gainedScore = 0;
    }

    if (hasHarfKaybi) {
      playerHand.clear();
      final tileBagMap = gameData!['tileBag'] as Map<String, dynamic>;
      final tileBag = TileBag.fromMap(tileBagMap);
      final yeniHarfler = tileBag.drawMultipleLetters(7);
      playerHand.addAll(yeniHarfler);
    }


    setState(() {
      lastValidWord = kelimeler.join(', ');
      lastGainedScore = gainedScore;
    });


// skoru Firestore'a yazabilmek için
    final playerKey = currentPlayerData!['uid'] == gameData!['player1']['uid'] ? 'player1' : 'player2';



    // 8. isNew=false yap
    for (var cell in newCells) {
      cell.isNew = false;
    }

    // 9. TileBag'i al
    final tileBagMap = gameData!['tileBag'] as Map<String, dynamic>;
    final tileBag = TileBag.fromMap(tileBagMap);

    // 10. Harfleri 7’ye tamamla
    final drawCount = 7 - playerHand.length;
    final newLetters = tileBag.drawMultipleLetters(drawCount);
    playerHand.addAll(newLetters);

    // 11. Sıra karşıya geçsin
    final player1Uid = gameData!['player1']['uid'];
    final nextTurnUid = currentPlayerData!['uid'] == player1Uid
        ? gameData!['player2']['uid']
        : player1Uid;

    // 12. Firestore güncelle
    final oldScore = currentPlayerData!['score'] ?? 0;
    final newScore = oldScore + gainedScore;

// Firestore'a tek seferde güncelle:
    await gameRef.update({
      'board': board.toMap(),
      'tilebag': tileBag.toMap(),
      '${currentPlayerData!['uid'] == player1Uid ? 'player1' : 'player2'}.hand': playerHand.map((l) => l.toMap()).toList(),
      '${currentPlayerData!['uid'] == player1Uid ? 'player1' : 'player2'}.score': newScore,
      'currentTurnUid': nextTurnUid,
      'lastMoveTime': FieldValue.serverTimestamp(),
      'lastMoveAt': FieldValue.serverTimestamp(),


    });



    print("✅ Oyun durumu güncellendi. Sıra geçti.");
  }


  void _listenToGame() {
    gameRef.snapshots().listen((snapshot) {
      if (!snapshot.exists) return;


      final data = snapshot.data() as Map<String, dynamic>;


      final player1 = data['player1'] as Map<String, dynamic>;
      final player2 = data['player2'] as Map<String, dynamic>;

      if (player1['uid'] == widget.currentUser.uid) {
        currentPlayerData = player1;
        opponentPlayerData = player2;
      } else {
        currentPlayerData = player2;
        opponentPlayerData = player1;
      }
      final currentTurnUid = data['currentTurnUid'];
      final isMyTurn = currentTurnUid == widget.currentUser.uid;
      final isNowMyTurn = currentTurnUid == widget.currentUser.uid;
      if (!isNowMyTurn) {
        setState(() {
          lastValidWord = null;
          lastGainedScore = null;
        });
      }

      // Tahta Firestore'dan güncel alınır
      if (data['board'] != null) {
        board = GameBoard.fromMap(data['board']);
      }

      // Elindeki harfler
      playerHand = (currentPlayerData!['hand'] as List)
          .map((e) => Letter.fromMap(e))
          .toList();

      if (mounted) {
        setState(() {
          gameData = data;
          this.isMyTurn = isMyTurn;
        });
      }

    });
  }


  @override
  Widget build(BuildContext context) {
    if (gameData == null || currentPlayerData == null || opponentPlayerData == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final readyPlayers = List<String>.from(gameData!['readyPlayers'] ?? []);
    final isGameReady = readyPlayers.length >= 2;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Oyun Ekranı"),
        backgroundColor: Colors.cyan,
      ),
      body: Column(
        children: [
          // Rakip bilgisi üstte
          Padding(
            padding: const EdgeInsets.all(12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Rakip: ${opponentPlayerData!['username']} | Puan: ${opponentPlayerData!['score'] ?? 0}"
                        "${isMyTurn ? " | Süre: ${remainingSeconds}s" : ""}",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  if (isMyTurn && remainingTime != null)
                    Text(
                      "⏱ Kalan Süre: ${remainingSeconds ~/ 60}:${(remainingSeconds % 60).toString().padLeft(2, '0')}",
                      style: const TextStyle(fontSize: 14, color: Colors.red),
                    ),

                ],
              ),
            ),
          ),


          if (!isGameReady)
            Expanded(
              child: Center(
                child: ElevatedButton(
                  onPressed: () {
                    gameRef.update({
                      'readyPlayers': FieldValue.arrayUnion([widget.currentUser.uid])
                    });
                  },
                  child: const Text("Hazırım"),
                ),
              ),
            )
          else ...[
            Expanded(
              child: GameBoardWidget(
                board: board,
                  onCellTap: (x, y) {
                    if (!isMyTurn) return;

                    final cell = board.getCell(x, y);

                    if (cell.letter != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Bu hücre dolu!')),
                      );
                      return;
                    }

                    if (selectedLetter == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Önce bir harf seçmelisin!')),
                      );
                      return;
                    }

                    setState(() {
                      cell.letter = selectedLetter!.character;
                      cell.isNew = true; // sadece bu client görecek
                      final index = playerHand.indexWhere((l) => l.character == selectedLetter!.character);
                      if (index != -1) {
                        playerHand.removeAt(index);
                      }
                      selectedLetter = null;
                    });
                  }


              ),
            ),
            const SizedBox(height: 10),
            if (lastValidWord != null && lastGainedScore != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '✅ $lastValidWord → +$lastGainedScore puan',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),

            HandWidget(
              hand: playerHand,
              selectedLetter: selectedLetter,
              onLetterTap: (letter) {
                setState(() {
                  selectedLetter = letter;
                  print("Harf seçildi: ${letter.character}");
                });
              },
            ),

            if (isMyTurn) ...[ElevatedButton(
              onPressed: _handleOyunuBitir,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text("🚨 Oyunu Bitir", style: TextStyle(fontSize: 16)),
            ),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: _handleSiraGec,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: const Text("⏭ Sıra Geç", style: TextStyle(fontSize: 16)),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _handleOnayla,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: const Text("✅ Onayla", style: TextStyle(fontSize: 16)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ]


          ],

          // Oyuncu bilgisi altta
          Padding(
            padding: const EdgeInsets.all(12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green),
              ),
              child: Text(
                "Sen: ${currentPlayerData!['username']} | Puan: ${currentPlayerData!['score'] ?? 0}",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}