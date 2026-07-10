class GoldRate {
  final double currentPrice;
  final double buyPrice;
  final double sellPrice;
  final String blockId;
  final String metalType;
  final String updatedAt;
  final GoldRateMeta gold;
  final GoldRateMeta silver;

  const GoldRate({
    this.currentPrice = 0,
    this.buyPrice = 0,
    this.sellPrice = 0,
    this.blockId = '',
    this.metalType = 'gold',
    this.updatedAt = '',
    this.gold = const GoldRateMeta(),
    this.silver = const GoldRateMeta(),
  });

  factory GoldRate.fromJson(Map<String, dynamic> json) {
    return GoldRate(
      currentPrice: _toDouble(json['currentPrice']),
      buyPrice: _toDouble(json['buyPrice']),
      sellPrice: _toDouble(json['sellPrice']),
      blockId: json['blockId']?.toString() ?? '',
      metalType: json['metalType']?.toString() ?? 'gold',
      updatedAt: json['updatedAt']?.toString() ?? '',
      gold: GoldRateMeta.fromJson(json['gold'] as Map<String, dynamic>? ?? {}),
      silver: GoldRateMeta.fromJson(json['silver'] as Map<String, dynamic>? ?? {}),
    );
  }

  Map<String, dynamic> toJson() => {
    'currentPrice': currentPrice,
    'buyPrice': buyPrice,
    'sellPrice': sellPrice,
    'blockId': blockId,
    'metalType': metalType,
    'updatedAt': updatedAt,
  };

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    return double.tryParse(value.toString()) ?? 0;
  }
}

class GoldRateMeta {
  final double currentPrice;
  final double buyPrice;
  final double sellPrice;

  const GoldRateMeta({
    this.currentPrice = 0,
    this.buyPrice = 0,
    this.sellPrice = 0,
  });

  factory GoldRateMeta.fromJson(Map<String, dynamic> json) {
    return GoldRateMeta(
      currentPrice: GoldRate._toDouble(json['currentPrice']),
      buyPrice: GoldRate._toDouble(json['buyPrice']),
      sellPrice: GoldRate._toDouble(json['sellPrice']),
    );
  }
}

class RateHistoryPoint {
  final String date;
  final String metalType;
  final double buyRate;
  final double sellRate;
  final String label;
  final double price;
  final String updatedAt;
  final RateReturns returns;

  const RateHistoryPoint({
    this.date = '',
    this.metalType = 'gold',
    this.buyRate = 0,
    this.sellRate = 0,
    this.label = '',
    this.price = 0,
    this.updatedAt = '',
    this.returns = const RateReturns(),
  });

  factory RateHistoryPoint.fromJson(Map<String, dynamic> json) {
    return RateHistoryPoint(
      date: json['date']?.toString() ?? '',
      metalType: json['metalType']?.toString() ?? 'gold',
      buyRate: GoldRate._toDouble(json['buyRate']),
      sellRate: GoldRate._toDouble(json['sellRate']),
      label: json['label']?.toString() ?? '',
      price: GoldRate._toDouble(json['price']),
      updatedAt: json['updatedAt']?.toString() ?? '',
      returns: RateReturns.fromJson(json['returns'] as Map<String, dynamic>? ?? {}),
    );
  }
}

class RateReturns {
  final double? oneDay;
  final double? oneWeek;
  final double? oneMonth;
  final double? threeMonth;
  final double? sixMonth;
  final double? oneYear;
  final double? twoYear;
  final double? threeYear;

  const RateReturns({
    this.oneDay,
    this.oneWeek,
    this.oneMonth,
    this.threeMonth,
    this.sixMonth,
    this.oneYear,
    this.twoYear,
    this.threeYear,
  });

  factory RateReturns.fromJson(Map<String, dynamic> json) {
    return RateReturns(
      oneDay: _toDoubleNullable(json['oneDayReturn']),
      oneWeek: _toDoubleNullable(json['oneWeekReturn']),
      oneMonth: _toDoubleNullable(json['oneMonthReturn']),
      threeMonth: _toDoubleNullable(json['threeMonthReturn']),
      sixMonth: _toDoubleNullable(json['sixMonthReturn']),
      oneYear: _toDoubleNullable(json['oneYearReturn']),
      twoYear: _toDoubleNullable(json['twoYearReturn']),
      threeYear: _toDoubleNullable(json['threeYearReturn']),
    );
  }

  static double? _toDoubleNullable(dynamic value) {
    if (value == null) return null;
    return double.tryParse(value.toString());
  }
}

class SipRateSnapshot {
  final GoldRateMeta gold;
  final GoldRateMeta silver;
  final String updatedAt;

  const SipRateSnapshot({
    this.gold = const GoldRateMeta(),
    this.silver = const GoldRateMeta(),
    this.updatedAt = '',
  });

  factory SipRateSnapshot.fromJson(Map<String, dynamic> json) {
    return SipRateSnapshot(
      gold: GoldRateMeta.fromJson(json['gold'] as Map<String, dynamic>? ?? {}),
      silver: GoldRateMeta.fromJson(json['silver'] as Map<String, dynamic>? ?? {}),
      updatedAt: json['updatedAt']?.toString() ?? '',
    );
  }
}

class RateHistoryPointInMemory {
  final String label;
  final double price;
  final String updatedAt;

  const RateHistoryPointInMemory({
    this.label = '',
    this.price = 0,
    this.updatedAt = '',
  });

  factory RateHistoryPointInMemory.fromJson(Map<String, dynamic> json) {
    return RateHistoryPointInMemory(
      label: json['label']?.toString() ?? '',
      price: GoldRate._toDouble(json['price']),
      updatedAt: json['updatedAt']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'label': label,
    'price': price,
    'updatedAt': updatedAt,
  };
}
