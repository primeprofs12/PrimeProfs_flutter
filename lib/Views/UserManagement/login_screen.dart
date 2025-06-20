import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../view_models/login_view_model.dart';
import '../Prof/ProfScreen.dart';
import '../etudiant/StudentScreen.dart';
import 'ForgotPasswordScreen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String errorMessage = '';
  bool isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// 🔹 **Sauvegarde le token et le rôle utilisateur dans les préférences**
  Future<void> _saveSession(String token, String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('accessToken', token);
    await prefs.setString('role', role);
    await prefs.setBool('isLoggedIn', true);
  }

  /// 🔹 **Redirige l'utilisateur vers l'écran correspondant à son rôle**
  void _navigateToHome(String role) {
    if (role == 'teacher') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ProfScreen()),
      );
    } else if (role == 'student') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const EtudiantScreen()),
      );
    } else {
      debugPrint('Rôle non reconnu: $role');
      // Optionally, you can handle this case (e.g., show an error screen)
    }
  }

  /// 🔹 **Vérifie les champs avant l'envoi**
  bool _validateInputs() {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() => errorMessage = 'Veuillez remplir tous les champs.');
      return false;
    }
    return true;
  }

  /// 🔹 **Gestion de la connexion utilisateur**
  Future<void> _login() async {
    if (!_validateInputs()) return;

    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    final viewModel = Provider.of<LoginViewModel>(context, listen: false);
    final authResponse = await viewModel.login(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    if (authResponse != null) {
      final isExpired = await viewModel.isSessionExpired();
      if (isExpired) {
        setState(
            () => errorMessage = 'Session expirée. Veuillez vous reconnecter.');
      } else {
        final role = await SharedPreferences.getInstance()
            .then((prefs) => prefs.getString('role'));
        if (role == 'teacher' || role == 'student') {
          await _saveSession(authResponse.accessToken,
              role!); // Assurez-vous que le rôle existe
          _navigateToHome(role);
        } else {
          setState(() => errorMessage = 'Rôle utilisateur invalide.');
        }
      }
    } else {
      setState(() =>
          errorMessage = 'Échec de la connexion. Vérifiez vos informations.');
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FF),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 60),
            Center(
              child: Image.asset(
                'assets/logo.png',
                width: 230,
                height: 230,
              ),
            ),
            const SizedBox(height: 30),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Entrer email',
                labelStyle: const TextStyle(color: Color(0xFFBDBDBD)),
                border: OutlineInputBorder(
                  borderSide: const BorderSide(color: Color(0xFF748FFF)),
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Entrer mot de passe',
                labelStyle: const TextStyle(color: Color(0xFFBDBDBD)),
                border: OutlineInputBorder(
                  borderSide: const BorderSide(color: Color(0xFF748FFF)),
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => ForgotPasswordScreen()),
                  );
                },
                child: const Text(
                  'Mot de passe oublié ?',
                  style: TextStyle(color: Color(0xFF748FFF)),
                ),
              ),
            ),
            const SizedBox(height: 20),
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF748FFF),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text('Se connecter',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    )),
                  ),
            const SizedBox(height: 20),
            if (errorMessage.isNotEmpty)
              Text(
                errorMessage,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }
}
