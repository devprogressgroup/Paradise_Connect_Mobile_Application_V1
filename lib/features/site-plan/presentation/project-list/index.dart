import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/widget/custom_header.dart';
import '../../domain/entities/project_site.dart';
import '../state/siteplan_bloc.dart';
import '../state/siteplan_event.dart';
import '../state/siteplan_state.dart';

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
                      context.read<SiteplanBloc>().add(LoadSiteplanEvent());
                      await context.read<SiteplanBloc>().stream
                          .firstWhere((s) => s is SiteplanLoaded || s is SiteplanError);
                    },
                    child: isLoading
                        ? const Center(child: CircularProgressIndicator())
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
                                          color: Colors.blue.shade900,
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
                                            ? Colors.blue.shade800
                                            : null,
                                      ),
                                    ),
                                    tileColor: isSelected
                                        ? Colors.blue.shade50
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
