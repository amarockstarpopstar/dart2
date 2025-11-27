import 'dart:math';
import 'ship.dart';

class Board {
  final int width;
  final int height;
  final List<Ship> ships = [];
  final Set<Point<int>> shots = {};
  final Set<Point<int>> hits = {};

  Board(this.width, this.height);

  bool placeShip(Ship ship, Point<int> start, Orientation orientation) {
    List<Point<int>> newCoords = [];
    for (int i = 0; i < ship.size; i++) {
      int x = start.x + (orientation == Orientation.horizontal ? i : 0);
      int y = start.y + (orientation == Orientation.vertical ? i : 0);
      
      if (x < 0 || x >= width || y < 0 || y >= height) return false;
      newCoords.add(Point(x, y));
    }

    for (var p in newCoords) {
      if (!_isValidPlacement(p)) return false;
    }

    ship.coordinates = newCoords;
    ships.add(ship);
    return true;
  }

  bool _isValidPlacement(Point<int> p) {
    for (var ship in ships) {
      for (var coord in ship.coordinates) {
        if ((p.x - coord.x).abs() <= 1 && (p.y - coord.y).abs() <= 1) {
          return false;
        }
      }
    }
    return true;
  }

  // Returns true if it was a valid shot (not repeated), result is handled by checking hits
  bool receiveShot(Point<int> p) {
    if (shots.contains(p)) return false; 
    shots.add(p);

    for (var ship in ships) {
      if (ship.receiveHit(p)) {
        hits.add(p);
        return true;
      }
    }
    return false;
  }
  
  bool get allShipsSunk => ships.isNotEmpty && ships.every((s) => s.isSunk);

  List<String> render({required bool showShips}) {
    List<String> lines = [];
    
    // Header
    String header = '   ';
    for (int x = 0; x < width; x++) {
      header += '${x.toString().padLeft(2)} ';
    }
    lines.add(header);

    for (int y = 0; y < height; y++) {
      String line = '${y.toString().padLeft(2)} ';
      for (int x = 0; x < width; x++) {
        var p = Point(x, y);
        String char = '.'; // Empty/Unknown

        bool isShip = false;
        bool isHit = hits.contains(p);
        bool isMiss = shots.contains(p) && !isHit;
        Ship? shipAtCell;

        for (var s in ships) {
          if (s.occupies(p)) {
            isShip = true;
            shipAtCell = s;
            break;
          }
        }

        if (isHit) {
          char = 'X';
          if (shipAtCell != null && shipAtCell.isSunk) {
            char = '#'; // Sunk
          }
        } else if (isMiss) {
          char = 'O';
        } else if (isShip) {
          if (showShips) {
            char = 'S';
          } else {
            char = '.';
          }
        }

        line += ' $char ';
      }
      lines.add(line);
    }
    return lines;
  }
}
