import 'package:flutter/material.dart';
import 'package:primeprof/Views/etudiant/StudentScreen.dart';

// Premier écran : Sélection du pack
class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String selectedPack = '4H';
  double selectedPrice = 40.0;

  final List<Map<String, dynamic>> packs = [
    {'label': '4H', 'price': 40, 'hours': 4},
    {'label': '15H', 'price': 120, 'hours': 15},
    {'label': '25H', 'price': 200, 'hours': 25},
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Choisir un pack', style: TextStyle(color: theme.colorScheme.primary)),
        backgroundColor: theme.appBarTheme.backgroundColor ?? theme.colorScheme.surface,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Commander un pack',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: packs.map((pack) {
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: GestureDetector(
                    onTap: () => setState(() {
                      selectedPack = pack['label'];
                      selectedPrice = pack['price'].toDouble();
                    }),
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: theme.shadowColor.withOpacity(
                                selectedPack == pack['label'] ? 0.3 : 0.2),
                            spreadRadius: 2,
                            blurRadius: 5,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            pack['label'],
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: selectedPack == pack['label']
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            '\$${pack['price']}',
                            style: TextStyle(
                              fontSize: 14,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PaymentMethodScreen(
                      selectedPack: selectedPack,
                      selectedPrice: selectedPrice,
                      hours: packs.firstWhere((pack) => pack['label'] == selectedPack)['hours'],
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                backgroundColor: theme.colorScheme.primary,
              ),
              child: Text(
                'Continuer',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Deuxième écran : Choix du mode de paiement
class PaymentMethodScreen extends StatefulWidget {
  final String selectedPack;
  final double selectedPrice;
  final int hours;

  const PaymentMethodScreen({
    super.key,
    required this.selectedPack,
    required this.selectedPrice,
    required this.hours,
  });

  @override
  _PaymentMethodScreenState createState() => _PaymentMethodScreenState();
}

class _PaymentMethodScreenState extends State<PaymentMethodScreen> {
  String selectedPaymentMethod = 'PayPal';
  final TextEditingController emailController = TextEditingController();
  final TextEditingController cardNumberController = TextEditingController();
  final TextEditingController expiryDateController = TextEditingController();
  final TextEditingController cvvController = TextEditingController();
  bool isConfirmed = false;

  @override
  void dispose() {
    emailController.dispose();
    cardNumberController.dispose();
    expiryDateController.dispose();
    cvvController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Mode de paiement', style: TextStyle(color: theme.colorScheme.primary)),
        backgroundColor: theme.appBarTheme.backgroundColor ?? theme.colorScheme.surface,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Pack sélectionné: ${widget.selectedPack} (\$${widget.selectedPrice})',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Veuillez choisir le mode de paiement :',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              SizedBox(height: 10),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: theme.shadowColor.withOpacity(0.2),
                      spreadRadius: 1,
                      blurRadius: 5,
                    ),
                  ],
                ),
                child: DropdownButtonFormField(
                  value: selectedPaymentMethod,
                  items: ['PayPal', 'Visa Card'].map((method) {
                    return DropdownMenuItem(
                      value: method,
                      child: Text(method, style: TextStyle(color: theme.colorScheme.onSurface)),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => selectedPaymentMethod = value!),
                  decoration: InputDecoration(border: InputBorder.none),
                  dropdownColor: theme.colorScheme.surface,
                ),
              ),
              SizedBox(height: 20),
              if (selectedPaymentMethod == 'PayPal')
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: 'Adresse e-mail PayPal',
                    labelStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: theme.dividerColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: theme.colorScheme.primary),
                    ),
                  ),
                  style: TextStyle(color: theme.colorScheme.onSurface),
                )
              else
                Column(
                  children: [
                    TextField(
                      controller: cardNumberController,
                      decoration: InputDecoration(
                        labelText: 'Numéro de carte',
                        labelStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: theme.dividerColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: theme.colorScheme.primary),
                        ),
                      ),
                      style: TextStyle(color: theme.colorScheme.onSurface),
                    ),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: expiryDateController,
                            decoration: InputDecoration(
                              labelText: 'Date d\'expiration (MM/YY)',
                              labelStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: theme.dividerColor),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: theme.colorScheme.primary),
                              ),
                            ),
                            style: TextStyle(color: theme.colorScheme.onSurface),
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: cvvController,
                            decoration: InputDecoration(
                              labelText: 'CVV',
                              labelStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: theme.dividerColor),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: theme.colorScheme.primary),
                              ),
                            ),
                            style: TextStyle(color: theme.colorScheme.onSurface),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              SizedBox(height: 20),
              Row(
                children: [
                  Checkbox(
                    value: isConfirmed,
                    onChanged: (value) => setState(() => isConfirmed = value!),
                    activeColor: theme.colorScheme.primary,
                  ),
                  Flexible(
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'J\'accepte les ',
                            style: TextStyle(color: theme.colorScheme.onSurface),
                          ),
                          TextSpan(
                            text: 'conditions générales',
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                          TextSpan(
                            text: ' et la ',
                            style: TextStyle(color: theme.colorScheme.onSurface),
                          ),
                          TextSpan(
                            text: 'politique de confidentialité.',
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              ElevatedButton(
  onPressed: isConfirmed
      ? () async {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Paiement réussi!')),
          );

          // Naviguer vers EtudiantScreen avec les heures ajoutées
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const EtudiantScreen(),
              settings: RouteSettings(
                arguments: {'hoursAdded': widget.hours},
              ),
            ),
          );
        }
      : null,
  style: ElevatedButton.styleFrom(
    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
    backgroundColor: theme.colorScheme.primary,
  ),
  child: Text(
    'Payer',
    style: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.bold,
      color: theme.colorScheme.onPrimary,
    ),
  ),
),
            ],
          ),
        ),
      ),
    );
  }
}