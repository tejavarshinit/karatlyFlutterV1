class UserProfile {
  final String fullName;
  final String email;
  final String mobileNumber;
  final String pinCode;
  final String dateOfBirth;
  final String uniqueId;
  final String partnerUserId;
  final bool panVerified;
  final bool aadhaarVerified;
  final bool bankVerified;
  final String kycStatus;
  final String? profilePhoto;

  const UserProfile({
    this.fullName = '',
    this.email = '',
    this.mobileNumber = '',
    this.pinCode = '',
    this.dateOfBirth = '',
    this.uniqueId = '',
    this.partnerUserId = '',
    this.panVerified = false,
    this.aadhaarVerified = false,
    this.bankVerified = false,
    this.kycStatus = '',
    this.profilePhoto,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      fullName: json['fullName']?.toString() ?? json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? json['emailId']?.toString() ?? '',
      mobileNumber: json['mobileNumber']?.toString() ?? json['mobile']?.toString() ?? '',
      pinCode: json['pinCode']?.toString() ?? json['pincode']?.toString() ?? '',
      dateOfBirth: json['dateOfBirth']?.toString() ?? json['dob']?.toString() ?? '',
      uniqueId: json['augmontUniqueId']?.toString() ?? json['uniqueId']?.toString() ?? '',
      partnerUserId: json['partnerUserId']?.toString() ?? '',
      panVerified: json['panVerified'] == true,
      aadhaarVerified: json['aadhaarVerified'] == true,
      bankVerified: json['bankVerified'] == true,
      kycStatus: json['kycStatus']?.toString() ?? '',
      profilePhoto: json['profilePhoto']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'fullName': fullName,
    'email': email,
    'mobileNumber': mobileNumber,
    'pinCode': pinCode,
    'dateOfBirth': dateOfBirth,
    'uniqueId': uniqueId,
    'partnerUserId': partnerUserId,
    'panVerified': panVerified,
    'aadhaarVerified': aadhaarVerified,
    'bankVerified': bankVerified,
    'kycStatus': kycStatus,
    'profilePhoto': profilePhoto,
  };

  UserProfile copyWith({
    String? fullName,
    String? email,
    String? mobileNumber,
    String? pinCode,
    String? dateOfBirth,
    String? uniqueId,
    String? partnerUserId,
    bool? panVerified,
    bool? aadhaarVerified,
    bool? bankVerified,
    String? kycStatus,
    String? profilePhoto,
  }) {
    return UserProfile(
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      pinCode: pinCode ?? this.pinCode,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      uniqueId: uniqueId ?? this.uniqueId,
      partnerUserId: partnerUserId ?? this.partnerUserId,
      panVerified: panVerified ?? this.panVerified,
      aadhaarVerified: aadhaarVerified ?? this.aadhaarVerified,
      bankVerified: bankVerified ?? this.bankVerified,
      kycStatus: kycStatus ?? this.kycStatus,
      profilePhoto: profilePhoto ?? this.profilePhoto,
    );
  }
}

class AuthUser {
  final String name;
  final String kycStatus; // 'Verified', 'Pending', 'Not Started'
  final bool kycApproved;
  final bool panVerified;
  final bool aadhaarVerified;
  final bool bankVerified;
  final String? augmontUniqueId;
  final String? profilePhoto;

  const AuthUser({
    this.name = 'User',
    this.kycStatus = 'Not Started',
    this.kycApproved = false,
    this.panVerified = false,
    this.aadhaarVerified = false,
    this.bankVerified = false,
    this.augmontUniqueId,
    this.profilePhoto,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    final kycRaw = (json['kycStatus']?.toString() ?? '').toLowerCase();
    final kycApproved = kycRaw == 'approved';
    return AuthUser(
      name: json['fullName']?.toString() ?? json['name']?.toString() ?? json['userName']?.toString() ?? 'User',
      kycStatus: kycApproved ? 'Verified' : (kycRaw.isNotEmpty ? 'Pending' : 'Not Started'),
      kycApproved: kycApproved,
      panVerified: json['panVerified'] == true,
      aadhaarVerified: json['aadhaarVerified'] == true,
      bankVerified: json['bankVerified'] == true,
      augmontUniqueId: json['augmontUniqueId']?.toString() ?? json['uniqueId']?.toString(),
      profilePhoto: json['profilePhoto']?.toString(),
    );
  }
}
