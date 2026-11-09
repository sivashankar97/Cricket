import 'package:data/api/auction/auction_models.dart';
import 'package:data/api/tournament_team/tournament_team_model.dart';

/// Parses pasted player lines: `Name, Player ID, Number, Role, Base price`.
/// Only the name is required; blank lines are ignored.
List<AuctionPlayer> parsePlayerLines(
  String text, {
  required int defaultBasePrice,
  required String Function() newId,
}) {
  final players = <AuctionPlayer>[];
  for (final line in text.split('\n')) {
    final parts = line.split(RegExp(r'[,\t]')).map((p) => p.trim()).toList();
    if (parts.isEmpty || parts.first.isEmpty) continue;
    String? at(int i) => i < parts.length && parts[i].isNotEmpty ? parts[i] : null;
    players.add(AuctionPlayer(
      id: newId(),
      name: parts.first,
      code: at(1),
      number: int.tryParse(at(2) ?? ''),
      role: parseRole(at(3)),
      basePrice: int.tryParse(at(4) ?? '') ?? defaultBasePrice,
    ),);
  }
  return players;
}

TournamentPlayerRole? parseRole(String? raw) {
  final value = raw?.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '') ?? '';
  if (value.isEmpty) return null;
  if (value.startsWith('wk') || value.startsWith('wicket') || value == 'keeper') {
    return TournamentPlayerRole.wicketKeeper;
  }
  if (value.startsWith('all') || value == 'ar') {
    return TournamentPlayerRole.allRounder;
  }
  if (value.startsWith('bowl')) return TournamentPlayerRole.bowler;
  if (value.startsWith('bat')) return TournamentPlayerRole.batsman;
  return null;
}

String _normalize(String value) =>
    value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

/// File name without extension, e.g. "P001 - Arun Kumar.jpg" → "P001 - Arun Kumar".
String fileStem(String fileName) {
  final base = fileName.split(RegExp(r'[\\/]')).last;
  final dot = base.lastIndexOf('.');
  return (dot > 0 ? base.substring(0, dot) : base).trim();
}

/// Finds the player a photo belongs to by its file name: player ID first,
/// then number, then name. A file name may combine them, e.g. "P001_Arun".
AuctionPlayer? matchPhotoToPlayer(String fileName, List<AuctionPlayer> players) {
  final stem = fileStem(fileName);
  final pieces = {
    stem,
    ...stem.split(RegExp(r'\s*[-_]\s*|\s{2,}')),
  }.map((p) => p.trim()).where((p) => p.isNotEmpty).toList();

  for (final piece in pieces) {
    final code = _normalize(piece);
    final byCode = players.where(
      (p) => p.code != null && p.code!.isNotEmpty && _normalize(p.code!) == code,
    );
    if (byCode.length == 1) return byCode.first;
  }
  for (final piece in pieces) {
    final number = int.tryParse(piece.replaceAll('#', ''));
    if (number == null) continue;
    final byNumber = players.where((p) => p.number == number);
    if (byNumber.length == 1) return byNumber.first;
  }
  for (final piece in pieces) {
    final name = _normalize(piece);
    if (name.isEmpty) continue;
    final byName = players.where((p) => _normalize(p.name) == name);
    if (byName.length == 1) return byName.first;
  }
  return null;
}
