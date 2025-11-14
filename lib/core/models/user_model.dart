class UserModel {
  final int id;
  final String email;
  final String name;
  final String? password;
  final String? newPassword;
  final String? photoUrl;
  final String? phone;
  final String role;
  final String? fname;
  final String? lname;
  final String? sector;
  final String? barangay;
  final String? status;
  final String? idToken;
  final int? farmerId;
  final String? authProvider; // 'email' or 'google'
  final bool? hasPassword; // true for email/password users
  final DateTime? createdAt; // New field

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.photoUrl,
    this.password,
    this.newPassword,
    required this.role,
    this.fname,
    this.phone,
    this.lname,
    this.sector,
    this.barangay,
    this.status,
    this.idToken,
    this.farmerId,
    this.authProvider,
    this.hasPassword,
    this.createdAt, // New field
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: (json['id'] as int?) ?? 0,
      email: (json['email'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      password: (json['password'] as String?) ?? '',
      newPassword: (json['newPassword'] as String?) ?? '',
      photoUrl: json['photoUrl'] as String?,
      role: (json['role'] as String?) ?? '',
      fname: (json['fname'] as String?) ?? '',
      status: (json['status'] as String?) ?? '',
      lname: (json['lname'] as String?) ?? '',
      sector: (json['sector'] as String?) ?? '',
      barangay: (json['barangay'] as String?) ?? '',
      phone: (json['phone'] as String?) ?? '',
      farmerId: (json['farmerId'] as int?) ?? 0,
      authProvider: (json['authProvider'] as String?) ?? 'email',
      hasPassword: (json['hasPassword'] as bool?) ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null, // Parse DateTime
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'photoUrl': photoUrl,
      'role': role,
      'fname': fname,
      'lname': lname,
      'password': password,
      'newPassword': newPassword,
      'sector': sector,
      'status': status,
      'idToken': idToken,
      'barangay': barangay,
      'phone': phone,
      'farmerId': farmerId,
      'authProvider': authProvider,
      'hasPassword': hasPassword,
      'createdAt': createdAt?.toIso8601String(), // Convert to ISO string
    };
  }

  @override
  List<Object?> get props => [
        id,
        email,
        name,
        photoUrl,
        role,
        fname,
        lname,
        sector,
        status,
        password,
        newPassword,
        barangay,
        phone,
        farmerId,
        authProvider,
        hasPassword,
        createdAt, // Include new field
      ];

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? 0,
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      photoUrl: map['photoUrl'],
      role: map['role'] ?? '',
      fname: map['fname'] ?? '',
      password: map['password'] ?? '',
      newPassword: map['newPassword'] ?? '',
      lname: map['lname'] ?? '',
      sector: map['sector'] ?? '',
      phone: map['phone'] ?? map['contact'] ?? '',
      farmerId: map['farmerId'] ?? 0,
      status: map['status'] ?? '',
      barangay: map['barangay'] ?? '',
      authProvider: map['authProvider'] ?? 'email',
      hasPassword: map['hasPassword'] ?? true,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : null, // Parse DateTime
    );
  }

// Add the copyWith method
  UserModel copyWith({
    int? id,
    String? email,
    String? name,
    String? password,
    String? newPassword,
    String? photoUrl,
    String? phone,
    String? role,
    String? fname,
    String? lname,
    String? sector,
    String? barangay,
    String? status,
    String? idToken,
    int? farmerId,
    String? authProvider,
    bool? hasPassword,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      password: password ?? this.password,
      newPassword: newPassword ?? this.newPassword,
      photoUrl: photoUrl ?? this.photoUrl,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      fname: fname ?? this.fname,
      lname: lname ?? this.lname,
      sector: sector ?? this.sector,
      barangay: barangay ?? this.barangay,
      status: status ?? this.status,
      idToken: idToken ?? this.idToken,
      farmerId: farmerId ?? this.farmerId,
      authProvider: authProvider ?? this.authProvider,
      hasPassword: hasPassword ?? this.hasPassword,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'password': password,
      'newPassword': newPassword,
      'photoUrl': photoUrl,
      'role': role,
      'fname': fname,
      'lname': lname,
      'sector': sector,
      'status': status,
      'barangay': barangay,
      'phone': phone,
      'farmerId': farmerId,
      'authProvider': authProvider,
      'hasPassword': hasPassword,
      'createdAt': createdAt?.toIso8601String(), // Convert to ISO string
    };
  }
}
