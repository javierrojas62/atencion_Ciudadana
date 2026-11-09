import 'package:flutter/material.dart';

// Aviso para las pantallas que todavía no están terminadas
class EnConstruccion extends StatelessWidget {
  const EnConstruccion({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.construction, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'En construcción',
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}
