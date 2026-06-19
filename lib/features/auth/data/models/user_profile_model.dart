import '../../domain/entities/user_profile.dart';

class SalesTeamMemberModel extends SalesTeamMemberEntity {
  SalesTeamMemberModel({
    required super.salesPersonId,
    super.userId,
    required super.fullName,
    super.positionName,
    super.subordinates,
  });

  factory SalesTeamMemberModel.fromJson(Map<String, dynamic> json) {
    return SalesTeamMemberModel(
      salesPersonId: json['sales_person_id'],
      userId: json['user_id'],
      fullName: json['full_name'] ?? '',
      positionName: json['position_name'],
      subordinates: json['subordinates'] != null
          ? (json['subordinates'] as List).map((i) => SalesTeamMemberModel.fromJson(i)).toList()
          : const [],
    );
  }
}

class SalesTeamHierarchyModel extends SalesTeamHierarchyEntity {
  SalesTeamHierarchyModel({
    required super.salesTeamId,
    required super.salesTeamName,
    super.members,
  });

  factory SalesTeamHierarchyModel.fromJson(Map<String, dynamic> json) {
    return SalesTeamHierarchyModel(
      salesTeamId: json['sales_team_id'],
      salesTeamName: json['sales_team_name'] ?? '',
      members: json['members'] != null
          ? (json['members'] as List).map((i) => SalesTeamMemberModel.fromJson(i)).toList()
          : const [],
    );
  }
}

class HirachyUserModel extends HirachyUserEntity {
  HirachyUserModel({
    required super.userId,
    required super.fullName,
    super.access,
    super.accessLabel,
  });

  factory HirachyUserModel.fromJson(Map<String, dynamic> json) {
    return HirachyUserModel(
      userId: json['user_id'],
      fullName: json['full_name'] ?? '',
      access: json['access'],
      accessLabel: json['access_label'],
    );
  }
}

class GroupHierarchyModel extends GroupHierarchyEntity {
  GroupHierarchyModel({
    required super.groupId,
    required super.groupName,
    super.users,
    super.children,
  });

  factory GroupHierarchyModel.fromJson(Map<String, dynamic> json) {
    return GroupHierarchyModel(
      groupId: json['group_id'],
      groupName: json['group_name'] ?? '',
      users: json['users'] != null
          ? (json['users'] as List).map((i) => HirachyUserModel.fromJson(i)).toList()
          : const [],
      children: json['children'] != null
          ? (json['children'] as List).map((i) => GroupHierarchyModel.fromJson(i)).toList()
          : const [],
    );
  }
}

class HierarchyNodeModel extends HierarchyNodeEntity {
  HierarchyNodeModel({
    super.salesRoleId,
    required super.salesPersonId,
    super.userId,
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
      userId: json['user_id'],
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
    super.photoUrl,
    required super.permissionScope,
    super.positionName,
    super.salesPersonId,
    super.salesTeamId,
    super.salesTeamName,
    super.userRoleId,
    super.userRoleName,
    super.salesRoles,
    super.subordinates,
    super.groupHierarchy,
    super.salesTeamHierarchy,
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
      photoUrl: json['photo_url'],
      permissionScope: json['permission_scope'] ?? '',
      positionName: json['position_name'],
      salesPersonId: json['sales_person_id'],
      salesTeamId: json['sales_team_id'],
      salesTeamName: json['sales_team_name'],
      userRoleId: json['user_role_id'],
      userRoleName: json['user_role_name'],
      salesRoles: json['sales_roles'] != null ? (json['sales_roles'] as List).map((i) => HierarchyNodeModel.fromJson(i)).toList() : const [],
      subordinates: json['subordinates'] != null ? (json['subordinates'] as List).map((i) => HierarchyNodeModel.fromJson(i)).toList() : const [],
      groupHierarchy: json['group_hierarchy'] != null ? (json['group_hierarchy'] as List).map((i) => GroupHierarchyModel.fromJson(i)).toList() : const [],
      salesTeamHierarchy: json['sales_team_hierarchy'] != null ? (json['sales_team_hierarchy'] as List).map((i) => SalesTeamHierarchyModel.fromJson(i)).toList() : const [],
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
