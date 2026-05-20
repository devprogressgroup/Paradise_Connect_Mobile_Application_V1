import '../../domain/entities/project_site.dart';

abstract class SiteplanState {}

class SiteplanInitial extends SiteplanState {}

class SiteplanLoading extends SiteplanState {}

class SiteplanLoaded extends SiteplanState {
  final List<ProjectSite> sites;
  SiteplanLoaded(this.sites);
}

class SiteplanError extends SiteplanState {
  final String message;
  SiteplanError(this.message);
}
