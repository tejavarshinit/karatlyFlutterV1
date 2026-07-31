import 'package:flutter/material.dart';
import '../../app/theme.dart';

/// Feature chip matching reference FeatureChip component.
class FeatureChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String metalType;

  const FeatureChip({
    super.key,
    required this.icon,
    required this.label,
    this.metalType = 'gold',
  });

  @override
  Widget build(BuildContext context) {
    final isSilver = metalType == 'silver';
    final isDiamond = metalType == 'diamond';

    final iconColor = isSilver
        ? const Color(0xFF9E9E9E)
        : isDiamond
            ? const Color(0xFF4593F9)
            : const Color(0xFFB57F23);

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(39),
        border: Border.all(color: const Color(0xFF3E3E3E)),
        color: const Color(0xFF16140F),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10,
                height: 15 / 10,
                color: Color(0xFF5E5E5E),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
