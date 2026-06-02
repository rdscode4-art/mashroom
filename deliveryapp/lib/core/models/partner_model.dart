class DeliveryPartner {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String profileImage;
  final String vehicleType;
  final String vehicleNumber;
  final String dlNumber;
  final String aadharNumber;
  final bool isOnline;
  final bool isAvailable;
  final bool isApproved;
  final String kycStatus;
  final String kycRejectionReason;
  final int totalDeliveries;
  final double earnings;

  const DeliveryPartner({
    required this.id,
    required this.name,
    required this.phone,
    this.email = '',
    this.profileImage = '',
    this.vehicleType = 'bike',
    this.vehicleNumber = '',
    this.dlNumber = '',
    this.aadharNumber = '',
    this.isOnline = false,
    this.isAvailable = true,
    this.isApproved = false,
    this.kycStatus = 'pending',
    this.kycRejectionReason = '',
    this.totalDeliveries = 0,
    this.earnings = 0,
  });

  factory DeliveryPartner.fromJson(Map<String, dynamic> j) => DeliveryPartner(
        id: j['_id'] ?? '',
        name: j['name'] ?? '',
        phone: j['phone'] ?? '',
        email: j['email'] ?? '',
        profileImage: j['profileImage'] ?? '',
        vehicleType: j['vehicleType'] ?? 'bike',
        vehicleNumber: j['vehicleNumber'] ?? '',
        dlNumber: j['kyc']?['dlNumber'] ?? '',
        aadharNumber: j['kyc']?['aadharNumber'] ?? '',
        isOnline: j['isOnline'] ?? false,
        isAvailable: j['isAvailable'] ?? true,
        isApproved: j['isApproved'] ?? false,
        kycStatus: j['kycStatus'] ?? 'pending',
        kycRejectionReason: j['kycRejectionReason'] ?? '',
        totalDeliveries: (j['totalDeliveries'] as num?)?.toInt() ?? 0,
        earnings: (j['earnings'] as num?)?.toDouble() ?? 0,
      );
}
