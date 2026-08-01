import 'package:flutter/material.dart';

class StepIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const StepIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalSteps, (index) {
        final stepNumber = index + 1;
        final isActive = stepNumber == currentStep;
        final isCompleted = stepNumber < currentStep;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isActive
                    ? const LinearGradient(colors: [Color(0xFFF7CD57), Color(0xFFB57F23)])
                    : isCompleted
                        ? null
                        : null,
                color: isCompleted ? const Color(0xFF3D3B37) : null,
                border: isActive || isCompleted
                    ? null
                    : Border.all(color: const Color(0xFF3D3B37)),
                boxShadow: isActive
                    ? [
                        const BoxShadow(
                          color: Color(0x66F7CD57),
                          blurRadius: 10,
                          spreadRadius: 0,
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  '$stepNumber',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isActive || isCompleted ? Colors.black : const Color(0xFF9E9A94),
                  ),
                ),
              ),
            ),
            if (index < totalSteps - 1)
              Container(
                width: 32,
                height: 4,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: isCompleted ? const Color(0xFFF7CD57) : const Color(0xFF2E2D2A),
                ),
              ),
          ],
        );
      }),
    );
  }
}
