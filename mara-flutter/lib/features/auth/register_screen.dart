import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mara_flutter/core/services/auth_service.dart';
import 'package:mara_flutter/core/theme/app_theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _pwCtrl = TextEditingController();
  final _pw2Ctrl = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _obscure = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _pwCtrl.dispose();
    _pw2Ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await AuthService.instance.register(
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _pwCtrl.text,
      );
      if (mounted) context.go('/');
    } catch (e) {
      setState(
          () => _error = 'Erreur d\'inscription. Vérifiez vos informations.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0D1B2A),
                  Color(0xFF1A2E4A),
                  Color(0xFF0D1117)
                ],
              ),
            ),
          ),
          Positioned(
            top: -80,
            right: -60,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.12),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Logo + title
                      Row(children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Text('M',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text('MARA',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2)),
                      ]),
                      const SizedBox(height: 32),
                      const Text('Créer un compte',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w800)),
                      const SizedBox(height: 6),
                      const Text('Rejoignez la plateforme MARA',
                          style:
                              TextStyle(color: Colors.white54, fontSize: 13)),
                      const SizedBox(height: 32),

                      // Form card
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 24,
                                offset: const Offset(0, 8)),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (_error != null)
                                Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFEBEE),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                        color: AppColors.red
                                            .withValues(alpha: 0.4)),
                                  ),
                                  child: Text(_error!,
                                      style: const TextStyle(
                                          color: AppColors.red, fontSize: 13)),
                                ),
                              _buildField(
                                controller: _nameCtrl,
                                label: 'Nom complet',
                                hint: 'Votre prénom et nom',
                                icon: Icons.person_outline_rounded,
                                validator: (v) =>
                                    (v == null || v.trim().length < 2)
                                        ? 'Nom requis (min 2 caractères)'
                                        : null,
                              ),
                              const SizedBox(height: 16),
                              _buildField(
                                controller: _emailCtrl,
                                label: 'Email',
                                hint: 'votre@email.com',
                                icon: Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                                validator: (v) =>
                                    (v == null || !v.contains('@'))
                                        ? 'Email invalide'
                                        : null,
                              ),
                              const SizedBox(height: 16),
                              _buildField(
                                controller: _pwCtrl,
                                label: 'Mot de passe',
                                hint: '••••••••',
                                icon: Icons.lock_outline_rounded,
                                obscure: _obscure,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscure
                                        ? Icons.visibility_off_rounded
                                        : Icons.visibility_rounded,
                                    size: 18,
                                    color: AppColors.muted,
                                  ),
                                  onPressed: () =>
                                      setState(() => _obscure = !_obscure),
                                ),
                                validator: (v) => (v == null || v.length < 8)
                                    ? 'Minimum 8 caractères'
                                    : null,
                              ),
                              const SizedBox(height: 16),
                              _buildField(
                                controller: _pw2Ctrl,
                                label: 'Confirmer le mot de passe',
                                hint: '••••••••',
                                icon: Icons.lock_outline_rounded,
                                obscure: _obscure,
                                validator: (v) => v != _pwCtrl.text
                                    ? 'Les mots de passe ne correspondent pas'
                                    : null,
                              ),
                              const SizedBox(height: 24),
                              SizedBox(
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: _loading ? null : _submit,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                    elevation: 0,
                                  ),
                                  child: _loading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white))
                                      : const Text('Créer mon compte',
                                          style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700)),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text('Déjà un compte ? ',
                                      style: TextStyle(
                                          color: AppColors.sub, fontSize: 13)),
                                  GestureDetector(
                                    onTap: () => context.go('/login'),
                                    child: const Text('Se connecter',
                                        style: TextStyle(
                                            color: AppColors.primary,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.text)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.muted, fontSize: 13),
            prefixIcon: Icon(icon, size: 18, color: AppColors.muted),
            suffixIcon: suffixIcon,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.red, width: 1.5),
            ),
            filled: true,
            fillColor: const Color(0xFFF8F9FB),
          ),
        ),
      ],
    );
  }
}
