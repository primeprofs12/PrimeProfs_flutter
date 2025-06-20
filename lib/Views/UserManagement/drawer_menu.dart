import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../view_models/login_view_model.dart';

class DrawerMenu extends StatelessWidget {
  final List<Map<String, dynamic>> menuItems;
  final int selectedIndex;
  final Function(int) onItemTapped;
  final bool isProfessor;

  const DrawerMenu({
    super.key,
    required this.menuItems,
    required this.selectedIndex,
    required this.onItemTapped,
    required this.isProfessor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Drawer(
      backgroundColor: theme.scaffoldBackgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              children: [
                DrawerHeader(
                  child: Image.asset('assets/logo.png',
                      color: theme.brightness == Brightness.dark
                          ? Colors.white
                          : null),
                ),
                ...menuItems.map((item) => _buildListTile(
                      icon: item['icon'],
                      title: item['title'],
                      index: item['index'],
                      context: context,
                    )),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 8.0, bottom: 25),
              child: Consumer<LoginViewModel>(
                builder: (context, loginViewModel, child) {
                  return ListTile(
                    leading: Icon(Icons.logout, color: Colors.red),
                    title: Text(
                      'Déconnexion',
                      style: TextStyle(
                          color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                    onTap: () async {
                      await loginViewModel.logout();
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('isLoggedIn', false);
                      Navigator.of(context).pop(); // Ferme le drawer
                      Navigator.of(context)
                          .pushReplacementNamed('/'); // Retourne à LoginScreen
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Déconnecté avec succès')),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    required int index,
    required BuildContext context,
  }) {
    final theme = Theme.of(context);
    Color color = selectedIndex == index
        ? theme.primaryColor
        : theme.textTheme.bodyLarge?.color ?? Colors.black;

    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
      onTap: () => onItemTapped(index),
    );
  }
}
