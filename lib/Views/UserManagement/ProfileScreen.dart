import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:primeprof/Views/UserManagement/ChangePasswordScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:clipboard/clipboard.dart';
import '../../view_models/profile_view_model.dart';
import '../../view_models/login_view_model.dart';
import '../../view_models/EditProfileViewModel.dart';

class ProfileScreen extends StatefulWidget {
  final String role;
  const ProfileScreen({super.key, required this.role});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isEditing = false;
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _faqQuestionController;

  String _displayName = '';
  String _displayEmail = '';
  String? _profileImageUrl;

  final ProfileViewModel _profileViewModel = ProfileViewModel();
  final LoginViewModel _loginViewModel = LoginViewModel();
  final EditProfileViewModel _editProfileViewModel = EditProfileViewModel();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _faqQuestionController = TextEditingController();

    _nameController.addListener(_updateDisplayName);
    _emailController.addListener(_updateDisplayEmail);

    _loadUserData();
  }

  void _updateDisplayName() {
    setState(() {
      _displayName = _nameController.text;
    });
  }

  void _updateDisplayEmail() {
    setState(() {
      _displayEmail = _emailController.text;
    });
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    await _initializeFromLocalStorage();
    await _profileViewModel.getUserDetails();
    await _profileViewModel.fetchFaqReports();
    _initializeControllers();

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _initializeFromLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userName = prefs.getString('userName');
      final userEmail = prefs.getString('userEmail');

      if (userName != null && userEmail != null) {
        setState(() {
          _nameController.text = userName;
          _emailController.text = userEmail;
          _displayName = userName;
          _displayEmail = userEmail;
        });
      }
    } catch (e) {
      print('Error loading from local storage: $e');
    }
  }

  void _initializeControllers() {
    if (_profileViewModel.user != null) {
      setState(() {
        _nameController.text = _profileViewModel.user!.fullName ?? '';
        _emailController.text = _profileViewModel.user!.email ?? '';
        _displayName = _profileViewModel.user!.fullName ?? '';
        _displayEmail = _profileViewModel.user!.email ?? '';
        _profileImageUrl = _profileViewModel.user!.profilePicture;
      });
    }
  }

  @override
  void dispose() {
    _nameController.removeListener(_updateDisplayName);
    _emailController.removeListener(_updateDisplayEmail);
    _nameController.dispose();
    _emailController.dispose();
    _faqQuestionController.dispose();
    super.dispose();
  }

  void _toggleEditMode() {
    setState(() {
      _isEditing = !_isEditing;
      if (!_isEditing) {
        _initializeControllers();
      }
    });
  }

  Future<bool> _onWillPop() async {
    if (_isEditing) {
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Modifications non enregistrées'),
          content: const Text(
              'Voulez-vous quitter sans enregistrer vos modifications?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () {
                _toggleEditMode();
                Navigator.of(context).pop(true);
              },
              child: const Text('Quitter'),
            ),
          ],
        ),
      );
      return result ?? false;
    }
    return true;
  }

  Future<void> _updateProfileImage() async {
    setState(() {
      _isLoading = true;
    });

    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _profileImageUrl = "https://example.com/new-profile-image.jpg";
      _isLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Photo de profil mise à jour")),
    );
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      _editProfileViewModel.setFullName(_nameController.text);
      _editProfileViewModel.setEmail(_emailController.text);

      final success = await _editProfileViewModel.saveProfile();

      if (success && mounted) {
        await _editProfileViewModel.refreshUserData();
        await _profileViewModel.getUserDetails();

        setState(() {
          _displayName = _nameController.text;
          _displayEmail = _emailController.text;
          _isLoading = false;
          _isEditing = false;
        });

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userName', _nameController.text);
        await prefs.setString('userEmail', _emailController.text);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profil mis à jour avec succès")),
        );
      } else if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_editProfileViewModel.errorMessage ??
                "Erreur lors de la mise à jour du profil"),
            backgroundColor: Colors.red,
          ),
        );

        if (_editProfileViewModel.errorMessage?.contains("Session expirée") ??
            false) {
          Navigator.of(context).pushReplacementNamed('/login');
        }
      }
    }
  }

  Future<void> _submitFAQQuestion() async {
    if (_faqQuestionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Veuillez entrer une question."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final success = await _profileViewModel.submitFaqReport(
      "Question utilisateur",
      _faqQuestionController.text.trim(),
    );

    if (success && mounted) {
      await _profileViewModel.fetchFaqReports();
      setState(() {
        _isLoading = false;
        _faqQuestionController.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              "Votre question a été reçue, nous vous répondrons bientôt !"),
          duration: Duration(seconds: 2),
        ),
      );
    } else if (mounted) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_profileViewModel.faqErrorMessage ??
              "Erreur lors de la soumission"),
          backgroundColor: Colors.red,
        ),
      );
      if (_profileViewModel.faqErrorMessage?.contains("Session expirée") ??
          false) {
        await _loginViewModel.logout();
        await _profileViewModel.clearUserData();
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }

  void _shareReferralLink() {
    const referralLink = "https://primeprof.com";
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Inviter des amis"),
        content: const Text("Partagez votre lien : https://primeprof.com"),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              const message =
                  "Rejoignez PrimeProf avec mon lien de parrainage et profitez d'avantages exclusifs ! $referralLink";
              try {
                await Share.share(message, subject: "Invitation à PrimeProf");
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Erreur lors du partage : $e"),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text("Partager"),
          ),
          TextButton(
            onPressed: () {
              FlutterClipboard.copy(referralLink).then((value) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Lien copié !")),
                  );
                }
                Navigator.pop(context);
              });
            },
            child: const Text("Copier le lien"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: _buildScaffold(context),
    );
  }

  Widget _buildScaffold(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_profileViewModel.user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.login, size: 50, color: theme.colorScheme.onSurface),
              const SizedBox(height: 16),
              Text(
                "Veuillez vous connecter pour voir votre profil.",
                style:
                    TextStyle(fontSize: 16, color: theme.colorScheme.onSurface),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Compte',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onPrimary,
          ),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [theme.colorScheme.primary, theme.colorScheme.primary],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onPrimary),
          onPressed: () => _isEditing ? _onWillPop() : Navigator.pop(context),
        ),
        actions: [
          if (_isEditing)
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.save, color: theme.colorScheme.onPrimary),
                  onPressed: _saveProfile,
                ),
              ],
            )
          else
            IconButton(
              icon: Icon(Icons.edit, color: theme.colorScheme.onPrimary),
              onPressed: _toggleEditMode,
            ),
        ],
      ),
      body: Stack(
        children: [
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(80),
                bottomRight: Radius.circular(0),
              ),
            ),
          ),
          Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: theme.colorScheme.surface,
                              child:
                                  _buildProfileImage(_profileImageUrl, theme),
                            ),
                            if (_isEditing)
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: GestureDetector(
                                  onTap: _updateProfileImage,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.secondary,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: theme.colorScheme.onPrimary,
                                        width: 2,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.edit,
                                      color: theme.colorScheme.onSecondary,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _displayName.isNotEmpty
                              ? _displayName
                              : (_profileViewModel.user?.fullName ??
                                  'John Doe'),
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: theme.shadowColor,
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color:
                                    theme.colorScheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.person_outline,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Name',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: Colors.grey,
                                    ),
                                  ),
                                  if (_isEditing)
                                    _buildTextField(
                                      controller: _nameController,
                                      validator: (value) => value!.isEmpty
                                          ? 'Veuillez entrer un nom'
                                          : null,
                                      theme: theme,
                                    )
                                  else
                                    Text(
                                      _displayName,
                                      style:
                                          theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w500,
                                        color: theme.colorScheme.onSurface,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        Divider(height: 24, color: theme.dividerColor),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color:
                                    theme.colorScheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.email_outlined,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Email',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: Colors.grey,
                                    ),
                                  ),
                                  if (_isEditing)
                                    _buildTextField(
                                      controller: _emailController,
                                      keyboardType: TextInputType.emailAddress,
                                      validator: (value) => value!.isEmpty ||
                                              !value.contains('@')
                                          ? 'Veuillez entrer un email valide'
                                          : null,
                                      theme: theme,
                                    )
                                  else
                                    Text(
                                      _displayEmail,
                                      style:
                                          theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w500,
                                        color: theme.colorScheme.onSurface,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Dark Mode Toggle
                  const SizedBox(height: 24),
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: theme.shadowColor,
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.purple.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _profileViewModel.themeMode == ThemeMode.dark
                                ? Icons.dark_mode
                                : Icons.light_mode,
                            color: Colors.purple,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            "Mode sombre",
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                        Switch(
                          value: _profileViewModel.themeMode == ThemeMode.dark,
                          onChanged: (value) async {
                            await _profileViewModel.toggleTheme();
                            setState(() {});
                          },
                          activeColor: theme.colorScheme.primary,
                        ),
                      ],
                    ),
                  ),

                  // Change Password Option
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: theme.shadowColor,
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  const ChangePasswordScreen()),
                        );
                      },
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color:
                                  theme.colorScheme.secondary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.lock_outline,
                              color: theme.colorScheme.secondary,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              "Changer le mot de passe",
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                          Icon(Icons.chevron_right,
                              color: theme.colorScheme.onSurface),
                        ],
                      ),
                    ),
                  ),

                  // Privacy section
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: theme.shadowColor,
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: InkWell(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                "Paramètres de confidentialité en cours de chargement..."),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.privacy_tip,
                              color: Colors.orange,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              "Privacy",
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Text(
                              'Action Needed',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Inviter des amis
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: theme.shadowColor,
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: InkWell(
                      splashColor: Colors.green.withOpacity(0.2),
                      highlightColor: Colors.green.withOpacity(0.1),
                      onTap: _shareReferralLink,
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.group_add,
                              color: Colors.green,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              "Inviter des amis",
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // FAQ Section
                  const SizedBox(height: 24),
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: theme.shadowColor,
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ExpansionTile(
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.help_outline,
                          color: Colors.blue,
                        ),
                      ),
                      title: Text(
                        "Foire aux questions (FAQ)",
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Container(
                                height: 300,
                                child: _profileViewModel.faqReports.isEmpty
                                    ? Center(
                                        child: Text(
                                          "Aucune question pour le moment. Posez-en une !",
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                            color: theme
                                                .colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      )
                                    : ListView.builder(
                                        reverse: true,
                                        itemCount: _profileViewModel
                                                .faqReports.length *
                                            2,
                                        itemBuilder: (context, index) {
                                          if (index % 2 == 0) {
                                            final reportIndex = index ~/ 2;
                                            final report = _profileViewModel
                                                .faqReports[reportIndex];
                                            return _buildFAQMessage(
                                              theme: theme,
                                              message: report.description,
                                              isUser: true,
                                            );
                                          } else {
                                            return _buildFAQMessage(
                                              theme: theme,
                                              message:
                                                  "Votre question a été reçue, nous vous répondrons bientôt !",
                                              isUser: false,
                                            );
                                          }
                                        },
                                      ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _faqQuestionController,
                                      decoration: InputDecoration(
                                        hintText: "Posez votre question...",
                                        filled: true,
                                        fillColor:
                                            theme.colorScheme.surfaceVariant,
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          borderSide: BorderSide.none,
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 8),
                                      ),
                                      style: TextStyle(
                                          color: theme.colorScheme.onSurface),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: Icon(Icons.send,
                                        color: theme.colorScheme.primary),
                                    onPressed: _submitFAQQuestion,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 16),
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        setState(() {
                          _isLoading = true;
                        });

                        await _loginViewModel.logout();
                        await _profileViewModel.clearUserData();
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setBool('isLoggedIn', false);

                        if (mounted) {
                          setState(() {
                            _isLoading = false;
                          });

                          Navigator.of(context).pushReplacementNamed('/');
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text("Déconnecté avec succès")),
                          );
                        }
                      },
                      icon: const Icon(Icons.logout),
                      label: const Text('Se déconnecter'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileImage(String? profilePicture, ThemeData theme) {
    return profilePicture != null && profilePicture.isNotEmpty
        ? ClipOval(
            child: Image.network(
              profilePicture,
              fit: BoxFit.cover,
              width: 100,
              height: 100,
              loadingBuilder: (context, child, loadingProgress) =>
                  loadingProgress == null
                      ? child
                      : const CircularProgressIndicator(),
              errorBuilder: (context, error, stackTrace) {
                print("Image load error: $error");
                return Icon(Icons.person,
                    size: 50, color: theme.colorScheme.onPrimary);
              },
            ),
          )
        : Icon(Icons.person, size: 50, color: theme.colorScheme.onPrimary);
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String? Function(String?) validator,
    required ThemeData theme,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        filled: true,
        fillColor: theme.colorScheme.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        errorStyle: TextStyle(color: theme.colorScheme.error),
      ),
      validator: validator,
      style: TextStyle(color: theme.colorScheme.onSurface),
      onChanged: (value) {
        setState(() {});
      },
    );
  }

  Widget _buildFAQMessage({
    required ThemeData theme,
    required String message,
    required bool isUser,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Align(
        alignment: isUser ? Alignment.centerLeft : Alignment.centerRight,
        child: Container(
          constraints:
              BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: isUser
                ? theme.colorScheme.primary.withOpacity(0.1)
                : theme.colorScheme.secondary.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isUser
                  ? theme.colorScheme.onSurface
                  : theme.colorScheme.onSurfaceVariant,
              fontWeight: isUser ? FontWeight.w500 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}
