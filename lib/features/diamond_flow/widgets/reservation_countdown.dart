import 'dart:async';
import 'package:flutter/material.dart';

class ReservationCountdown extends StatefulWidget {
  final DateTime createdAt;
  final Duration duration;
  final VoidCallback? onExpired;
  final bool compact;

  const ReservationCountdown({
    super.key,
    required this.createdAt,
    this.duration = const Duration(minutes: 30),
    this.onExpired,
    this.compact = false,
  });

  @override
  State<ReservationCountdown> createState() => _ReservationCountdownState();
}

class _ReservationCountdownState extends State<ReservationCountdown> {
  late Timer _timer;
  late Duration _remaining;
  bool _expired = false;

  @override
  void initState() {
    super.initState();
    _calculateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _calculateRemaining());
  }

  void _calculateRemaining() {
    final expiry = widget.createdAt.add(widget.duration);
    final now = DateTime.now();
    final diff = expiry.difference(now);

    if (diff.isNegative) {
      if (!_expired) {
        _expired = true;
        widget.onExpired?.call();
        _timer.cancel();
      }
      setState(() => _remaining = Duration.zero);
    } else {
      setState(() => _remaining = diff);
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final minutes = _remaining.inMinutes;
    final seconds = _remaining.inSeconds % 60;
    final progress = _remaining.inSeconds / widget.duration.inSeconds;
    final isActive = !_expired;

    final color = isActive ? const Color(0xFF3AC7FF) : const Color(0xFF5C2020);
    final bgColor = isActive
        ? const Color(0xFF3AC7FF).withValues(alpha: 0.15)
        : const Color(0xFF5C2020).withValues(alpha: 0.3);

    if (widget.compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 2,
                color: color,
                backgroundColor: color.withValues(alpha: 0.2),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              _expired ? 'Expired' : '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
              style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            height: 36,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 3,
                  color: color,
                  backgroundColor: color.withValues(alpha: 0.2),
                ),
                Text(
                  '${minutes.toString().padLeft(2, '0')}',
                  style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _expired ? 'Reservation Expired' : 'Reservation Active',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
                ),
                const SizedBox(height: 2),
                Text(
                  _expired ? 'Items may no longer be available' : 'Items reserved for ${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                  style: TextStyle(fontSize: 10, color: color.withValues(alpha: 0.7)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
