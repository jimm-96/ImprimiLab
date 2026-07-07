import 'package:flutter/material.dart';
import '../state/app_state.dart';
import '../models/user_profile.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  TabController? _tabController;
  final _loginFormKey = GlobalKey<FormState>();
  final _registerFormKey = GlobalKey<FormState>();
  final _editFormKey = GlobalKey<FormState>();

  // Login inputs
  final _loginUserCtrl = TextEditingController();
  final _loginPassCtrl = TextEditingController();

  // Register inputs
  final _regUserCtrl = TextEditingController();
  final _regPassCtrl = TextEditingController();
  final _regConfirmPassCtrl = TextEditingController();
  final _regNameCtrl = TextEditingController();
  final _regEmailCtrl = TextEditingController();

  // Edit profile inputs
  late TextEditingController _editNameCtrl;
  late TextEditingController _editEmailCtrl;
  late TextEditingController _editPhoneCtrl;
  late TextEditingController _editWorkshopCtrl;
  late TextEditingController _editBioCtrl;
  late TextEditingController _editWebsiteCtrl;
  String? _selectedMakerLevel;

  bool _obscureLoginPass = true;
  bool _obscureRegPass = true;
  bool _obscureRegConfirmPass = true;

  @override
  void initState() {
    super.initState();
    if (appState.currentUser == null) {
      _tabController = TabController(length: 2, vsync: this);
    } else {
      _initEditControllers();
    }
  }

  void _initEditControllers() {
    final user = appState.currentUser!;
    _editNameCtrl = TextEditingController(text: user.name);
    _editEmailCtrl = TextEditingController(text: user.email);
    _editPhoneCtrl = TextEditingController(text: user.phone ?? '');
    _editWorkshopCtrl = TextEditingController(text: user.workshopName ?? '');
    _editBioCtrl = TextEditingController(text: user.bio ?? '');
    _editWebsiteCtrl = TextEditingController(text: user.website ?? '');
    _selectedMakerLevel = user.makerLevel ?? 'Novato';
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _loginUserCtrl.dispose();
    _loginPassCtrl.dispose();
    _regUserCtrl.dispose();
    _regPassCtrl.dispose();
    _regConfirmPassCtrl.dispose();
    _regNameCtrl.dispose();
    _regEmailCtrl.dispose();

    if (appState.currentUser != null) {
      _editNameCtrl.dispose();
      _editEmailCtrl.dispose();
      _editPhoneCtrl.dispose();
      _editWorkshopCtrl.dispose();
      _editBioCtrl.dispose();
      _editWebsiteCtrl.dispose();
    }
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_loginFormKey.currentState!.validate()) return;

    final username = _loginUserCtrl.text.trim();
    final password = _loginPassCtrl.text.trim();

    final success = await appState.loginUser(username, password);
    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sesión iniciada con éxito'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          _initEditControllers();
        });
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Usuario o contraseña incorrectos'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _handleRegister() async {
    if (!_registerFormKey.currentState!.validate()) return;

    final username = _regUserCtrl.text.trim();
    final password = _regPassCtrl.text.trim();
    final name = _regNameCtrl.text.trim();
    final email = _regEmailCtrl.text.trim();

    final success = await appState.registerUser(username, password, name, email);
    if (success) {
      // Auto-login after successful registration
      await appState.loginUser(username, password);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Usuario registrado e ingresado con éxito'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          _initEditControllers();
        });
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('El nombre de usuario ya está en uso'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _handleSaveProfile() async {
    if (!_editFormKey.currentState!.validate()) return;

    final updated = appState.currentUser!.copyWith(
      name: _editNameCtrl.text.trim(),
      email: _editEmailCtrl.text.trim(),
      phone: _editPhoneCtrl.text.trim().isEmpty ? null : _editPhoneCtrl.text.trim(),
      workshopName: _editWorkshopCtrl.text.trim().isEmpty ? null : _editWorkshopCtrl.text.trim(),
      bio: _editBioCtrl.text.trim().isEmpty ? null : _editBioCtrl.text.trim(),
      website: _editWebsiteCtrl.text.trim().isEmpty ? null : _editWebsiteCtrl.text.trim(),
      makerLevel: _selectedMakerLevel,
    );

    await appState.updateUserProfile(updated);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Perfil actualizado correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _handleLogout() async {
    await appState.logoutUser();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sesión cerrada'),
          backgroundColor: Colors.cyan,
        ),
      );
      setState(() {
        _tabController = TabController(length: 2, vsync: this);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          appState.currentUser == null ? 'Ingreso a ImpriLab' : 'Mi Perfil Maker',
          style: TextStyle(
            color: primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: primary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListenableBuilder(
        listenable: appState,
        builder: (context, _) {
          final user = appState.currentUser;
          if (user == null) {
            return _buildAuthTabs(primary);
          }
          return _buildProfileEditor(user, primary);
        },
      ),
    );
  }

  Widget _buildAuthTabs(Color primary) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          labelColor: primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: primary,
          tabs: const [
            Tab(icon: Icon(Icons.login), text: 'Iniciar Sesión'),
            Tab(icon: Icon(Icons.person_add), text: 'Registrarse'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildLoginForm(primary),
              _buildRegisterForm(primary),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm(Color primary) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _loginFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            Icon(Icons.lock_person_outlined, size: 70, color: primary),
            const SizedBox(height: 16),
            const Text(
              '¡Bienvenido de vuelta, Maker!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Inicia sesión para gestionar tus parámetros y stock localmente.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 28),
            TextFormField(
              controller: _loginUserCtrl,
              decoration: const InputDecoration(
                labelText: 'Nombre de Usuario',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Ingresa tu nombre de usuario';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _loginPassCtrl,
              obscureText: _obscureLoginPass,
              decoration: InputDecoration(
                labelText: 'Contraseña',
                prefixIcon: const Icon(Icons.key),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureLoginPass ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() => _obscureLoginPass = !_obscureLoginPass);
                  },
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Ingresa tu contraseña';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _handleLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Ingresar',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegisterForm(Color primary) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _registerFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Crea tu Cuenta Maker',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Regístrate para personalizar tu perfil, taller y stock.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _regUserCtrl,
              decoration: const InputDecoration(
                labelText: 'Nombre de Usuario',
                prefixIcon: Icon(Icons.alternate_email),
                border: OutlineInputBorder(),
                helperText: 'Será tu identificador único de ingreso.',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Ingresa un nombre de usuario';
                }
                if (value.trim().contains(' ')) {
                  return 'No debe contener espacios';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _regNameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nombre Completo / Comercial',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Ingresa tu nombre';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _regEmailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Correo Electrónico',
                prefixIcon: Icon(Icons.email_outlined),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Ingresa tu correo';
                }
                final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
                if (!emailRegex.hasMatch(value.trim())) {
                  return 'Ingresa un correo válido';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _regPassCtrl,
              obscureText: _obscureRegPass,
              decoration: InputDecoration(
                labelText: 'Contraseña',
                prefixIcon: const Icon(Icons.lock_outline),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureRegPass ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() => _obscureRegPass = !_obscureRegPass);
                  },
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Ingresa una contraseña';
                }
                if (value.length < 4) {
                  return 'Debe tener al menos 4 caracteres';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _regConfirmPassCtrl,
              obscureText: _obscureRegConfirmPass,
              decoration: InputDecoration(
                labelText: 'Confirmar Contraseña',
                prefixIcon: const Icon(Icons.lock_outline),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureRegConfirmPass ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() => _obscureRegConfirmPass = !_obscureRegConfirmPass);
                  },
                ),
              ),
              validator: (value) {
                if (value != _regPassCtrl.text) {
                  return 'Las contraseñas no coinciden';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _handleRegister,
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Registrarse y Comenzar',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileEditor(UserProfile user, Color primary) {
    // Helper to get initials
    final words = user.name.trim().split(' ');
    final initials = words.isNotEmpty && words[0].isNotEmpty
        ? (words.length > 1 && words[1].isNotEmpty
            ? '${words[0][0]}${words[1][0]}'
            : words[0][0])
        : '?';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Form(
        key: _editFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Profile Card
            Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: primary.withAlpha(40), width: 1.5),
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: primary,
                      child: Text(
                        initials.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 28,
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user.name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    if (user.workshopName != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '🏢 ${user.workshopName}',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: primary, fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: primary.withAlpha(30),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Nivel: ${user.makerLevel ?? "Novato"}',
                        style: TextStyle(
                          color: primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Form section title
            const Text(
              'Información del Perfil',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Read-only Username
            TextFormField(
              initialValue: '@${user.username}',
              enabled: false,
              decoration: const InputDecoration(
                labelText: 'Nombre de Usuario',
                prefixIcon: Icon(Icons.alternate_email),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Editable Name
            TextFormField(
              controller: _editNameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nombre Completo / Comercial',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'El nombre es obligatorio';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Editable Email
            TextFormField(
              controller: _editEmailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Correo Electrónico',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'El correo es obligatorio';
                }
                final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
                if (!emailRegex.hasMatch(value.trim())) {
                  return 'Ingresa un correo válido';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Phone
            TextFormField(
              controller: _editPhoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Teléfono (Contacto)',
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Workshop Name
            TextFormField(
              controller: _editWorkshopCtrl,
              decoration: const InputDecoration(
                labelText: 'Nombre del Taller / Emprendimiento',
                prefixIcon: Icon(Icons.store),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Bio
            TextFormField(
              controller: _editBioCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Biografía / Descripción del Taller',
                prefixIcon: Icon(Icons.description),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Website / Socials
            TextFormField(
              controller: _editWebsiteCtrl,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'Sitio Web / Red Social (Instagram, TikTok)',
                prefixIcon: Icon(Icons.link),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Maker Level Dropdown
            DropdownButtonFormField<String>(
              value: _selectedMakerLevel,
              decoration: const InputDecoration(
                labelText: 'Nivel de Experiencia Maker',
                prefixIcon: Icon(Icons.speed),
                border: OutlineInputBorder(),
              ),
              dropdownColor: const Color(0xFF1E293B),
              items: const [
                DropdownMenuItem(value: 'Novato', child: Text('Novato (0-6 meses)')),
                DropdownMenuItem(value: 'Intermedio', child: Text('Intermedio (6-18 meses)')),
                DropdownMenuItem(value: 'Experto', child: Text('Experto (1.5 - 3 años)')),
                DropdownMenuItem(value: 'Profesional', child: Text('Profesional (+3 años)')),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedMakerLevel = val);
                }
              },
            ),
            const SizedBox(height: 32),

            // Action Buttons
            ElevatedButton(
              onPressed: _handleSaveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Guardar Cambios',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _handleLogout,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.redAccent,
                side: const BorderSide(color: Colors.redAccent, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Cerrar Sesión',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
