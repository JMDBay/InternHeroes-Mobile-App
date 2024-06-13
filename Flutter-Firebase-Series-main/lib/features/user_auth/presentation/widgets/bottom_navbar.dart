import 'package:flutter/material.dart';

class BottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final void Function(int) onItemTapped;

  const BottomNavBar({
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            icon: Icon(Icons.book, color: selectedIndex == 0 ? Colors.orange : Colors.grey),
            onPressed: () => onItemTapped(0),
          ),
          IconButton(
            icon: Icon(Icons.message, color: selectedIndex == 1 ? Colors.orange : Colors.grey),
            onPressed: () => onItemTapped(1),
          ),
          IconButton(
            icon: Icon(Icons.add, color: selectedIndex == 2 ? Colors.orange : Colors.grey),
            onPressed: () => onItemTapped(2),
          ),
          IconButton(
            icon: Icon(Icons.calendar_today, color: selectedIndex == 3 ? Colors.orange : Colors.grey),
            onPressed: () => onItemTapped(3),
          ),
          IconButton(
            icon: Icon(Icons.account_circle, color: selectedIndex == 4 ? Colors.orange : Colors.grey),
            onPressed: () => onItemTapped(4),
          ),
        ],
      ),
    );
  }
}
