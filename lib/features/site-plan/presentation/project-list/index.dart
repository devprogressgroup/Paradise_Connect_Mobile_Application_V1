import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:progress_group/features/auth/presentation/state/auth/auth_bloc.dart';
import 'package:progress_group/features/auth/presentation/state/auth/auth_event.dart';

import '../../../../core/utils/widget/custom_header.dart';
import '../../domain/entities/project_site.dart';
import '../state/siteplan_bloc.dart';
import '../state/siteplan_event.dart';
import '../state/siteplan_state.dart';
import 'package:progress_group/core/constants/colors.dart';

class ProjectListPage extends StatelessWidget {
  final List<ProjectSite> sites;
  final ProjectSite? selectedSite;
  const ProjectListPage({super.key, required this.sites, this.selectedSite});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SiteplanBloc, SiteplanState>(
      builder: (context, state) {
        final currentSites = state is SiteplanLoaded ? state.sites : sites;
        final isLoading = state is SiteplanLoading;

        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                customHeader(context, "Site Plan", isBack: true),
                const SizedBox(height: 16),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      context.read<AuthBloc>().add(FetchPermissionsEvent());
                      context.read<SiteplanBloc>().add(LoadSiteplanEvent());
                      await context.read<SiteplanBloc>().stream
                          .firstWhere((s) => s is SiteplanLoaded || s is SiteplanError);
                    },
                    child: isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : currentSites.isEmpty
                            ? const Center(
                                child: Text(
                                  'Tidak ada data site plan',
                                  style: TextStyle(color: Color(greyShade500)),
                                ),
                              )
                            : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(16),
                            itemCount: currentSites.length,
                            itemBuilder: (context, index) {
                              final site = currentSites[index];
                              final showHeader = index == 0 ||
                                  currentSites[index - 1].groupName != site.groupName;

                              final isSelected =
                                  selectedSite?.unitName == site.unitName &&
                                  selectedSite?.groupName == site.groupName;

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (showHeader) ...[
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                        site.groupName.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Color(blueShade900Color),
                                        ),
                                      ),
                                    ),
                                  ],
                                  ListTile(
                                    title: Text(
                                      site.unitName,
                                      style: TextStyle(
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        color: isSelected
                                            ? Color(blueShade800Color)
                                            : null,
                                      ),
                                    ),
                                    tileColor: isSelected
                                        ? Color(blueShade50Color)
                                        : null,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    onTap: () => context.pop(site),
                                  ),
                                ],
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
