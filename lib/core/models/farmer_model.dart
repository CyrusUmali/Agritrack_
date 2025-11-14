import 'package:equatable/equatable.dart';

class Farmer extends Equatable {
  final int id;
  final String name;
  final String? firstname;
  final String? middlename;
  final String? surname;
  final String? extension;
  final String sector;
  final String? association;
  final String? barangay;
  final String? contact;
  final String? farmName;
  final String? sex;
  final double? hectare;
  final String? email;
  final String? phone;
  final String? address;
  final String? imageUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? house_hold_head;
  final String? civilStatus;
  final String? accountStatus;
  final String? spouseName;
  final String? religion;
  final int? userId;
  final int? householdNum;
  final int? maleMembersNum;
  final int? femaleMembersNum;
  final String? motherMaidenName;
  final String? personToNotify;
  final String? ptnContact;
  final String? ptnRelationship;
   final DateTime? birthday;

  const Farmer({
    required this.id,
    this.birthday, // Add to constructor
    required this.name,
    this.association,
    this.firstname,
    this.middlename,
    this.surname,
    this.extension,
    this.sex,
    required this.sector,
    this.barangay,
    this.contact,
    this.userId,
    this.farmName,
    this.hectare,
    this.email,
    this.phone,
    this.address,
    this.imageUrl =
        'https://res.cloudinary.com/dk41ykxsq/image/upload/v1745590990/cHJpdmF0ZS9sci9pbWFnZXMvd2Vic2l0ZS8yMDIzLTAxL3JtNjA5LXNvbGlkaWNvbi13LTAwMi1wLnBuZw-removebg-preview_myrmrf.png',
    this.createdAt,
    this.updatedAt,
    this.house_hold_head,
    this.civilStatus,
    this.accountStatus,
    this.spouseName,
    this.religion,
    this.householdNum,
    this.maleMembersNum,
    this.femaleMembersNum,
    this.motherMaidenName,
    this.personToNotify,
    this.ptnContact,
    this.ptnRelationship,
  });

  factory Farmer.fromMap(Map<String, dynamic> map) {
    return Farmer(
      id: map['id'] ?? 0,
      name: map['name'] ?? '',
      firstname: map['firstname'],
      birthday: map['birthday'] != null
          ? DateTime.tryParse(map['birthday'])
          : null, // Parse birthday if available
      middlename: map['middlename'],
      accountStatus: map['accountStatus'],
      association: map['association'],
      surname: map['surname'],
      extension: map['extension'],
      sector: map['sector'] ?? '',
      barangay: map['barangay'],
      contact: map['contact'],
      farmName: map['farmName'],
      sex: map['sex'],
      hectare: map['hectare']?.toDouble(),
      email: map['email'],
      phone: map['phone'],
      address: map['address'],
      imageUrl: map['imageUrl'],
      createdAt:
          map['createdAt'] != null ? DateTime.tryParse(map['createdAt']) : null,
      updatedAt:
          map['updatedAt'] != null ? DateTime.tryParse(map['updatedAt']) : null,
      house_hold_head: map['house_hold_head'],
      civilStatus: map['civil_status'],
      spouseName: map['spouse_name'],
      religion: map['religion'],
      userId: map['userId'],
      householdNum: map['household_num'],
      maleMembersNum: map['male_members_num'],
      femaleMembersNum: map['female_members_num'],
      motherMaidenName: map['mother_maiden_name'],
      personToNotify: map['person_to_notify'],
      ptnContact: map['ptn_contact'],
      ptnRelationship: map['ptn_relationship'],
    );
  }

