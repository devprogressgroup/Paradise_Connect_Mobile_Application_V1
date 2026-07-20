import 'package:flutter/material.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:progress_group/core/network/api_constants.dart';

const _envBannerColors = {
  AppEnvironment.development: Color(0xFF22C55E),
  AppEnvironment.development2: Color(0xFFF59E0B),
  AppEnvironment.developmnetDomain: Color(0xFF8B5CF6),
};

/// Banner status environment — mirip [ImpersonationBanner], nempel di atas.
/// Tidak muncul saat environment production.
class EnvironmentBanner extends StatelessWidget {
  const EnvironmentBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppEnvironment>(
      valueListenable: ApiConstants.envNotifier,
      builder: (context, env, _) {
        if (env == AppEnvironment.production) return const SizedBox.shrink();
        final color = _envBannerColors[env] ?? const Color(0xFF22C55E);
        return Material(
          color: color,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 8, 6),
              child: Row(
                children: [
                  const Icon(Icons.dns_outlined, color: Color(whiteColor), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Environment: ${ApiConstants.labelFor(env)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(whiteColor),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
