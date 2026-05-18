import '../../domain/entities/user_profile.dart';

class HierarchyNodeModel extends HierarchyNodeEntity {
  HierarchyNodeModel({
    super.salesRoleId,
    required super.salesPersonId,
    super.salesPersonParentId,
    super.salesTeamId,
    super.salesTeamName,
    super.companyId,
    required super.fullName,
    super.positionName,
    super.parent,
    super.subordinates,
  });

  factory HierarchyNodeModel.fromJson(Map<String, dynamic> json) {
    return HierarchyNodeModel(
      salesRoleId: json['sales_role_id'],
      salesPersonId: json['sales_person_id'],
      salesPersonParentId: json['sales_person_parent_id'],
      salesTeamId: json['sales_team_id'],
      salesTeamName: json['sales_team_name'],
      companyId: json['company_id'],
      fullName: json['full_name'] ?? '',
      positionName: json['position_name'],
      parent: json['parent'] != null ? HierarchyNodeModel.fromJson(json['parent']) : null,
      subordinates: json['subordinates'] != null ? (json['subordinates'] as List).map((i) => HierarchyNodeModel.fromJson(i)).toList() : const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sales_role_id': salesRoleId,
      'sales_person_id': salesPersonId,
      'sales_person_parent_id': salesPersonParentId,
      'sales_team_id': salesTeamId,
      'company_id': companyId,
      'full_name': fullName,
      'position_name': positionName,
      'parent': (parent as HierarchyNodeModel?)?.toJson(),
      'subordinates': subordinates.map((i) => (i as HierarchyNodeModel).toJson()).toList(),
    };
  }
}

class UserProfileModel extends UserProfileEntity {
  UserProfileModel({
    required super.userId,
    required super.fullName,
    required super.username,
    required super.email,
    required super.phoneNumber,
    required super.isActive,
    super.photo,
    required super.permissionScope,
    super.positionName,
    super.salesPersonId,
    super.salesTeamId,
    super.salesTeamName,
    super.salesRoles,
    super.subordinates,
    super.nikNumber,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      userId: json['user_id'],
      fullName: json['full_name'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      isActive: json['is_active'] ?? false,
      photo: json['photo'],
      permissionScope: json['permission_scope'] ?? '',
      positionName: json['position_name'],
      salesPersonId: json['sales_person_id'],
      salesTeamId: json['sales_team_id'],
      salesTeamName: json['sales_team_name'],
      salesRoles: json['sales_roles'] != null ? (json['sales_roles'] as List).map((i) => HierarchyNodeModel.fromJson(i)).toList() : const [],
      subordinates: json['subordinates'] != null ? (json['subordinates'] as List).map((i) => HierarchyNodeModel.fromJson(i)).toList() : const [],
      nikNumber: json['nik_number'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'full_name': fullName,
      'username': username,
      'email': email,
      'phone_number': phoneNumber,
      'is_active': isActive,
      'photo': photo,
      'permission_scope': permissionScope,
      'position_name': positionName,
      'sales_person_id': salesPersonId,
      'sales_roles': salesRoles.map((i) => (i as HierarchyNodeModel).toJson()).toList(),
      'subordinates': subordinates.map((i) => (i as HierarchyNodeModel).toJson()).toList(),
      'nik_number': nikNumber,
    };
  }
}
