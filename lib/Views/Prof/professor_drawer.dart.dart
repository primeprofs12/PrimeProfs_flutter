import 'package:flutter/material.dart';
import '../UserManagement/drawer_menu.dart';
import '../UserManagement/menu_items.dart';


class ProfessorDrawer extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const ProfessorDrawer({super.key, required this.selectedIndex, required this.onItemTapped});

  @override
  Widget build(BuildContext context) {
    return DrawerMenu(
      menuItems: professorMenuItems,
      selectedIndex: selectedIndex,
      onItemTapped: onItemTapped,
      isProfessor: true,
    );
  }
}