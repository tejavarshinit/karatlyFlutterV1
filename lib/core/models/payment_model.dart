import '../utils/money.dart';

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
    'amount': MoneyHelper.truncateMoney(amount),
    'currency': currency,
    'customer': customer.toJson(),
    'business': business.toJson(),
  };

  factory PaymentRequest.fromJson(Map<String, dynamic> json) {
    return PaymentRequest(
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      currency: json['currency']?.toString() ?? 'INR',
      customer: PaymentCustomer.fromJson((json['customer'] as Map?)?.cast<String, dynamic>() ?? const {}),
      business: PaymentBusiness.fromJson((json['business'] as Map?)?.cast<String, dynamic>() ?? const {}),
    );
  }
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

  factory PaymentCustomer.fromJson(Map<String, dynamic> json) {
    return PaymentCustomer(
      customerId: json['customerId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      mobile: json['mobile']?.toString() ?? '',
    );
  }
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
  final String? couponCode;
  final double? couponSubtotal;
  final double? couponFee;
  final String? employeeId;
  final String? corporateId;

  const PaymentBusiness({
    required this.flowType,
    required this.uniqueId,
    required this.metalType,
    required this.quantity,
    required this.lockPrice,
    this.blockId,
    this.sku,
    this.addressId,
    this.couponCode,
    this.couponSubtotal,
    this.couponFee,
    this.employeeId,
    this.corporateId,
  });

  Map<String, dynamic> toJson() => {
    'flowType': flowType,
    'uniqueId': uniqueId,
    'metalType': metalType,
    'quantity': flowType == 'DIGITAL_BUY'
        ? quantity.toStringAsFixed(4)
        : quantity.toString(),
    'lockPrice': lockPrice,
    'blockId': blockId ?? '',
    if (sku != null && sku!.isNotEmpty) 'sku': sku,
    if (addressId != null && addressId!.isNotEmpty) 'addressId': addressId,
    if (couponCode != null && couponCode!.isNotEmpty) 'couponCode': couponCode,
    if (couponSubtotal != null && couponSubtotal! > 0) 'couponSubtotal': couponSubtotal,
    if (couponFee != null && couponFee! > 0) 'couponFee': couponFee,
    if (employeeId != null && employeeId!.isNotEmpty) 'employeeId': employeeId,
    if (corporateId != null && corporateId!.isNotEmpty) 'corporateId': corporateId,
  };

  factory PaymentBusiness.fromJson(Map<String, dynamic> json) {
    return PaymentBusiness(
      flowType: json['flowType']?.toString() ?? 'DIGITAL_BUY',
      uniqueId: json['uniqueId']?.toString() ?? '',
      metalType: json['metalType']?.toString() ?? '',
      quantity: (json['quantity'] is num)
          ? (json['quantity'] as num).toDouble()
          : double.tryParse(json['quantity']?.toString() ?? '') ?? 0,
      lockPrice: json['lockPrice']?.toString() ?? '',
      blockId: json['blockId']?.toString(),
      sku: json['sku']?.toString(),
      addressId: json['addressId']?.toString(),
      couponCode: json['couponCode']?.toString(),
      couponSubtotal: (json['couponSubtotal'] as num?)?.toDouble(),
      couponFee: (json['couponFee'] as num?)?.toDouble(),
      employeeId: json['employeeId']?.toString(),
      corporateId: json['corporateId']?.toString(),
    );
  }
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
  final String couponReservationId;
  final double couponDiscount;

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
    this.couponReservationId = '',
    this.couponDiscount = 0,
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
      couponReservationId: json['couponReservationId']?.toString() ?? '',
      couponDiscount: (json['couponDiscount'] as num?)?.toDouble() ?? 0,
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
