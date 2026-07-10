import 'package:flutter/material.dart';
import '../../app/theme.dart';

/// Step rail indicator matching reference StepRail component.
/// Shows a progress bar and label for each step.
class StepRail extends StatelessWidget {
  final String label;
  final bool active;
  final String metalType;

  const StepRail({
    super.key,
    required this.label,
    this.active = false,
    this.metalType = 'gold',
  });

  @override
  Widget build(BuildContext context) {
    final isSilver = metalType == 'silver';
    final isDiamond = metalType == 'diamond';

    final barColor = active
        ? (isSilver
            ? const LinearGradient(
                colors: [Color(0xFFFFFFFF), Color(0xFF999999)])
            : isDiamond
                ? const LinearGradient(
                    colors: [Color(0xFF0073CE), Color(0xFF003E6F)])
                : const LinearGradient(
                    colors: [Color(0xFFFFE9AA), Color(0xFFF7CD57), Color(0xFFCA9B14)],
                    stops: [0, 0.5, 1],
                  ))
        : null;

    final textColor = active
        ? (isSilver
            ? Colors.white
            : isDiamond
                ? const Color(0xFF4593F9)
                : AppTheme.gold)
        : const Color(0xFF515151);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 5,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: barColor,
            color: barColor == null ? const Color(0xFF3E3E3E) : null,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            height: 18 / 12,
            color: textColor,
          ),
        ),
      ],
    );
  }
}
