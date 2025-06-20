import 'package:flutter/material.dart';
import '../../view_models/verify_otp_view_model.dart';
import 'ChangePasswordScreen.dart';

class VerificationCodeScreen extends StatefulWidget {
  const VerificationCodeScreen({super.key});

  @override
  _VerificationCodeScreenState createState() => _VerificationCodeScreenState();
}

class _VerificationCodeScreenState extends State<VerificationCodeScreen> {
  final TextEditingController _codeController = TextEditingController();
  final OtpVerificationViewModel _viewModel =
      OtpVerificationViewModel(); // Instantiate the ViewModel
  String _message = ''; // To display error messages

  Future<void> _verifyOtp(BuildContext context) async {
    try {
      final otp = _codeController.text.trim();
      if (otp.isEmpty) {
        setState(() {
          _message = 'Veuillez entrer le code de vérification.';
        });
        return;
      }

      // Call the ViewModel to verify the OTP
      final response = await _viewModel.verifyOtp(otp);

      // Show success popup
      _showSuccessPopup(context, response.message);
    } catch (e) {
      // Handle errors
      setState(() {
        _message = 'Erreur: $e';
      });
    }
  }

  void _showSuccessPopup(BuildContext context, String message) {
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
            const Color(0xFF45ECCC),
            Icons.check_circle_outline,
            () {
              Navigator.pop(context); // Close the popup
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ChangePasswordScreen()),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildPopupContent(
      String message, Color color, IconData icon, VoidCallback onPressed) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
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
            child:
                Text('OK', style: TextStyle(fontSize: 18, color: Colors.white)),
          ),
        ],
      ),
    );
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
                  'Vérification du code',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Entrez le code que vous avez reçu par e-mail pour continuer.',
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                TextField(
                  controller: _codeController,
                  decoration: InputDecoration(
                    labelText: 'Entrer le code',
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
                if (_message.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      _message,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () {
                    _verifyOtp(context); // Call the OTP verification method
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF748FFF),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  child: Text(
                    'Valider',
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
