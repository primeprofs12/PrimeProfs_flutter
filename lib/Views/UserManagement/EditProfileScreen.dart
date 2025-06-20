import 'package:flutter/material.dart';
import 'package:primeprof/view_models/EditProfileViewModel.dart';
import 'package:provider/provider.dart';

class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => EditProfileViewModel(),
      child: Consumer<EditProfileViewModel>(
        builder: (context, viewModel, _) => _buildScaffold(context, viewModel),
      ),
    );
  }

  Widget _buildScaffold(BuildContext context, EditProfileViewModel viewModel) {
    final theme = Theme.of(context);

    if (viewModel.isLoading && viewModel.user == null) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator(color: theme.colorScheme.primary)),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(),
        toolbarHeight: 0,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: viewModel.formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    Text(
                      'Modifier le profil',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Modifiez vos informations personnelles ci-dessous.',
                      style: TextStyle(
                        fontSize: 16,
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Profile image
                    Center(
                      child: Stack(
                        children: [
                          _buildProfileImageSection(context), // Pass context
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                shape: BoxShape.circle,
                                border: Border.all(color: theme.colorScheme.surface, width: 2),
                              ),
                              child: Icon(
                                Icons.edit,
                                color: theme.colorScheme.onPrimary,
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Form fields
                    _buildTextField(
                      context: context, // Pass context here
                      initialValue: viewModel.fullName ?? '',
                      label: 'Nom Complet',
                      icon: Icons.person_outline,
                      onChanged: viewModel.setFullName,
                      validator: (value) => value!.isEmpty ? 'Veuillez entrer un nom' : null,
                    ),

                    const SizedBox(height: 16),

                    _buildTextField(
                      context: context, // Pass context here
                      initialValue: viewModel.email ?? '',
                      label: 'Email',
                      icon: Icons.email_outlined,
                      onChanged: viewModel.setEmail,
                      validator: (value) => value!.isEmpty || !value.contains('@')
                          ? 'Veuillez entrer un email valide'
                          : null,
                      keyboardType: TextInputType.emailAddress,
                    ),

                    const SizedBox(height: 16),

                    _buildTextField(
                      context: context, // Pass context here
                      initialValue: viewModel.age?.toString() ?? '',
                      label: 'Âge',
                      icon: Icons.cake_outlined,
                      onChanged: (value) => viewModel.setAge(int.tryParse(value)),
                      validator: (value) {
                        if (value!.isEmpty) return 'Veuillez entrer un âge';
                        final age = int.tryParse(value);
                        if (age == null || age < 0) return 'Âge invalide';
                        return null;
                      },
                      keyboardType: TextInputType.number,
                    ),

                    const SizedBox(height: 16),

                    _buildTextField(
                      context: context, // Pass context here
                      initialValue: viewModel.grade ?? '',
                      label: 'Classe',
                      icon: Icons.school_outlined,
                      onChanged: viewModel.setGrade,
                      validator: (value) => value!.isEmpty ? 'Veuillez entrer une classe' : null,
                    ),

                    if (viewModel.errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        viewModel.errorMessage!,
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ],

                    const SizedBox(height: 40),

                    // Save button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: viewModel.isLoading
                            ? null
                            : () async {
                                if (viewModel.formKey.currentState!.validate()) {
                                  final success = await viewModel.saveProfile();
                                  if (success && context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Profil mis à jour avec succès',
                                          style: TextStyle(color: theme.colorScheme.onSurface),
                                        ),
                                        backgroundColor: theme.colorScheme.surface,
                                      ),
                                    );
                                    Navigator.pop(context);
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: viewModel.isLoading
                            ? CircularProgressIndicator(color: theme.colorScheme.onPrimary)
                            : Text(
                                'Enregistrer',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onPrimary,
                                ),
                              ),
                      ),
                    ),

                    // Add extra space at the bottom for the back button
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),

            // Back button - positioned lower
            Positioned(
              left: 20,
              bottom: 20,
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(Icons.arrow_back, color: theme.colorScheme.onPrimary),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileImageSection(BuildContext context) {
    final theme = Theme.of(context);
    const staticImageUrl = 'https://example.com/static-profile-picture.jpg';
    return CircleAvatar(
      radius: 50,
      backgroundColor: theme.colorScheme.surfaceVariant,
      child: ClipOval(
        child: Image.network(
          staticImageUrl,
          width: 100,
          height: 100,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Icon(
            Icons.person,
            size: 50,
            color: theme.colorScheme.onSurface.withOpacity(0.4),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required BuildContext context, // Add context as a required parameter
    required String initialValue,
    required String label,
    required IconData icon,
    required Function(String) onChanged,
    required String? Function(String?) validator,
    TextInputType keyboardType = TextInputType.text,
  }) {
    final theme = Theme.of(context);
    return TextFormField(
      initialValue: initialValue,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: label,
        hintStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.4)),
        filled: true,
        fillColor: theme.colorScheme.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        prefixIcon: Icon(icon, color: theme.colorScheme.primary),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        errorStyle: TextStyle(color: theme.colorScheme.error),
      ),
      onChanged: onChanged,
      validator: validator,
      style: TextStyle(color: theme.colorScheme.onSurface),
    );
  }
}