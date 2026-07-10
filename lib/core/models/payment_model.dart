class PaymentRequest {
  final double amount;
  final String currency;
  final PaymentCustomer customer;
  final PaymentBusiness business;

  const PaymentRequest({
    required this.amount,
    this.currency = 'INR',
    required this.customer,
    required this.business,
  });

  Map<String, dynamic> toJson() => {
    'amount': amount,
    'currency': currency,
    'customer': customer.toJson(),
    'business': business.toJson(),
  };
}

class PaymentCustomer {
  final String customerId;
  final String name;
  final String email;
  final String mobile;

  const PaymentCustomer({
    required this.customerId,
    this.name = '',
    this.email = '',
    required this.mobile,
  });

  Map<String, dynamic> toJson() => {
    'customerId': customerId,
    'name': name,
    'email': email,
    'mobile': mobile,
  };
}

class PaymentBusiness {
  final String flowType; // 'DIGITAL_BUY' | 'PHYSICAL_REDEMPTION'
  final String uniqueId;
  final String metalType;
  final double quantity;
  final String lockPrice;
  final String? blockId;
  final String? sku;
  final String? addressId;

  const PaymentBusiness({
    required this.flowType,
    required this.uniqueId,
    required this.metalType,
    required this.quantity,
    required this.lockPrice,
    this.blockId,
    this.sku,
    this.addressId,
  });

  Map<String, dynamic> toJson() => {
    'flowType': flowType,
    'uniqueId': uniqueId,
    'metalType': metalType,
    'quantity': quantity.toString(),
    'lockPrice': lockPrice,
    if (blockId != null) 'blockId': blockId,
    if (sku != null) 'sku': sku,
    if (addressId != null) 'addressId': addressId,
  };
}

class PaymentResponse {
  final String sabbpeOrderId;
  final String merchantOrderId;
  final String paymentSessionId;
  final String orderStatus;
  final String paymentStatus;
  final String paymentMethod;
  final String action;
  final String channel;
  final String paymentUrl;
  final String? qrCode;
  final String cfPaymentId;
  final PaymentActionData? actionData;
  final String message;

  const PaymentResponse({
    this.sabbpeOrderId = '',
    this.merchantOrderId = '',
    this.paymentSessionId = '',
    this.orderStatus = '',
    this.paymentStatus = '',
    this.paymentMethod = '',
    this.action = '',
    this.channel = '',
    this.paymentUrl = '',
    this.qrCode,
    this.cfPaymentId = '',
    this.actionData,
    this.message = '',
  });

  factory PaymentResponse.fromJson(Map<String, dynamic> json) {
    return PaymentResponse(
      sabbpeOrderId: json['sabbpeOrderId']?.toString() ?? '',
      merchantOrderId: json['merchantOrderId']?.toString() ?? '',
      paymentSessionId: json['paymentSessionId']?.toString() ?? '',
      orderStatus: json['orderStatus']?.toString() ?? '',
      paymentStatus: json['paymentStatus']?.toString() ?? '',
      paymentMethod: json['paymentMethod']?.toString() ?? '',
      action: json['action']?.toString() ?? '',
      channel: json['channel']?.toString() ?? '',
      paymentUrl: json['paymentUrl']?.toString() ?? '',
      qrCode: json['qrCode']?.toString(),
      cfPaymentId: json['cfPaymentId']?.toString() ?? '',
      actionData: json['actionData'] != null
          ? PaymentActionData.fromJson(json['actionData'] as Map<String, dynamic>)
          : null,
      message: json['message']?.toString() ?? '',
    );
  }
}

class PaymentActionData {
  final String? url;
  final String? payload;
  final String? method;

  const PaymentActionData({this.url, this.payload, this.method});

  factory PaymentActionData.fromJson(Map<String, dynamic> json) {
    return PaymentActionData(
      url: json['url']?.toString(),
      payload: json['payload']?.toString(),
      method: json['method']?.toString(),
    );
  }
}

class PaymentStatusResponse {
  final String sabbpeOrderId;
  final String merchantOrderId;
  final String orderStatus;
  final String paymentStatus;
  final String message;

  const PaymentStatusResponse({
    this.sabbpeOrderId = '',
    this.merchantOrderId = '',
    this.orderStatus = '',
    this.paymentStatus = '',
    this.message = '',
  });

  factory PaymentStatusResponse.fromJson(Map<String, dynamic> json) {
    return PaymentStatusResponse(
      sabbpeOrderId: json['sabbpeOrderId']?.toString() ?? '',
      merchantOrderId: json['merchantOrderId']?.toString() ?? '',
      orderStatus: json['orderStatus']?.toString() ?? '',
      paymentStatus: json['paymentStatus']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
    );
  }
}

class PaymentMethod {
  final String type;
  final String name;
  final bool enabled;
  final List<PaymentBank> banks;

  const PaymentMethod({
    this.type = '',
    this.name = '',
    this.enabled = true,
    this.banks = const [],
  });

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      type: json['type']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      enabled: json['enabled'] != false,
      banks: (json['banks'] as List<dynamic>?)
              ?.map((e) => PaymentBank.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class PaymentBank {
  final String code;
  final String name;

  const PaymentBank({this.code = '', this.name = ''});

  factory PaymentBank.fromJson(Map<String, dynamic> json) {
    return PaymentBank(
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
    );
  }
}
