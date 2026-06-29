import 'package:flutter/material.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:progress_group/core/network/api_constants.dart';

const _envColors = {
  AppEnvironment.production: Color(primaryColor),
  AppEnvironment.development: Color(0xFF22C55E),
  AppEnvironment.development2: Color(0xFFF59E0B),
  AppEnvironment.developmnetDomain: Color(0xFF8B5CF6),
};

void showEnvSwitcher(BuildContext context) {
  final available = ApiConstants.availableEnvironments;
  if (available.length == 1 && available.contains(AppEnvironment.production)) return;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      final screenHeight = MediaQuery.of(ctx).size.height;
      return ValueListenableBuilder<AppEnvironment>(
        valueListenable: ApiConstants.envNotifier,
        builder: (_, currentEnv, __) {
          final available = ApiConstants.availableEnvironments;
          final options = _envColors.entries.where((e) => available.contains(e.key)).toList();
          return ConstrainedBox(
            constraints: BoxConstraints(minHeight: screenHeight * 0.45),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pilih Environment',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  ...options.map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _EnvOption(
                          ctx: ctx,
                          env: e.key,
                          label: ApiConstants.labelFor(e.key),
                          subtitle: ApiConstants.baseUrlFor(e.key),
                          color: e.value,
                          currentEnv: currentEnv,
                        ),
                      )),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

class _EnvOption extends StatelessWidget {
  const _EnvOption({
    required this.ctx,
    required this.env,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.currentEnv,
  });

  final BuildContext ctx;
  final AppEnvironment env;
  final String label;
  final String subtitle;
  final Color color;
  final AppEnvironment currentEnv;

  @override
  Widget build(BuildContext context) {
    final isSelected = currentEnv == env;
    return GestureDetector(
      onTap: () async {
        Navigator.pop(ctx);
        if (currentEnv != env) {
          await ApiConstants.switchEnv(env);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.08) : Colors.grey.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: isSelected ? color : Colors.black87)),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
            ),
            if (isSelected) Icon(Icons.check_circle, color: color, size: 20),
          ],
        ),
      ),
    );
  }
}
