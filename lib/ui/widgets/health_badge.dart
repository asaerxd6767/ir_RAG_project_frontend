import 'package:material_ui/material_ui.dart';

import '../../state/ask_controller.dart';

class HealthBadge extends StatelessWidget {
  const HealthBadge({
    super.key,
    required this.controller,
    required this.onRefresh,
  });

  final AskController controller;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final checking = controller.isCheckingHealth;
    final online = controller.isBackendHealthy;
    final label = checking ? 'Checking…' : online ? 'Backend online' : 'Backend offline';
    final color = checking ? scheme.outline : online ? scheme.primary : scheme.error;

    return Tooltip(
      message: controller.healthError ?? 'Tap to re-check the backend connection',
      child: InkWell(
        onTap: onRefresh,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: color.withValues(alpha: 0.35)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (checking)
                SizedBox(
                  width: 11,
                  height: 11,
                  child: CircularProgressIndicator(strokeWidth: 2, color: color),
                )
              else
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 4),
              Icon(Icons.refresh_rounded, size: 15, color: color),
            ],
          ),
        ),
      ),
    );
  }
}
