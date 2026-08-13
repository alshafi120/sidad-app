/// Auth domain entities.
library;

import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String name;
  final String phone;
  final UserRole role;
  final String? avatarUrl;
  final DateTime createdAt;

  const User({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
    this.avatarUrl,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, name, phone, role, avatarUrl, createdAt];
}

enum UserRole { merchant, customer, admin }
