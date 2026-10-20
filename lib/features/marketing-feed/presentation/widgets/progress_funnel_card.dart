import 'dart:math';

import 'package:flutter/material.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/personal_funnel_entity.dart';
import 'package:progress_group/features/marketing-feed/presentation/widgets/feed_section.dart';

/// Section "Progress Kamu": bar funnel pribadi bulan berjalan.
class ProgressFunnelCard extends StatelessWidget {
  final PersonalFunnelEntity? funnel;
  final VoidCallback? onOpenReport;

  const ProgressFunnelCard({super.key, required this.funnel, this.onOpenReport});

  static const double _barMaxHeight = 64;

  @override
  Widget build(BuildContext context) {
    final data = funnel;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FeedSectionHeader(
          title: 'Progress Kamu',
          hint: data == null ? null : 'Funnel pribadi ${data.periodLabel}, update tiap hari',
          actionLabel: 'Lihat Report',
          onAction: onOpenReport,
        ),
        const SizedBox(height: 8),
        FeedCard(
          child: SizedBox(
            // Bar maks 64 + angka & label — muat sampai text scale 1.15 (batas di main.dart).
            height: 112,
            child: data == null
                ? const Center(
                    child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (var i = 0; i < data.stages.length; i++) ...[
                        if (i > 0) const SizedBox(width: 10),
                        Expanded(child: _buildBar(data.stages[i], data.maxCount)),
                      ],
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildBar(FunnelStageEntity stage, int maxCount) {
    final height = maxCount == 0 ? 6.0 : max(6.0, stage.count / maxCount * _barMaxHeight);
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text('${stage.count}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Container(
          height: height,
          decoration: const BoxDecoration(
            color: Color(primaryColor),
            borderRadius: BorderRadius.vertical(top: Radius.circular(6), bottom: Radius.circular(2)),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          stage.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(grey2Color)),
        ),
      ],
    );
  }
}
