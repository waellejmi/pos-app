import 'package:flutter/material.dart';

class FilterButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final Color color;
  final VoidCallback onPressed;

  const FilterButton({
    required this.label,
    required this.isActive,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isActive ? color : Colors.grey,
      ),
      child: Row(
        children: [
          Icon(
            isActive ? Icons.check : Icons.filter_list,
            color: Colors.white,
          ),
          SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }
}
