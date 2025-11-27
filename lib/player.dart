import 'dart:math';
import 'dart:io';
import 'dart:async';
import 'dart:isolate';
import 'board.dart';
import 'ship.dart';

abstract class Player {
  String name;
  final Board board;

  Player(this.name, int boardSize) : board = Board(boardSize, boardSize);

  Future<Point<int>> makeMove(Board opponentBoard);
  void placeShips(List<int> shipSizes);
}

class HumanPlayer extends Player {
  HumanPlayer(super.name, super.boardSize);

  @override
  Future<Point<int>> makeMove(Board opponentBoard) async {
    while (true) {
      stdout.write('$name, enter coordinates to attack (x y): ');
      String? input = stdin.readLineSync();
      if (input == null) continue;
      
      var parts = input.trim().split(RegExp(r'\s+'));
      if (parts.length != 2) {
        print('Invalid input. Please enter x and y coordinates separated by space.');
        continue;
      }

      try {
        int x = int.parse(parts[0]);
        int y = int.parse(parts[1]);
        var p = Point(x, y);

        if (x < 0 || x >= opponentBoard.width || y < 0 || y >= opponentBoard.height) {
          throw FormatException('Coordinates out of bounds.');
        }
        
        if (opponentBoard.shots.contains(p)) {
          throw FormatException('You already shot there.');
        }

        return p;
      } on FormatException catch (e) {
        print('Error: ${e.message}');
        // Rethrow to allow logging in Game loop if needed, but we need to stay in loop?
        // If we throw, we exit makeMove.
        // The requirement is to log the error.
        // We can return a special value or throw.
        // If we throw, the Game loop must catch and call makeMove again.
        rethrow;
      } catch (e) {
        print('Invalid numbers.');
        throw FormatException('Invalid numbers');
      }
    }
  }

  @override
  void placeShips(List<int> shipSizes) {
    // For each ship size, ask user for coordinates and orientation
    for (int size in shipSizes) {
      bool placed = false;
      while (!placed) {
        print('\nYour Board:');
        print(board.render(showShips: true).join('\n'));
        stdout.write('$name, place ship of size $size (format: x y h/v): ');
        String? input = stdin.readLineSync();
        if (input == null) continue;

        var parts = input.trim().split(RegExp(r'\s+'));
        if (parts.length != 3) {
          print('Invalid input. You must provide x, y, and orientation. Example: 4 2 h');
          continue;
        }

        try {
          int x = int.parse(parts[0]);
          int y = int.parse(parts[1]);
          String oStr = parts[2].toLowerCase();
          Orientation o;
          if (oStr.startsWith('h')) {
            o = Orientation.horizontal;
          } else if (oStr.startsWith('v')) {
            o = Orientation.vertical;
          } else {
            print('Invalid orientation. Use h or v.');
            continue;
          }

          var ship = Ship('Ship $size', size);
          if (board.placeShip(ship, Point(x, y), o)) {
            placed = true;
            print('Ship placed.');
          } else {
            print('Invalid placement. Check bounds and spacing (ships cannot touch).');
          }
        } catch (e) {
          print('Invalid input.');
        }
      }
    }
  }
}

class BotPlayer extends Player {
  final Random _rng = Random();

  BotPlayer(super.name, super.boardSize);

  @override
  Future<Point<int>> makeMove(Board opponentBoard) async {
    // Use Isolate to calculate move
    final shots = opponentBoard.shots.toList();
    final width = opponentBoard.width;
    final height = opponentBoard.height;

    return await Isolate.run(() {
      final rng = Random();
      while (true) {
        int x = rng.nextInt(width);
        int y = rng.nextInt(height);
        var p = Point(x, y);
        if (!shots.contains(p)) {
          return p;
        }
      }
    });
  }

  @override
  void placeShips(List<int> shipSizes) {
    for (int size in shipSizes) {
      bool placed = false;
      while (!placed) {
        int x = _rng.nextInt(board.width);
        int y = _rng.nextInt(board.height);
        Orientation o = _rng.nextBool() ? Orientation.horizontal : Orientation.vertical;
        
        var ship = Ship('BotShip $size', size);
        if (board.placeShip(ship, Point(x, y), o)) {
          placed = true;
        }
      }
    }
    print('$name has placed ships.');
  }
}
