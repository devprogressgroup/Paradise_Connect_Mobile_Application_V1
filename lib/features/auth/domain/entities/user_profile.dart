class HierarchyNodeEntity {
  final int? salesRoleId;
  final int salesPersonId;
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
  final List<HierarchyNodeEntity> salesRoles;
  final List<HierarchyNodeEntity> subordinates;

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
    this.salesRoles = const [],
    this.subordinates = const [],
  });

}
