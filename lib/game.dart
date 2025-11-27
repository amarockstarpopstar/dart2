import 'dart:io';
import 'dart:async';
import 'player.dart';
import 'stats_manager.dart';
import 'logger.dart';

class Game {
  late Player player1;
  late Player player2;
  int boardSize = 10;
  List<int> shipSizes = [4, 3, 3, 2, 2, 2, 1, 1, 1, 1]; 
  
  final StatsManager _statsManager = StatsManager();
  final GameLogger _logger = GameLogger();

  Future<void> start() async {
    print('Welcome to Sea Battle!');
    await _setupGame();
    await _playGame();
    _logger.dispose();
  }

  Future<void> _setupGame() async {
    // Select Mode
    print('Select Mode:');
    print('1. Player vs Player');
    print('2. Player vs Bot');
    String? mode = stdin.readLineSync();
    bool isPvE = mode == '2';

    // Select Size
    print('Select Field Size:');
    print('1. 10x10 (Standard)');
    print('2. 15x15 (Medium)');
    print('3. 20x20 (Large)');
    String? sizeChoice = stdin.readLineSync();
    
    if (sizeChoice == '2') {
      boardSize = 15;
      shipSizes = [5, 4, 4, 3, 3, 3, 2, 2, 2, 2, 1, 1, 1, 1, 1];
    } else if (sizeChoice == '3') {
      boardSize = 20;
      shipSizes = [6, 5, 5, 4, 4, 4, 3, 3, 3, 3, 2, 2, 2, 2, 2, 1, 1, 1, 1, 1, 1];
    } else {
      boardSize = 10;
      shipSizes = [4, 3, 3, 2, 2, 2, 1, 1, 1, 1];
    }

    // Create Players
    stdout.write('Enter Player 1 Name: ');
    String p1Name = stdin.readLineSync() ?? 'Player 1';
    if (p1Name.isEmpty) p1Name = 'Player 1';
    player1 = HumanPlayer(p1Name, boardSize);

    if (isPvE) {
      player2 = BotPlayer('Bot', boardSize);
    } else {
      stdout.write('Enter Player 2 Name: ');
      String p2Name = stdin.readLineSync() ?? 'Player 2';
      if (p2Name.isEmpty) p2Name = 'Player 2';
      player2 = HumanPlayer(p2Name, boardSize);
    }

    // Load Stats
    print('Loading stats...');
    var p1Stats = await _statsManager.loadStats(player1.name);
    print(p1Stats);
    if (!isPvE) {
      var p2Stats = await _statsManager.loadStats(player2.name);
      print(p2Stats);
    }

    // Placement
    _clearConsole();
    print('${player1.name}, place your ships.');
    player1.placeShips(shipSizes);
    _clearConsole();
    
    if (player2 is HumanPlayer) {
      print('Pass the device to ${player2.name}. Press Enter when ready.');
      stdin.readLineSync();
      print('${player2.name}, place your ships.');
      player2.placeShips(shipSizes);
      _clearConsole();
    } else {
      print('${player2.name} is placing ships...');
      player2.placeShips(shipSizes);
    }
  }

  Future<void> _playGame() async {
    Player current = player1;
    Player opponent = player2;

    // Initial Game State Log
    await _logger.updateGameStateFile(player1, player2);

    while (true) {
      _clearConsole();
      print('Turn: ${current.name}');
      
      if (current is HumanPlayer) {
        print('Opponent Board:');
        print(opponent.board.render(showShips: false).join('\n'));
        print('Your Board:');
        print(current.board.render(showShips: true).join('\n'));
      }

      try {
        var shot = await current.makeMove(opponent.board);
        bool hit = opponent.board.receiveShot(shot);
        
        String result = hit ? 'Hit' : 'Miss';
        _logger.log('${current.name} attacked ${shot.x} ${shot.y}: $result');
        await _logger.updateGameStateFile(player1, player2);

        if (hit) {
          print('Hit!');
          if (opponent.board.allShipsSunk) {
            print('${current.name} wins!');
            _logger.log('${current.name} wins!');
            await _updateStats(current, opponent);
            break;
          }
          print('Shoot again!');
          if (current is HumanPlayer) {
               print('Press Enter to continue...');
               stdin.readLineSync();
          }
          continue; 
        } else {
          print('Miss.');
          if (current is HumanPlayer) {
               print('Press Enter to end turn...');
               stdin.readLineSync();
          }
        }
      } catch (e) {
        // Catch errors from makeMove (like invalid input if we decided to throw, 
        // but currently HumanPlayer handles its own loop. 
        // However, if we throw from makeMove for logging purposes:
        _logger.log('Error during ${current.name} turn: $e');
        print('An error occurred: $e');
        // If it was a critical error, we might break, but for game logic errors we might retry?
        // Since HumanPlayer loops until valid input, this catch block might catch unexpected errors.
      }

      // Swap
      var temp = current;
      current = opponent;
      opponent = temp;
      
      if (current is HumanPlayer) {
         _clearConsole();
         print('Pass the device to ${current.name}. Press Enter when ready.');
         stdin.readLineSync();
      }
    }
  }

  Future<void> _updateStats(Player winner, Player loser) async {
    var wStats = await _statsManager.loadStats(winner.name);
    wStats.gamesPlayed++;
    wStats.wins++;
    await _statsManager.saveStats(wStats);

    if (loser is HumanPlayer) {
      var lStats = await _statsManager.loadStats(loser.name);
      lStats.gamesPlayed++;
      lStats.losses++;
      await _statsManager.saveStats(lStats);
    }
  }

  void _clearConsole() {
    // ANSI escape code to clear screen
    stdout.write('\x1B[2J\x1B[0;0H');
    // Also print newlines for terminals that don't support ANSI
    for(int i=0; i<50; i++) {
      print('');
    } 
  }
}
