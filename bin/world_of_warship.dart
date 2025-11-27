import 'package:world_of_warship/game.dart';

Future<void> main(List<String> arguments) async {
  final game = Game();
  await game.start();
}
