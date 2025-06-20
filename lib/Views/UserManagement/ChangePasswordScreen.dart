import 'package:flutter/material.dart';
import '../../view_models/change_password_view_model.dart';
import 'login_screen.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  _ChangePasswordScreenState createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  final ChangePasswordViewModel _viewModel = ChangePasswordViewModel();

  void _validateAndSave() async {
    String password = _passwordController.text.trim();
    String confirmPassword = _confirmPasswordController.text.trim();
    if (password.isEmpty || confirmPassword.isEmpty) {
      _showErrorPopup("Veuillez remplir tous les champs.");
      return;
    }
    if (password.length < 6) {
      _showErrorPopup("Le mot de passe doit contenir au moins 6 caractères.");
      return;
    }
    if (password != confirmPassword) {
      _showErrorPopup("Les mots de passe ne correspondent pas.");
      return;
    }

    try {
      final response = await _viewModel.changePassword('7', password); // Replace '7' with actual user ID
      _showSuccessPopup(response.message);
    } catch (e) {
      setState(() {
      });
    }
  }

  void _showSuccessPopup(String message) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: _buildPopupContent(
            message,
            theme.colorScheme.secondary, // Using secondary for success
            Icons.check_circle_outline,
            () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
              );
            },
          ),
        );
      },
    );
  }

  void _showErrorPopup(String errorMessage) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: _buildPopupContent(
            errorMessage,
            theme.colorScheme.error,
            Icons.error_outline,
            () => Navigator.pop(context),
          ),
        );
      },
    );
  }

  Widget _buildPopupContent(String message, Color color, IconData icon, VoidCallback onPressed) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.2),
            blurRadius: 10,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: 50,
          ),
          const SizedBox(height: 15),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'OK',
              style: TextStyle(fontSize: 18, color: theme.colorScheme.onPrimary),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: theme.appBarTheme.backgroundColor ?? theme.colorScheme.surface,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                Text(
                  'Changer le mot de passe',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Text(
                  'Entrez votre nouveau mot de passe et confirmez-le pour finaliser la réinitialisation.',
                  style: TextStyle(
                    fontSize: 16,
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),

                // Password Field
                TextField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  decoration: InputDecoration(
                    labelText: 'Nouveau mot de passe',
                    labelStyle: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.5)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: BorderSide(color: theme.dividerColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: BorderSide(color: theme.dividerColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: BorderSide(color: theme.colorScheme.primary),
                    ),
                    fillColor: theme.colorScheme.surface,
                    filled: true,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                  ),
                  style: TextStyle(color: theme.colorScheme.onSurface),
                ),
                const SizedBox(height: 20),

                // Confirm Password Field
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: !_isConfirmPasswordVisible,
                  decoration: InputDecoration(
                    labelText: 'Confirmer le mot de passe',
                    labelStyle: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.5)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: BorderSide(color: theme.dividerColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: BorderSide(color: theme.dividerColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: BorderSide(color: theme.colorScheme.primary),
                    ),
                    fillColor: theme.colorScheme.surface,
                    filled: true,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isConfirmPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                      onPressed: () {
                        setState(() {
                          _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                        });
                      },
                    ),
                  ),
                  style: TextStyle(color: theme.colorScheme.onSurface),
                ),
                const SizedBox(height: 30),

                // Save Button
                ElevatedButton(
                  onPressed: _validateAndSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  child: Text(
                    'Enregistrer',
                    style: TextStyle(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Back Button
          Positioned(
            bottom: 20,
            left: 20,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(12),
                child: Icon(
                  Icons.arrow_back,
                  color: theme.colorScheme.onPrimary,
                  size: 35,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}