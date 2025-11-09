import 'package:flutter/material.dart';
import '../models/word_status.dart';

class StatusActionButtons extends StatelessWidget {
  final VoidCallback? onEasyPressed;
  final VoidCallback? onHesitantPressed;
  final VoidCallback? onDifficultPressed;

  const StatusActionButtons({
    Key? key,
    this.onEasyPressed,
    this.onHesitantPressed,
    this.onDifficultPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 24,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStatusButton(
              label: '简单',
              color: 0xFF4CAF50,
              onPressed: onEasyPressed,
              icon: Icons.check_circle,
            ),
            _buildStatusButton(
              label: '犹豫',
              color: 0xFFFFEB3B,
              onPressed: onHesitantPressed,
              icon: Icons.help_outline,
            ),
            _buildStatusButton(
              label: '困难',
              color: 0xFFF44336,
              onPressed: onDifficultPressed,
              icon: Icons.cancel,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusButton({
    required String label,
    required int color,
    required VoidCallback? onPressed,
    required IconData icon,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 6),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          decoration: BoxDecoration(
            color: Color(color).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Color(color).withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Color(color), size: 24),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: Color(color),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
