import 'dart:math';

enum Orientation { horizontal, vertical }

class Ship {
  final String name;
  final int size;
  List<Point<int>> coordinates = [];
  Set<Point<int>> hits = {};

  Ship(this.name, this.size);

  bool get isSunk => hits.length == size;

  bool occupies(Point<int> p) {
    return coordinates.contains(p);
  }

  bool receiveHit(Point<int> p) {
    if (occupies(p)) {
      hits.add(p);
      return true;
    }
    return false;
  }
}
