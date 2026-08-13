/// Mapper for UserModel to User Entity.
library;

import '../../domain/entities/user_entity.dart';
import '../models/user_model.dart';

class UserMapper {
  static User toEntity(UserModel model) {
    return User(
      id: model.id,
      name: model.name,
      phone: model.phone,
      role: model.role == 'merchant'
          ? UserRole.merchant
          : (model.role == 'admin' ? UserRole.admin : UserRole.customer),
      avatarUrl: model.avatarUrl,
      createdAt: model.createdAt != null
          ? DateTime.tryParse(model.createdAt!) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  static UserModel toModel(User entity) {
    return UserModel(
      id: entity.id,
      name: entity.name,
      phone: entity.phone,
      role: entity.role == UserRole.merchant
          ? 'merchant'
          : (entity.role == UserRole.admin ? 'admin' : 'customer'),
      avatarUrl: entity.avatarUrl,
      createdAt: entity.createdAt.toIso8601String(),
    );
  }
}
