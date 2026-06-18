class HirachyUserEntity {
  final int userId;
  final String fullName;
  final String? access;
  final String? accessLabel;

  HirachyUserEntity({
    required this.userId,
    required this.fullName,
    this.access,
    this.accessLabel,
  });
}

class GroupHierarchyEntity {
  final int groupId;
  final String groupName;
  final List<HirachyUserEntity> users;
  final List<GroupHierarchyEntity> children;

  GroupHierarchyEntity({
    required this.groupId,
    required this.groupName,
    this.users = const [],
    this.children = const [],
  });
}

class HierarchyNodeEntity {
  final int? salesRoleId;
  final int salesPersonId;
  final int? userId;
  final int? salesPersonParentId;
  final int? salesTeamId;
  final String? salesTeamName;
  final int? companyId;
  final String fullName;
  final String? positionName;
  final HierarchyNodeEntity? parent;
  final List<HierarchyNodeEntity> subordinates;

  HierarchyNodeEntity({
    this.salesRoleId,
    required this.salesPersonId,
    this.userId,
    this.salesPersonParentId,
    this.salesTeamId,
    this.salesTeamName,
    this.companyId,
    required this.fullName,
    this.positionName,
    this.parent,
    this.subordinates = const [],
  });
}

class UserProfileEntity {
  final int userId;
  final String fullName;
  final String username;
  final String email;
  final String phoneNumber;
  final bool isActive;
  final String? photo;
  final String? photoUrl;
  final String permissionScope;
  final String? positionName;
  final int? nikNumber;
  final int? salesPersonId;
  final int? salesTeamId;
  final String? salesTeamName;
  final int? userRoleId;
  final List<HierarchyNodeEntity> salesRoles;
  final List<HierarchyNodeEntity> subordinates;
  final List<GroupHierarchyEntity> groupHierarchy;

  UserProfileEntity({
    required this.userId,
    required this.fullName,
    required this.username,
    required this.email,
    required this.phoneNumber,
    required this.isActive,
    this.photo,
    this.photoUrl,
    required this.permissionScope,
    this.positionName,
    this.nikNumber,
    this.salesPersonId,
    this.salesTeamId,
    this.salesTeamName,
    this.userRoleId,
    this.salesRoles = const [],
    this.subordinates = const [],
    this.groupHierarchy = const [],
  });

}
