class DiamondProduct {
  final String productId;
  final String stockId;
  final String shape;
  final double carat;
  final String color;
  final String clarity;
  final String cut;
  final String polish;
  final String symmetry;
  final String fluorescence;
  final String certificate;
  final String certNumber;
  final double finalPrice;
  final double pricePerCarat;
  final String currencyCode;
  final double length;
  final double width;
  final double height;
  final double table;
  final double depth;
  final String girdle;
  final String culet;
  final bool eyeClean;
  final String shade;
  final String luster;
  final bool hasImage;
  final bool hasVideo;
  final bool hasBuyback;
  final String treatment;
  final String fancyColor;
  final String fancyColorIntensity;
  final String fancyColorOvertone;
  final String imageUrl;
  final String diamondImage;
  final String videoUrl;

  const DiamondProduct({
    this.productId = '',
    this.stockId = '',
    this.shape = '',
    this.carat = 0,
    this.color = '',
    this.clarity = '',
    this.cut = '',
    this.polish = '',
    this.symmetry = '',
    this.fluorescence = '',
    this.certificate = '',
    this.certNumber = '',
    this.finalPrice = 0,
    this.pricePerCarat = 0,
    this.currencyCode = '',
    this.length = 0,
    this.width = 0,
    this.height = 0,
    this.table = 0,
    this.depth = 0,
    this.girdle = '',
    this.culet = '',
    this.eyeClean = false,
    this.shade = '',
    this.luster = '',
    this.hasImage = false,
    this.hasVideo = false,
    this.hasBuyback = false,
    this.treatment = '',
    this.fancyColor = '',
    this.fancyColorIntensity = '',
    this.fancyColorOvertone = '',
    this.imageUrl = '',
    this.diamondImage = '',
    this.videoUrl = '',
  });

  factory DiamondProduct.fromJson(Map<String, dynamic> json) {
    // Parse measurements string like "8.94 - 5.35 * 3.42"
    double parseLen = 0, parseW = 0, parseH = 0;
    final measurements = json['measurements']?.toString() ?? '';
    if (measurements.isNotEmpty) {
      final parts = measurements.split(RegExp(r'[\s*xX*×]+')).where((s) => s.trim().isNotEmpty).toList();
      if (parts.length >= 3) {
        parseLen = double.tryParse(parts[0].trim()) ?? 0;
        parseW = double.tryParse(parts[1].trim()) ?? 0;
        parseH = double.tryParse(parts[2].trim()) ?? 0;
      } else if (parts.length == 2) {
        parseLen = double.tryParse(parts[0].trim()) ?? 0;
        parseW = double.tryParse(parts[1].trim()) ?? 0;
      }
    }

    final diamondImageUrl = json['diamondImage']?.toString() ?? '';
    final diamondVideoUrl = json['diamondVideo']?.toString() ?? '';
    final apiImageUrl = json['imageUrl']?.toString() ?? '';
    final apiVideoUrl = json['videoUrl']?.toString() ?? '';

    final resolvedImageUrl = apiImageUrl.isNotEmpty ? apiImageUrl : diamondImageUrl;
    final resolvedVideoUrl = apiVideoUrl.isNotEmpty ? apiVideoUrl : diamondVideoUrl;

    return DiamondProduct(
      productId: _str(json, 'productId', 'product_id', 'id', '_id', 'stockId', 'stock_id', 'sku', 'stockNum'),
      stockId: json['stockId']?.toString() ?? json['stock_id']?.toString() ?? json['stockNum']?.toString() ?? '',
      shape: json['shape']?.toString() ?? '',
      carat: _toDouble(json['carat']) != 0 ? _toDouble(json['carat']) : _toDouble(json['weight']),
      color: json['color']?.toString() ?? '',
      clarity: json['clarity']?.toString() ?? '',
      cut: json['cut']?.toString() ?? '',
      polish: json['polish']?.toString() ?? '',
      symmetry: json['symmetry']?.toString() ?? '',
      fluorescence: _str(json, 'fluorescence', 'fluorescenceIntensity'),
      certificate: _str(json, 'certificate', 'lab'),
      certNumber: _str(json, 'certNumber', 'certNumberUrl', 'certificateNumber'),
      finalPrice: _toDouble(json['finalPrice']) != 0 ? _toDouble(json['finalPrice']) : _toDouble(json['price']),
      pricePerCarat: _toDouble(json['pricePerCarat']),
      currencyCode: json['currencyCode']?.toString() ?? '',
      length: _toDouble(json['length']) != 0 ? _toDouble(json['length']) : parseLen,
      width: _toDouble(json['width']) != 0 ? _toDouble(json['width']) : parseW,
      height: _toDouble(json['height']) != 0 ? _toDouble(json['height']) : parseH,
      table: _toDouble(json['table']) != 0 ? _toDouble(json['table']) : _toDouble(json['tablePercentage']),
      depth: _toDouble(json['depth']) != 0 ? _toDouble(json['depth']) : _toDouble(json['depthPercentage']),
      girdle: _str(json, 'girdle', 'girdleCondition'),
      culet: _str(json, 'culet', 'culetCondition'),
      eyeClean: json['eyeClean'] == true,
      shade: json['shade']?.toString() ?? '',
      luster: _str(json, 'luster', 'milky'),
      hasImage: resolvedImageUrl.isNotEmpty,
      hasVideo: resolvedVideoUrl.isNotEmpty,
      hasBuyback: json['hasBuyback'] == true,
      treatment: json['treatment']?.toString() ?? '',
      fancyColor: json['fancyColor']?.toString() ?? '',
      fancyColorIntensity: json['fancyColorIntensity']?.toString() ?? '',
      fancyColorOvertone: json['fancyColorOvertone']?.toString() ?? '',
      imageUrl: resolvedImageUrl,
      diamondImage: diamondImageUrl,
      videoUrl: resolvedVideoUrl,
    );
  }

