import 'dart:async';
import 'dart:io';
import 'player.dart';

class GameLogger {
  static const String _logDir = 'logs';
  static const String _gameStateFile = 'game_state.txt';
  static const String _logFile = '$_logDir/game_log.txt';
  
  final StreamController<String> _logController = StreamController<String>();
  late StreamSubscription _subscription;

  GameLogger() {
    _subscription = _logController.stream.listen((message) {
      _writeToFile(message);
    });
    _clearLogFile();
  }

  void log(String message) {
    _logController.add('${DateTime.now()}: $message');
  }

  void dispose() {
    _subscription.cancel();
    _logController.close();
    _clearGameStateFile();
  }

  Future<void> _writeToFile(String message) async {
    final file = File(_logFile);
    await file.writeAsString('$message\n', mode: FileMode.append);
  }

  Future<void> _clearLogFile() async {
    final file = File(_logFile);
    if (await file.exists()) {
      await file.writeAsString('');
    }
  }

  Future<void> _clearGameStateFile() async {
    final file = File(_gameStateFile);
    if (await file.exists()) {
      await file.writeAsString(''); // Or await file.delete();
    }
  }

  Future<void> updateGameStateFile(Player p1, Player p2) async {
    final file = File(_gameStateFile);
    String content = '${_generatePlayerState(p1)}\n${_generatePlayerState(p2)}';
    await file.writeAsString(content);
  }

  String _generatePlayerState(Player p) {
    // int hits = p.board.hits.length; // Hits received by this player (opponent's hits)
    // Wait, the requirement says: "Player1: 5 hits, 5 misses..."
    // Usually "Player1 hits" means hits Player1 MADE.
    // But "3 ships intact" refers to Player1's ships.
    // Let's assume it describes the Player's status and performance.
    
    // Let's count hits/misses MADE by the player.
    // But the Board class stores shots received.
    // We need to look at the OPPONENT'S board to see what this player did.
    // However, the prompt says "Player1 ... 3 ships intact". That's Player1's board.
    // "5 hits, 5 misses" could be shots received OR shots made.
    // Given "3 ships intact", it's likely "Status of Player1".
    // So "5 hits" = 5 times Player1 was hit.
    
    // Actually, "Player1: 5 hits, 5 misses" usually implies score.
    // Let's stick to:
    // Hits/Misses: Shots MADE by Player1 (we need to track this or infer from opponent board).
    // Ships intact: Player1's ships.
    
    // Since we don't easily have "Shots made by P1" without looking at P2's board,
    // let's pass both players to the update method and handle it there.
    // But here we only have `p`.
    
    // Let's change the logic. We will calculate "Shots Received" and "Ships Intact" for `p`.
    // If we want "Shots Made", we need the other player.
    // Let's just report on the board state of `p`.
    // "Player1: Received 5 hits, 3 ships intact..."
    
    int shipsIntact = p.board.ships.where((s) => !s.isSunk).length;
    int shipsSunk = p.board.ships.where((s) => s.isSunk).length;
    int shipsDamaged = p.board.ships.where((s) => s.hits.isNotEmpty && !s.isSunk).length;
    
    // To strictly follow "5 hits, 5 misses", let's assume it means shots made by the player.
    // But we can't easily get that from just `p`.
    // Let's stick to Board state:
    // Hits on this board (Opponent's success)
    // Misses on this board (Opponent's failure)
    
    int hitsOnMe = p.board.hits.length;
    int missesOnMe = p.board.shots.length - hitsOnMe;

    return '${p.name}: $hitsOnMe hits received, $missesOnMe misses received, $shipsIntact ships intact, $shipsDamaged damaged, $shipsSunk sunk.';
  }
  
  // Overloaded method to include shots made if we want to be more precise
  Future<void> updateGameStateFull(Player p1, Player p2) async {
     final file = File(_gameStateFile);
     String c1 = _getPlayerPerformance(p1, p2); // p1 stats vs p2 board
     String c2 = _getPlayerPerformance(p2, p1); // p2 stats vs p1 board
     await file.writeAsString('$c1\n$c2');
  }

  String _getPlayerPerformance(Player me, Player opponent) {
      // Hits/Misses made by ME (on opponent board)
      int myHits = opponent.board.hits.length;
      int myMisses = opponent.board.shots.length - myHits;
      
      // My Ships status
      int shipsIntact = me.board.ships.where((s) => !s.isSunk && s.hits.isEmpty).length;
      int shipsSunk = me.board.ships.where((s) => s.isSunk).length;
      int shipsDamaged = me.board.ships.where((s) => s.hits.isNotEmpty && !s.isSunk).length;

      return '${me.name}: $myHits hits made, $myMisses misses made, $shipsIntact ships intact, $shipsDamaged damaged, $shipsSunk sunk.';
  }
}
