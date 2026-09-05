import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;

  final String name;

  final String email;

  final List<String> roles;

  final Timestamp createdAt;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.roles,
    required this.createdAt,
  });

  factory UserModel.fromMap(
    Map<String, dynamic> map,
  ) {
    return UserModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      roles: List<String>.from(
        map['roles'] ?? [],
      ),
      createdAt:
          map['createdAt'] ??
              Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'roles': roles,
      'createdAt': createdAt,
    };
  }

  bool get isBuyer =>
      roles.contains('buyer');

  bool get isSeller =>
      roles.contains('seller');
}