  static String _str(Map<String, dynamic> json, [String? k1, String? k2, String? k3, String? k4, String? k5, String? k6, String? k7, String? k8]) {
    final keys = [k1, k2, k3, k4, k5, k6, k7, k8].whereType<String>();
    for (final key in keys) {
      final val = json[key]?.toString() ?? '';
      if (val.isNotEmpty && val.toLowerCase() != 'none') return val;
    }
    return '';
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    return double.tryParse(value.toString()) ?? 0;
  }
}

class DiamondCartItem {
  final String id;
  final String productId;
  final String productName;
  final String imageUrl;
  final double unitPrice;
  final double lineTotal;
  final int quantity;
  final String currencyCode;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DiamondProduct? product;

  const DiamondCartItem({
    this.id = '',
    this.productId = '',
    this.productName = '',
    this.imageUrl = '',
    this.unitPrice = 0,
    this.lineTotal = 0,
    this.quantity = 0,
    this.currencyCode = '',
    this.createdAt,
    this.updatedAt,
    this.product,
  });

  factory DiamondCartItem.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      try {
        return DateTime.parse(v.toString());
      } catch (_) {
        return null;
      }
    }

    return DiamondCartItem(
      id: json['id']?.toString() ?? '',
      productId: json['productId']?.toString() ?? '',
      productName: json['productName']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString() ?? '',
      unitPrice: double.tryParse(json['unitPrice']?.toString() ?? '') ?? 0,
      lineTotal: double.tryParse(json['lineTotal']?.toString() ?? '') ?? 0,
      quantity: json['quantity'] as int? ?? 1,
      currencyCode: json['currencyCode']?.toString() ?? '',
      createdAt: parseDate(json['createdAt'] ?? json['created_at'] ?? json['addedAt']),
      updatedAt: parseDate(json['updatedAt']),
      product: json['product'] != null
          ? DiamondProduct.fromJson(json['product'] as Map<String, dynamic>)
          : null,
    );
  }
}

class DiamondOrder {
  final String lockId;
  final String productId;
  final String lockStatus;
  final String lockedAt;
  final String expiresAt;
  final String orderId;
  final String orderReference;
  final String merchantTransactionId;
  final String orderStatus;
  final double totalAmount;
  final String createdAt;
  final String updatedAt;
  final String paymentStatus;

  const DiamondOrder({
    this.lockId = '',
    this.productId = '',
    this.lockStatus = '',
    this.lockedAt = '',
    this.expiresAt = '',
    this.orderId = '',
    this.orderReference = '',
    this.merchantTransactionId = '',
    this.orderStatus = '',
    this.totalAmount = 0,
    this.createdAt = '',
    this.updatedAt = '',
    this.paymentStatus = '',
  });

  factory DiamondOrder.fromJson(Map<String, dynamic> json) {
    return DiamondOrder(
      lockId: json['lockId']?.toString() ?? '',
      productId: json['productId']?.toString() ?? '',
      lockStatus: json['lockStatus']?.toString() ?? '',
      lockedAt: json['lockedAt']?.toString() ?? '',
      expiresAt: json['expiresAt']?.toString() ?? '',
      orderId: json['orderId']?.toString() ?? '',
      orderReference: json['orderReference']?.toString() ?? '',
      merchantTransactionId: json['merchantTransactionId']?.toString() ?? '',
      orderStatus: json['orderStatus']?.toString() ?? '',
      totalAmount: double.tryParse(json['totalAmount'].toString()) ?? 0,
      createdAt: json['createdAt']?.toString() ?? '',
      updatedAt: json['updatedAt']?.toString() ?? '',
      paymentStatus: json['paymentStatus']?.toString() ?? '',
    );
  }
}

class DiamondPaymentResponse {
  final String merchantOrderRef;
  final String paymentUrl;
  final String message;

  const DiamondPaymentResponse({
    this.merchantOrderRef = '',
    this.paymentUrl = '',
    this.message = '',
  });

  factory DiamondPaymentResponse.fromJson(Map<String, dynamic> json) {
    return DiamondPaymentResponse(
      merchantOrderRef: json['merchant_order_ref']?.toString() ?? '',
      paymentUrl: json['payment_url']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
    );
  }
}
