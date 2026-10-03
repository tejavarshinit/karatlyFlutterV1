class GoldFlowState {
  final BuyState buyState;
  final SellState sellState;
  final SipState sipState;

  const GoldFlowState({
    this.buyState = const BuyState(),
    this.sellState = const SellState(),
    this.sipState = const SipState(),
  });

  GoldFlowState copyWith({
    BuyState? buyState,
    SellState? sellState,
    SipState? sipState,
  }) {
    return GoldFlowState(
      buyState: buyState ?? this.buyState,
      sellState: sellState ?? this.sellState,
      sipState: sipState ?? this.sipState,
    );
  }
}

class BuyState {
  final String type;
  final String sku;
  final double amount;
  final double rate;
  final String blockId;
  final String uniqueId;
  final double grams;
  final double preTax;
  final double gst;
  final double totalPaid;
  final String brand;
  final String address;
  final String paymentMethod;
  final String transactionId;
  final String merchantTransactionId;
  final String paymentStatus;
  final String paymentMessage;
  final String metalType;
  final String addressId;
  final bool isRedeemPayment;
  final String couponCode;
  final String reservationId;
  final double couponDiscount;
  final bool couponApplied;
  final String employeeId;
  final String corporateId;
  final String couponReservationId;

  const BuyState({
    this.type = '',
    this.sku = '',
    this.amount = 0,
    this.rate = 0,
    this.blockId = '',
    this.uniqueId = '',
    this.grams = 0,
    this.preTax = 0,
    this.gst = 0,
    this.totalPaid = 0,
    this.brand = '',
    this.address = '',
    this.paymentMethod = '',
    this.transactionId = '',
    this.merchantTransactionId = '',
    this.paymentStatus = '',
    this.paymentMessage = '',
    this.metalType = '',
    this.addressId = '',
    this.isRedeemPayment = false,
    this.couponCode = '',
    this.reservationId = '',
    this.couponDiscount = 0,
    this.couponApplied = false,
    this.employeeId = '',
    this.corporateId = '',
    this.couponReservationId = '',
  });

  BuyState copyWith({
    String? type,
    String? sku,
    double? amount,
    double? rate,
    String? blockId,
    String? uniqueId,
    double? grams,
    double? preTax,
    double? gst,
    double? totalPaid,
    String? brand,
    String? address,
    String? paymentMethod,
    String? transactionId,
    String? merchantTransactionId,
    String? paymentStatus,
    String? paymentMessage,
    String? metalType,
    String? addressId,
    bool? isRedeemPayment,
    String? couponCode,
    String? reservationId,
    double? couponDiscount,
    bool? couponApplied,
    String? employeeId,
    String? corporateId,
    String? couponReservationId,
  }) {
    return BuyState(
      type: type ?? this.type,
      sku: sku ?? this.sku,
      amount: amount ?? this.amount,
      rate: rate ?? this.rate,
      blockId: blockId ?? this.blockId,
      uniqueId: uniqueId ?? this.uniqueId,
      grams: grams ?? this.grams,
      preTax: preTax ?? this.preTax,
      gst: gst ?? this.gst,
      totalPaid: totalPaid ?? this.totalPaid,
      brand: brand ?? this.brand,
      address: address ?? this.address,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      transactionId: transactionId ?? this.transactionId,
      merchantTransactionId:
          merchantTransactionId ?? this.merchantTransactionId,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentMessage: paymentMessage ?? this.paymentMessage,
      metalType: metalType ?? this.metalType,
      addressId: addressId ?? this.addressId,
      isRedeemPayment: isRedeemPayment ?? this.isRedeemPayment,
      couponCode: couponCode ?? this.couponCode,
      reservationId: reservationId ?? this.reservationId,
      couponDiscount: couponDiscount ?? this.couponDiscount,
      couponApplied: couponApplied ?? this.couponApplied,
      employeeId: employeeId ?? this.employeeId,
      corporateId: corporateId ?? this.corporateId,
      couponReservationId: couponReservationId ?? this.couponReservationId,
    );
  }
}

