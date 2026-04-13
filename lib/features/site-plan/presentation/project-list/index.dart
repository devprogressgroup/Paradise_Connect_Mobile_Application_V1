import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/widget/custom_header.dart';
import '../../domain/entities/project_site.dart';

class ProjectListPage extends StatelessWidget {
  final List<ProjectSite> sites;
  const ProjectListPage({super.key, required this.sites});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            customHeader(context, "Site Plan", isBack: true),
            SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: sites.length,
                itemBuilder: (context, index) {
                  final site = sites[index];
                  bool showHeader = index == 0 || sites[index - 1].groupName != site.groupName;
              
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (showHeader) ...[
                        Text(site.groupName.toUpperCase(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue.shade900)),
                      ],
                      ListTile(
                        title: Text(site.unitName),
                        onTap: () => context.pop(site), // MENGIRIM DATA KEMBALI
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}