class SavedLotteryTicket {
  const SavedLotteryTicket({
    required this.id,
    required this.gameCode,
    required this.whiteNumbers,
    required this.specialNumber,
    required this.savedAt,
    this.label,
  });

  final String id;
  final String gameCode;
  final List<String> whiteNumbers;
  final String specialNumber;
  final DateTime savedAt;
  final String? label;

  String get gameName =>
      gameCode == 'mega-millions' ? 'Mega Millions' : 'Powerball';

  Map<String, dynamic> toJson() => {
    'id': id,
    'gameCode': gameCode,
    'whiteNumbers': whiteNumbers,
    'specialNumber': specialNumber,
    'savedAt': savedAt.toIso8601String(),
    'label': label,
  };

  SavedLotteryTicket copyWith({String? label}) => SavedLotteryTicket(
    id: id,
    gameCode: gameCode,
    whiteNumbers: whiteNumbers,
    specialNumber: specialNumber,
    savedAt: savedAt,
    label: label,
  );

  factory SavedLotteryTicket.fromJson(Map<String, dynamic> json) =>
      SavedLotteryTicket(
        id: json['id'] as String? ?? '',
        gameCode: json['gameCode'] as String? ?? 'powerball',
        whiteNumbers: (json['whiteNumbers'] as List<dynamic>? ?? const [])
            .map((value) => value.toString())
            .toList(),
        specialNumber: json['specialNumber']?.toString() ?? '',
        savedAt:
            DateTime.tryParse(json['savedAt'] as String? ?? '') ??
            DateTime.now(),
        label: (json['label'] as String?)?.trim().isEmpty ?? true
            ? null
            : (json['label'] as String).trim(),
      );
}
