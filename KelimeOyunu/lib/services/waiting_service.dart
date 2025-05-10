import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kelimeoyunu/models/game_board.dart';
import 'package:kelimeoyunu/models/tile_bag.dart';
import '../models/user_model.dart';
import 'dart:math';

class WaitingService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;


  static Future<String?> findMatchAndCreateGame(AppUser currentUser,{required String mode}) async {
    final waitingRef = _firestore.collection('waiting_players');

    try {
      // 1. 5dk modunda başka bekleyen var mı?
      final snapshot = await waitingRef
          .where('mode', isEqualTo: mode)
          .where('uid', isNotEqualTo: currentUser.uid)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        // 2. Başka biri bulundu, eşleş!
        final opponentDoc = snapshot.docs.first;
        final opponentData = opponentDoc.data();
        final opponentUID = opponentData['uid'];
        final opponentUsername = opponentData['username'];

        final random = Random();
        final firstTurnUid = random.nextBool() ? currentUser.uid : opponentUID;

        final tileBag = TileBag();
        final tileBagMap=tileBag.toMap();


        final board = GameBoard();
        _placeTrapsAndRewards(board);


// 7 harf çek
        final player1Hand = tileBag.drawMultipleLetters(7);
        final player2Hand = tileBag.drawMultipleLetters(7);

// Harfleri ve tahtayı Firestore’a uygun formata çevir
        final player1HandMap = player1Hand.map((l) => l.toMap()).toList();
        final player2HandMap = player2Hand.map((l) => l.toMap()).toList();
        final boardMap = board.toMap();



        final newGame = await _firestore.collection('games').add({
          'player1': {
            'uid': currentUser.uid,
            'username': currentUser.username,
            'score': 0,
            'hand': player1HandMap,
          },
          'player2': {
            'uid': opponentUID,
            'username': opponentUsername,
            'score': 0,
            'hand': player2HandMap,
          },
          'playerUids': [currentUser.uid, opponentUID],
          'board': boardMap,
          'mode': mode,

          'gameStatus': 'ongoing',
          'readyPlayers': [],
          'currentTurnUid': firstTurnUid,
          'tileBag':tileBagMap,
          'lastMoveAt': FieldValue.serverTimestamp(), // ⏱️ Son hamle zamanı
          'createdAt': FieldValue.serverTimestamp(),

        });


        // 4. İki oyuncuyu waiting listesinden sil
        await waitingRef.doc(currentUser.uid).delete();
        await waitingRef.doc(opponentUID).delete();

        // 5. Oyun ID'sini döndür (istersen)
        return newGame.id;
      } else {
        // 6. Bekleyen bulunamadı, kendimizi waiting_players'a ekle
        await waitingRef.doc(currentUser.uid).set({
          'uid': currentUser.uid,
          'username': currentUser.username,
          'mode': mode,
          'createdAt': FieldValue.serverTimestamp(),
        });

        return null; // Şu anda eşleşmedi, beklemeye devam
      }
    } catch (e) {
      print('Eşleşme hatası: $e');
      return null;
    }
  }
  static void _placeTrapsAndRewards(GameBoard board) {
    final random = Random();

    final traps = [
      ...List.filled(4, 'puan_bol'),
      ...List.filled(3, 'puan_transfer'),
      ...List.filled(3, 'harf_kaybi'),
      ...List.filled(2, 'kat_engeli'),
      ...List.filled(2, 'kelime_iptal'),
    ];

    final rewards = [
      ...List.filled(3, 'harf_bonus'),
      ...List.filled(2, 'kelime_bonus'),
      ...List.filled(1, 'tam_puan'),
    ];

    traps.shuffle();
    rewards.shuffle();

    for (final trap in traps) {
      while (true) {
        int x = random.nextInt(15);
        int y = random.nextInt(15);
        final cell = board.getCell(x, y);
        if (!cell.hasTrap && !cell.hasReward && cell.letter == null) {
          cell.hasTrap = true;
          cell.trapType = trap;
          break;
        }
      }
    }

    for (final reward in rewards) {
      while (true) {
        int x = random.nextInt(15);
        int y = random.nextInt(15);
        final cell = board.getCell(x, y);
        if (!cell.hasTrap && !cell.hasReward && cell.letter == null) {
          cell.hasReward = true;
          cell.rewardType = reward;
          break;
        }
      }
    }
  }


}