class SellState {
  final double amount;
  final double rate;
  final String blockId;
  final String uniqueId;
  final double grams;
  final double payout;
  final double platformFee;
  final String userBankId;
  final String bankName;
  final String transactionId;
  final String merchantTransactionId;
  final String orderStatus;
  final String metalType;
  final String payoutMethod;
  final String upiId;
  final String mobileNumber;
  final String accountNumber;
  final String accountHolderName;
  final String ifscCode;
  final bool payoutVerified;

  const SellState({
    this.amount = 0,
    this.rate = 0,
    this.blockId = '',
    this.uniqueId = '',
    this.grams = 0,
    this.payout = 0,
    this.platformFee = 0,
    this.userBankId = '',
    this.bankName = '',
    this.transactionId = '',
    this.merchantTransactionId = '',
    this.orderStatus = '',
    this.metalType = '',
    this.payoutMethod = '',
    this.upiId = '',
    this.mobileNumber = '',
    this.accountNumber = '',
    this.accountHolderName = '',
    this.ifscCode = '',
    this.payoutVerified = false,
  });

  SellState copyWith({
    double? amount,
    double? rate,
    String? blockId,
    String? uniqueId,
    double? grams,
    double? payout,
    double? platformFee,
    String? userBankId,
    String? bankName,
    String? transactionId,
    String? merchantTransactionId,
    String? orderStatus,
    String? metalType,
    String? payoutMethod,
    String? upiId,
    String? mobileNumber,
    String? accountNumber,
    String? accountHolderName,
    String? ifscCode,
    bool? payoutVerified,
  }) {
    return SellState(
      amount: amount ?? this.amount,
      rate: rate ?? this.rate,
      blockId: blockId ?? this.blockId,
      uniqueId: uniqueId ?? this.uniqueId,
      grams: grams ?? this.grams,
      payout: payout ?? this.payout,
      platformFee: platformFee ?? this.platformFee,
      userBankId: userBankId ?? this.userBankId,
      bankName: bankName ?? this.bankName,
      transactionId: transactionId ?? this.transactionId,
      merchantTransactionId:
          merchantTransactionId ?? this.merchantTransactionId,
      orderStatus: orderStatus ?? this.orderStatus,
      metalType: metalType ?? this.metalType,
      payoutMethod: payoutMethod ?? this.payoutMethod,
      upiId: upiId ?? this.upiId,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      accountNumber: accountNumber ?? this.accountNumber,
      accountHolderName: accountHolderName ?? this.accountHolderName,
      ifscCode: ifscCode ?? this.ifscCode,
      payoutVerified: payoutVerified ?? this.payoutVerified,
    );
  }
}

class SipState {
  final double amount;
  final double rate;
  final String blockId;
  final String uniqueId;
  final String metalType;
  final String frequency;
  final int date;
  final int cycles;
  final String type;
  final String brand;
  final String transactionId;
  final String merchantTransactionId;

  const SipState({
    this.amount = 0,
    this.rate = 0,
    this.blockId = '',
    this.uniqueId = '',
    this.metalType = '',
    this.frequency = '',
    this.date = 0,
    this.cycles = 0,
    this.type = '',
    this.brand = '',
    this.transactionId = '',
    this.merchantTransactionId = '',
  });

  SipState copyWith({
    double? amount,
    double? rate,
    String? blockId,
    String? uniqueId,
    String? metalType,
    String? frequency,
    int? date,
    int? cycles,
    String? type,
    String? brand,
    String? transactionId,
    String? merchantTransactionId,
  }) {
    return SipState(
      amount: amount ?? this.amount,
      rate: rate ?? this.rate,
      blockId: blockId ?? this.blockId,
      uniqueId: uniqueId ?? this.uniqueId,
      metalType: metalType ?? this.metalType,
      frequency: frequency ?? this.frequency,
      date: date ?? this.date,
      cycles: cycles ?? this.cycles,
      type: type ?? this.type,
      brand: brand ?? this.brand,
      transactionId: transactionId ?? this.transactionId,
      merchantTransactionId:
          merchantTransactionId ?? this.merchantTransactionId,
    );
  }
}
