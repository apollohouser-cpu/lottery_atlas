/// A current North Carolina Education Lottery Scratch-Off ticket.
///
/// This catalog represents the Lottery's remaining-prizes inventory. It is
/// intentionally separate from location-bearing winner claims used to paint
/// the map: inventory tells us which tickets are active, but not where a
/// particular winning ticket was sold.
class NorthCarolinaScratchGame {
  const NorthCarolinaScratchGame({
    required this.id,
    required this.name,
    required this.topPrize,
    required this.topPrizesRemaining,
  });

  final String id;
  final String name;
  final int topPrize;
  final int topPrizesRemaining;
}
