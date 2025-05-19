import 'package:flutter/material.dart';

class PaginationWidget extends StatelessWidget {
  final int currentPage;
  final int lastPage;
  final Function(int) onPageChanged;

  PaginationWidget({
    required this.currentPage,
    required this.lastPage,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final List<int> pageNumbers = List.generate(
      lastPage > 1 ? lastPage : 1,
      (index) => index + 1,
    );

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: Icon(Icons.chevron_left),
            onPressed:
                currentPage > 1 ? () => onPageChanged(currentPage - 1) : null,
          ),
          ...pageNumbers.map((pageNum) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: ElevatedButton(
                onPressed: () => onPageChanged(pageNum),
                child: Text('$pageNum'),
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(
                    pageNum == currentPage ? Color(0xFF2D71F8) : Colors.grey,
                  ),
                ),
              ),
            );
          }),
          IconButton(
            icon: Icon(Icons.chevron_right),
            onPressed: currentPage < lastPage
                ? () => onPageChanged(currentPage + 1)
                : null,
          ),
        ],
      ),
    );
  }
}