  factory Farmer.fromJson(Map<String, dynamic> json) {
    return Farmer(
      id: (json['id'] as int?) ?? 0,
      name: (json['name'] as String?) ?? 'Unknown',
    accountStatus: (json['accountStatus'] ?? json['user_status']) as String? ?? 'Unregistered',
      firstname: (json['firstname'] as String?) ?? '',  
      birthday: json['birthday'] != null
          ? DateTime.tryParse(json['birthday'])
          : null, // Parse birthday if available


     // When sending to API:
     //'
    //  birthday: farmer.birthday?.toIso8601String().split('T')[0]  ,
      surname: (json['surname'] as String?) ?? '',
      middlename: (json['middlename'] as String?) ?? '',
      association: (json['association' as String?]) ?? '',
      extension: (json['extension'] as String?) ?? '',
      sector: (json['sector'] as String?) ?? 'Unknown Sector',
      barangay: (json['barangay'] as String?) ?? 'Unknown Barangay',
      contact: (json['contact'] as String?) ?? '',
      farmName: (json['farmName'] as String?) ?? '',
      sex: (json['sex'] as String?) ?? '',
      hectare: (json['hectare'] as num?)?.toDouble() ?? 0.0,
      email: (json['email'] as String?) ?? '',
      userId: (json['userId'] as int?) ?? 0,
      phone: (json['phone'] as String?) ?? '',
      address: (json['address'] as String?) ?? '',
      imageUrl: json['imageUrl'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'])
          : null,
      house_hold_head: json['house_hold_head'] as String?,
      civilStatus: json['civil_status'] as String?,
      spouseName: json['spouse_name'] as String?,
      religion: json['religion'] as String?,
      householdNum: json['household_num'] as int?,
      maleMembersNum: json['male_members_num'] as int?,
      femaleMembersNum: json['female_members_num'] as int?,
      motherMaidenName: json['mother_maiden_name'] as String?,
      personToNotify: json['person_to_notify'] as String?,
      ptnContact: json['ptn_contact'] as String?,
      ptnRelationship: json['ptn_relationship'] as String?,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'firstname': firstname,
      'accountStatus': accountStatus,
      'surname': surname,
      'middlename': middlename,
      'association': association,
      'extension': extension,
      'sector': sector,
      'userId': userId,
      'barangay': barangay,
      'contact': contact,
      'farmName': farmName,
      'sex': sex,
    'birthday': birthday != null 
        ? "${birthday!.year}-${birthday!.month.toString().padLeft(2, '0')}-${birthday!.day.toString().padLeft(2, '0')}"
        : null,
      'hectare': hectare,
      'email': email,
      'phone': phone,
      'address': address,
      'imageUrl': imageUrl,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'house_hold_head': house_hold_head,
      'civil_status': civilStatus,
      'spouse_name': spouseName,
      'religion': religion,
      'household_num': householdNum,
      'male_members_num': maleMembersNum,
      'female_members_num': femaleMembersNum,
      'mother_maiden_name': motherMaidenName,
      'person_to_notify': personToNotify,
      'ptn_contact': ptnContact,
      'ptn_relationship': ptnRelationship,
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'firstname': firstname,
      'surname': surname,
      'middlename': middlename,
      'birthday': birthday?.toIso8601String(),
      'accountStatus': accountStatus,
      'association': association,
      'extension': extension,
      'sector': sector,
      'userId': userId,
      'barangay': barangay,
      'contact': contact,
      'farmName': farmName,
      'sex': sex,
      'hectare': hectare,
      'email': email,
      'phone': phone,
      'address': address,
      'imageUrl': imageUrl,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'house_hold_head': house_hold_head,
      'civil_status': civilStatus,
      'spouse_name': spouseName,
      'religion': religion,
      'household_num': householdNum,
      'male_members_num': maleMembersNum,
      'female_members_num': femaleMembersNum,
      'mother_maiden_name': motherMaidenName,
      'person_to_notify': personToNotify,
      'ptn_contact': ptnContact,
      'ptn_relationship': ptnRelationship,
    };
  }

 
  @override
  List<Object?> get props => [
        id,
        name,
        birthday,
        firstname,
        surname,
        middlename,
        association,
        extension,
        sector,
        barangay,
        contact,
        farmName,
        hectare,
        email,
        phone,
        address,
        imageUrl,
        createdAt,
        updatedAt,
        house_hold_head,
        civilStatus,
        accountStatus,
        spouseName,
        religion,
        householdNum,
        maleMembersNum,
        femaleMembersNum,
        motherMaidenName,
        personToNotify,
        ptnContact,
        ptnRelationship,
        userId
      ];
}
