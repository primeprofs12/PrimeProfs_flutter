import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../view_models/forgot_password_view_model.dart';
import 'VerificationCodeScreen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  // Create the TextEditingController here
  final TextEditingController _emailController = TextEditingController();

  @override
  void dispose() {
    // Dispose of the controller when the widget is removed from the widget tree
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FF),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFFF7F8FF),
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
                const Text(
                  'Mot de passe oublié ?',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Veuillez entrer l\'adresse mail associée à votre compte. Nous vous enverrons un lien pour réinitialiser votre mot de passe.',
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                TextField(
                  controller: _emailController, // Use the controller here
                  decoration: InputDecoration(
                    labelText: 'Entrer email',
                    labelStyle: const TextStyle(color: Color(0xFFBDBDBD)),
                    border: OutlineInputBorder(
                      borderSide: const BorderSide(color: Color(0xFF748FFF)),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Color(0xFF748FFF)),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Color(0xFF748FFF)),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () async {
                    final viewModel =
                        Provider.of<ForgotPasswordViewModel>(context, listen: false);
                    final response = await viewModel.forgotPassword(_emailController.text);
                    if (response != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(response.message)),
                      );
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => VerificationCodeScreen()),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Failed to send forgot password request')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF748FFF),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  child: Text(
                    'Réinitialiser le mot de passe',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 20,
            left: 20,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF748FFF),
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(12),
                child: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
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