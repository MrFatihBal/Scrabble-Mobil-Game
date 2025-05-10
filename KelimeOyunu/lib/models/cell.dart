class Cell {
  final int x;
  final int y;

  String? letter;
  int scoreMultiplier;
  String multiplierType;
  bool hasTrap;
  String? trapType;
  bool hasReward;
  String? rewardType;
  bool isNew;

  Cell({
    required this.x,
    required this.y,
    this.letter,
    this.scoreMultiplier = 1,
    this.multiplierType = "none",
    this.hasTrap = false,
    this.trapType,
    this.hasReward = false,
    this.rewardType,
    this.isNew=false,
  });
  Map<String, dynamic> toMap() {
    return {
      'x': x,
      'y': y,
      'letter': letter,
      'scoreMultiplier': scoreMultiplier,
      'multiplierType': multiplierType,
      'hasTrap': hasTrap,
      'trapType': trapType,
      'hasReward': hasReward,
      'rewardType': rewardType,
      'isNew': isNew,
    };
  }

  factory Cell.fromMap(Map<String, dynamic> map) {
    return Cell(
      x: map['x'],
      y: map['y'],
      letter: map['letter'],
      scoreMultiplier: map['scoreMultiplier'] ?? 1,
      multiplierType: map['multiplierType'] ?? 'none',
      hasTrap: map['hasTrap'] ?? false,
      trapType: map['trapType'],
      hasReward: map['hasReward'] ?? false,
      rewardType: map['rewardType'],
      isNew: map['isNew'] ?? false,
    );
  }

}
