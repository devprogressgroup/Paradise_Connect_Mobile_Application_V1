class PermissionFeatureModel {
  final int formFeatureId;
  final String featureName;
  final String? featureDescription;
  final bool active;

  PermissionFeatureModel({
    required this.formFeatureId,
    required this.featureName,
    this.featureDescription,
    required this.active,
  });

  factory PermissionFeatureModel.fromJson(Map<String, dynamic> json) => PermissionFeatureModel(
    formFeatureId: json['form_feature_id'] ?? 0,
    featureName: json['feature_name'] ?? '',
    featureDescription: json['feature_description'],
    active: (json['active'] ?? 0) == 1,
  );
}

class PermissionFormModel {
  final int formId;
  final String formName;
  final List<PermissionFeatureModel> features;

  PermissionFormModel({
    required this.formId,
    required this.formName,
    required this.features,
  });

  factory PermissionFormModel.fromJson(Map<String, dynamic> json) => PermissionFormModel(
    formId: json['form_id'] ?? 0,
    formName: json['form_name'] ?? '',
    features: (json['features'] as List<dynamic>? ?? [])
        .map((e) => PermissionFeatureModel.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

class PermissionModuleModel {
  final int moduleId;
  final String moduleName;
  final List<PermissionFormModel> forms;

  PermissionModuleModel({
    required this.moduleId,
    required this.moduleName,
    required this.forms,
  });

  factory PermissionModuleModel.fromJson(Map<String, dynamic> json) => PermissionModuleModel(
    moduleId: json['module_id'] ?? 0,
    moduleName: json['module_name'] ?? '',
    forms: (json['forms'] as List<dynamic>? ?? [])
        .map((e) => PermissionFormModel.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

class PermissionSoftwareModel {
  final int softwareId;
  final String softwareName;
  final List<PermissionModuleModel> modules;

  PermissionSoftwareModel({
    required this.softwareId,
    required this.softwareName,
    required this.modules,
  });

  factory PermissionSoftwareModel.fromJson(Map<String, dynamic> json) => PermissionSoftwareModel(
    softwareId: json['software_id'] ?? 0,
    softwareName: json['software_name'] ?? '',
    modules: (json['modules'] as List<dynamic>? ?? [])
        .map((e) => PermissionModuleModel.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

class PermissionsModel {
  final int userId;
  final String fullName;
  final bool isSuperadmin;
  final List<PermissionSoftwareModel> permissions;

  PermissionsModel({
    required this.userId,
    required this.fullName,
    required this.isSuperadmin,
    required this.permissions,
  });

  factory PermissionsModel.fromJson(Map<String, dynamic> json) => PermissionsModel(
    userId: json['user_id'] ?? 0,
    fullName: json['full_name'] ?? '',
    isSuperadmin: json['is_superadmin'] ?? false,
    permissions: (json['permissions'] as List<dynamic>? ?? [])
        .map((e) => PermissionSoftwareModel.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}
