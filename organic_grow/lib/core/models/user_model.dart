class User {
  String id;
  String name;
  String email;
  String phone;
  String address;
  String image;
  String role;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    required this.image,
    this.role = 'customer',
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      address: json['address']?['fullAddress'] ?? json['address'] ?? '',
      image: json['profileImage'] ?? json['image'] ?? 'assets/images/placeholder.jpg',
      role: json['role'] ?? 'customer',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'image': image,
      'role': role,
    };
  }
}