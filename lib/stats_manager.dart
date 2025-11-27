import 'dart:convert';
import 'dart:io';

class PlayerStats {
  String name;
  int gamesPlayed;
  int wins;
  int losses;

  PlayerStats({
    required this.name,
    this.gamesPlayed = 0,
    this.wins = 0,
    this.losses = 0,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'gamesPlayed': gamesPlayed,
        'wins': wins,
        'losses': losses,
      };

  factory PlayerStats.fromJson(Map<String, dynamic> json) {
    return PlayerStats(
      name: json['name'],
      gamesPlayed: json['gamesPlayed'] ?? 0,
      wins: json['wins'] ?? 0,
      losses: json['losses'] ?? 0,
    );
  }

  @override
  String toString() {
    return 'Stats for $name: Games: $gamesPlayed, Wins: $wins, Losses: $losses';
  }
}

class StatsManager {
  static const String _statsDir = 'stats';

  Future<PlayerStats> loadStats(String playerName) async {
    final file = File('$_statsDir/${playerName}_stats.json');
    if (await file.exists()) {
      try {
        final content = await file.readAsString();
        final json = jsonDecode(content);
        return PlayerStats.fromJson(json);
      } catch (e) {
        print('Error loading stats for $playerName: $e');
      }
    }
    return PlayerStats(name: playerName);
  }

  Future<void> saveStats(PlayerStats stats) async {
    final file = File('$_statsDir/${stats.name}_stats.json');
    try {
      await file.writeAsString(jsonEncode(stats.toJson()));
    } catch (e) {
      print('Error saving stats for ${stats.name}: $e');
    }
  }
}
