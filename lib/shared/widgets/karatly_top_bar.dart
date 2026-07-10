import 'package:flutter/material.dart';

class KaratlyTopBar extends StatelessWidget {
  final String title;
  final Widget? rightAction;
  final bool showBack;
  final VoidCallback? onBack;

  const KaratlyTopBar({
    super.key,
    required this.title,
    this.rightAction,
    this.showBack = true,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: showBack
                ? GestureDetector(
                    onTap: onBack ?? () => Navigator.of(context).pop(),
                    child: Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.centerLeft,
                      child: const Icon(Icons.chevron_left, size: 28, color: Colors.white),
                    ),
                  )
                : null,
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Georgia',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
          SizedBox(
            width: 40,
            child: rightAction != null ? Align(alignment: Alignment.centerRight, child: rightAction!) : null,
          ),
        ],
      ),
    );
  }
}
