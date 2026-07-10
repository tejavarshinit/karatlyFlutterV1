class AugmontOrder {
  final String id;
  final String type;
  final double amount;
  final double gold;
  final double rate;
  final dynamic taxRate;
  final dynamic taxAmt;
  final String date;
  final String status;
  final String merchantTransactionId;
  final String transactionId;
  final String uniqueId;
  final String metalType;

  const AugmontOrder({
    this.id = '',
    this.type = '',
    this.amount = 0,
    this.gold = 0,
    this.rate = 0,
    this.taxRate,
    this.taxAmt,
    this.date = '',
    this.status = 'Pending',
    this.merchantTransactionId = '',
    this.transactionId = '',
    this.uniqueId = '',
    this.metalType = '',
  });

  String get orderReference => merchantTransactionId.isNotEmpty ? merchantTransactionId : transactionId;

  factory AugmontOrder.fromJson(Map<String, dynamic> json) {
    final rawType = json['type']?.toString().toLowerCase() ?? '';
    final inferredMetalType = (json['metalType']?.toString().trim().isNotEmpty ?? false)
        ? json['metalType']!.toString()
        : (rawType == 'gold' || rawType == 'silver' || rawType == 'diamond' ? rawType : '');
    return AugmontOrder(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      amount: _toDouble(json['amount']),
      gold: _toDouble(json['gold']),
      rate: _toDouble(json['rate']),
      taxRate: json['taxRate'],
      taxAmt: json['taxAmt'],
      date: json['date']?.toString() ?? '',
      status: json['status']?.toString() ?? 'Pending',
      merchantTransactionId: json['merchantTransactionId']?.toString() ?? '',
      transactionId: json['transactionId']?.toString() ?? '',
      uniqueId: json['uniqueId']?.toString() ?? '',
      metalType: inferredMetalType,
    );
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    return double.tryParse(value.toString()) ?? 0;
  }
}

class AugmontUserProfile {
  final String userName;
  final String uniqueId;
  final String customerMappedId;
  final String mobileNumber;
  final String userEmail;
  final String emailId;
  final String userStateId;
  final String userCityId;
  final String stateName;
  final String cityName;
  final String userPincode;
  final String kycStatus;
  final String userState;
  final String userCity;
  final String createdAt;
  final String userBankId;
  final String userAddressId;
  final bool profileExists;
  final bool profileCompleted;
  final Map<String, dynamic>? raw;

  const AugmontUserProfile({
    this.userName = '',
    this.uniqueId = '',
    this.customerMappedId = '',
    this.mobileNumber = '',
    this.userEmail = '',
    this.emailId = '',
    this.userStateId = '',
    this.userCityId = '',
    this.stateName = '',
    this.cityName = '',
    this.userPincode = '',
    this.kycStatus = '',
    this.userState = '',
    this.userCity = '',
    this.createdAt = '',
    this.userBankId = '',
    this.userAddressId = '',
    this.profileExists = false,
    this.profileCompleted = false,
    this.raw,
  });

  factory AugmontUserProfile.fromJson(Map<String, dynamic> json) {
    return AugmontUserProfile(
      userName: json['userName']?.toString() ?? json['name']?.toString() ?? '',
      uniqueId: json['uniqueId']?.toString() ?? json['userUniqueId']?.toString() ?? json['customerUniqueId']?.toString() ?? '',
      customerMappedId: json['customerMappedId']?.toString() ?? '',
      mobileNumber: json['mobileNumber']?.toString() ?? json['mobileNo']?.toString() ?? '',
      userEmail: json['userEmail']?.toString() ?? json['emailId']?.toString() ?? json['email']?.toString() ?? '',
      emailId: json['emailId']?.toString() ?? json['email']?.toString() ?? '',
      userStateId: json['userStateId']?.toString() ?? json['stateId']?.toString() ?? '',
      userCityId: json['userCityId']?.toString() ?? json['cityId']?.toString() ?? '',
      stateName: json['stateName']?.toString() ?? json['userState']?.toString() ?? '',
      cityName: json['cityName']?.toString() ?? json['userCity']?.toString() ?? '',
      userPincode: json['userPincode']?.toString() ?? json['pincode']?.toString() ?? '',
      kycStatus: json['kycStatus']?.toString() ?? '',
      userState: json['userState']?.toString() ?? '',
      userCity: json['userCity']?.toString() ?? '',
      createdAt: json['createdAt']?.toString() ?? '',
      userBankId: json['userBankId']?.toString() ?? '',
      userAddressId: json['userAddressId']?.toString() ?? '',
      profileExists: json['profileExists'] == true || json.isNotEmpty,
      profileCompleted: json['profileCompleted'] == true,
      raw: json,
    );
  }
}

class AugmontPassbook {
  final double goldGrams;
  final double silverGrams;

  const AugmontPassbook({
    this.goldGrams = 0,
    this.silverGrams = 0,
  });

  factory AugmontPassbook.fromJson(Map<String, dynamic> json) {
    return AugmontPassbook(
      goldGrams: _toDouble(json['goldGrms'] ?? json['goldBalance'] ?? json['gold'] ?? json['balance']),
      silverGrams: _toDouble(json['silverGrms'] ?? json['silverBalance'] ?? json['silver']),
    );
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    return double.tryParse(value.toString()) ?? 0;
  }
}
